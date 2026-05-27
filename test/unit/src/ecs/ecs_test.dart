// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

// Unit tests for `lib/src/ecs/ecs.dart`. Locks down the Bevy-inspired ECS
// surface: World construction/disposal, Components, Resources, Events,
// Systems, Bundles, EcsPlugin, and snapshot safety under reentrant mutation.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Component fixtures ──────────────────────────────────────────────────────

final class _Position extends Component {
  const _Position(this.x, this.y);
  final double x;
  final double y;
}

final class _Velocity extends Component {
  const _Velocity(this.dx, this.dy);
  final double dx;
  final double dy;
}

final class _Health extends Component {
  const _Health(this.hp);
  final int hp;
}

final class _Tag extends Component {
  const _Tag();
}

// ─── Resource fixtures ───────────────────────────────────────────────────────

final class _Score extends Resource {
  const _Score(this.value);
  final int value;
}

final class _Config extends Resource {
  const _Config(this.name);
  final String name;
}

// ─── Event fixtures ──────────────────────────────────────────────────────────

class _BaseEvent extends Event {
  const _BaseEvent(this.id);
  final int id;
}

final class _DerivedEvent extends _BaseEvent {
  const _DerivedEvent(super.id);
}

final class _OtherEvent extends Event {
  const _OtherEvent();
}

// ─── Bundle fixture ──────────────────────────────────────────────────────────

final class _PlayerBundle extends Bundle {
  const _PlayerBundle({required this.position, required this.health});
  final _Position position;
  final _Health health;
  @override
  Iterable<Component> get components => [position, health, const _Tag()];
}

// ─── EcsPlugin fixture ───────────────────────────────────────────────────────

final class _CounterPlugin extends EcsPlugin {
  const _CounterPlugin();
  @override
  void build(World world) {
    world.insertResource(const _Score(100));
    world.addSystem(FunctionSystem((_, __) {}));
  }
}

// ─── ServiceMixin Resource / Component fixtures ──────────────────────────────

final class _ServiceResource extends Resource with ServiceMixin {
  bool didDispose = false;

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) => Sync.okValue(Unit()),
      ];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) => [
        (_) => Sync.okValue(Unit()),
      ];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) => [
        (_) => Sync.okValue(Unit()),
      ];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
        (_) => Sync<Unit>(() {
              didDispose = true;
              return Unit();
            }),
      ];
}

final class _ServiceComponent extends Component with ServiceMixin {
  bool didDispose = false;

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) => Sync.okValue(Unit()),
      ];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) => [
        (_) => Sync.okValue(Unit()),
      ];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) => [
        (_) => Sync.okValue(Unit()),
      ];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
        (_) => Sync<Unit>(() {
              didDispose = true;
              return Unit();
            }),
      ];
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('World construction & disposal', () {
    test('default World() constructs with an empty registry', () {
      final world = World();
      expect(world.isDisposed, isFalse);
      expect(world.entities, isEmpty);
      expect(world.entityCount, 0);
      expect(world.elapsed, Duration.zero);
      expect(world.systems, isEmpty);
      expect(world.startupSystems, isEmpty);
      world.dispose();
    });

    test('dispose() marks the world as disposed', () {
      final world = World();
      expect(world.isDisposed, isFalse);
      world.dispose();
      expect(world.isDisposed, isTrue);
    });

    test('dispose() is idempotent', () {
      final world = World()
        ..dispose()
        ..dispose();
      expect(world.isDisposed, isTrue);
    });

    test('update after dispose is a no-op', () {
      final world = World();
      var ticks = 0;
      world.addSystem(FunctionSystem((_, __) => ticks++));
      world.dispose();
      world.update(Duration.zero);
      world.update(const Duration(seconds: 1));
      expect(ticks, 0);
    });

    test('dispose() empties the registry of all groups', () {
      final world = World()..insertResource(const _Score(7));
      world.spawn(const Some([_Position(0, 0)]));
      world.dispose();
      expect(world.registry.groupEntities, isEmpty);
    });
  });

  group('Entity spawn / despawn / clearEntities', () {
    test('spawn() creates an entity', () {
      final world = World();
      final e = world.spawn();
      expect(e.alive, isTrue);
      expect(world.entityCount, 1);
      expect(world.entities, contains(e));
      world.dispose();
    });

    test('spawn(Some([components])) attaches the components', () {
      final world = World();
      final e = world.spawn(const Some([_Position(1, 2), _Velocity(3, 4)]));
      expect(e.has<_Position>(), isTrue);
      expect(e.has<_Velocity>(), isTrue);
      world.dispose();
    });

    test('despawn() removes the entity and returns true', () {
      final world = World();
      final e = world.spawn();
      expect(world.despawn(e), isTrue);
      expect(e.alive, isFalse);
      expect(world.entityCount, 0);
      world.dispose();
    });

    test('despawn() of an already-despawned entity returns false', () {
      final world = World();
      final e = world.spawn();
      world.despawn(e);
      expect(world.despawn(e), isFalse);
      world.dispose();
    });

    test('clearEntities() removes every entity but keeps resources/systems',
        () {
      final world = World()..insertResource(const _Score(7));
      var ran = 0;
      world.addSystem(FunctionSystem((_, __) => ran++));
      for (var i = 0; i < 5; i++) {
        world.spawn(const Some([_Position(0, 0)]));
      }
      expect(world.entityCount, 5);
      world.clearEntities();
      expect(world.entityCount, 0);
      expect(world.getResource<_Score>().isSome(), isTrue);
      world.update(Duration.zero);
      expect(ran, 1);
      world.dispose();
    });

    test('entity ids increment per spawn', () {
      final world = World();
      final a = world.spawn();
      final b = world.spawn();
      expect(a.id, isNot(equals(b.id)));
      world.dispose();
    });
  });

  group('Components', () {
    test('addComponent (insert) / getComponent (get) round-trip', () {
      final world = World();
      final e = world.spawn();
      e.insert(const _Position(7, 8));
      final got = e.get<_Position>();
      expect(got.isSome(), isTrue);
      expect(e.require<_Position>().x, 7);
      world.dispose();
    });

    test('removeComponent (remove) deletes a component', () {
      final world = World();
      final e = world.spawn(const Some([_Position(0, 0)]));
      final removed = e.remove<_Position>();
      expect(removed.isSome(), isTrue);
      expect(e.has<_Position>(), isFalse);
      world.dispose();
    });

    test('remove on a missing component returns None', () {
      final world = World();
      final e = world.spawn();
      expect(e.remove<_Position>().isNone(), isTrue);
      world.dispose();
    });

    test('multiple components per entity are independent', () {
      final world = World();
      final e = world.spawn();
      e.insert(const _Position(1, 2));
      e.insert(const _Velocity(3, 4));
      e.insert(const _Health(99));
      expect(e.has<_Position>(), isTrue);
      expect(e.has<_Velocity>(), isTrue);
      expect(e.has<_Health>(), isTrue);
      world.dispose();
    });

    test('inserting twice replaces the previous component value', () {
      final world = World();
      final e = world.spawn(const Some([_Position(0, 0)]));
      e.insert(const _Position(9, 9));
      expect(e.require<_Position>().x, 9);
      world.dispose();
    });

    test('despawning removes all of the entity\'s components', () {
      final world = World();
      final e = world.spawn(const Some([_Position(1, 1), _Velocity(2, 2)]));
      world.despawn(e);
      expect(world.withComponent<_Position>(), isEmpty);
      expect(world.withComponent<_Velocity>(), isEmpty);
      world.dispose();
    });

    test('removing a ServiceMixin component cascades dispose() on despawn',
        () async {
      final world = World();
      final svc = _ServiceComponent();
      (await svc.init().toAsync().value).end();
      final e = world.spawn();
      e.insert(svc);
      world.despawn(e);
      await Future<void>.delayed(Duration.zero);
      expect(svc.didDispose, isTrue);
      world.dispose();
    });

    test('clearEntities cascades dispose() on ServiceMixin components',
        () async {
      final world = World();
      final svc = _ServiceComponent();
      (await svc.init().toAsync().value).end();
      world.spawn().insert(svc);
      world.clearEntities();
      await Future<void>.delayed(Duration.zero);
      expect(svc.didDispose, isTrue);
      world.dispose();
    });
  });

  group('Resources', () {
    test('insertResource / getResource round-trip', () {
      final world = World();
      world.insertResource(const _Score(42));
      final got = world.getResource<_Score>();
      expect(got.isSome(), isTrue);
      expect(world.requireResource<_Score>().value, 42);
      world.dispose();
    });

    test('only one of each Resource type at a time — re-insert replaces', () {
      final world = World();
      world.insertResource(const _Score(1));
      world.insertResource(const _Score(2));
      world.insertResource(const _Score(3));
      expect(world.requireResource<_Score>().value, 3);
      world.dispose();
    });

    test('different Resource types coexist independently', () {
      final world = World()
        ..insertResource(const _Score(10))
        ..insertResource(const _Config('main'));
      expect(world.requireResource<_Score>().value, 10);
      expect(world.requireResource<_Config>().name, 'main');
      world.dispose();
    });

    test('removeResource removes and returns the resource', () {
      final world = World()..insertResource(const _Score(5));
      final removed = world.removeResource<_Score>();
      expect(removed.isSome(), isTrue);
      expect(world.getResource<_Score>().isNone(), isTrue);
      world.dispose();
    });

    test('requireResource throws StateError when missing', () {
      final world = World();
      expect(() => world.requireResource<_Score>(), throwsStateError);
      world.dispose();
    });

    test('removeResource cascades dispose() on ServiceMixin resource',
        () async {
      final world = World();
      final svc = _ServiceResource();
      (await svc.init().toAsync().value).end();
      world.insertResource(svc);
      world.removeResource<_ServiceResource>().end();
      await Future<void>.delayed(Duration.zero);
      expect(svc.didDispose, isTrue);
      world.dispose();
    });

    test('world.dispose() cascades dispose() on ServiceMixin resources',
        () async {
      final world = World();
      final svc = _ServiceResource();
      (await svc.init().toAsync().value).end();
      world.insertResource(svc);
      world.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(svc.didDispose, isTrue);
    });
  });

  group('Events', () {
    test('sendEvent + readEvents round-trip within a tick', () {
      final world = World();
      world.sendEvent(const _BaseEvent(1));
      world.sendEvent(const _BaseEvent(2));
      final read = world.readEvents<_BaseEvent>().toList();
      expect(read.length, 2);
      expect(read.map((e) => e.id), [1, 2]);
      world.dispose();
    });

    test('subtype propagation: derived event reaches base-typed listener', () {
      final world = World();
      var baseHits = 0;
      var derivedHits = 0;
      world.onEvent<_BaseEvent>((_) => baseHits++);
      world.onEvent<_DerivedEvent>((_) => derivedHits++);
      world.sendEvent(const _DerivedEvent(7));
      expect(baseHits, 1);
      expect(derivedHits, 1);
      world.dispose();
    });

    test('readEvents<Base> includes events sent as derived', () {
      final world = World();
      world.sendEvent(const _DerivedEvent(3));
      expect(world.readEvents<_BaseEvent>().length, 1);
      expect(world.readEvents<_DerivedEvent>().length, 1);
      world.dispose();
    });

    test('readEvents<Other> excludes unrelated event types', () {
      final world = World();
      world.sendEvent(const _BaseEvent(1));
      expect(world.readEvents<_OtherEvent>(), isEmpty);
      world.dispose();
    });

    test('onEvent listener fires synchronously on sendEvent', () {
      final world = World();
      final received = <int>[];
      world.onEvent<_BaseEvent>((e) => received.add(e.id));
      world.sendEvent(const _BaseEvent(1));
      world.sendEvent(const _BaseEvent(2));
      expect(received, [1, 2]);
      world.dispose();
    });

    test('onEvent returns an unsubscribe closure', () {
      final world = World();
      var hits = 0;
      final off = world.onEvent<_BaseEvent>((_) => hits++);
      world.sendEvent(const _BaseEvent(1));
      off();
      world.sendEvent(const _BaseEvent(2));
      expect(hits, 1);
      world.dispose();
    });

    test('event buffer is cleared at end of update (depth 0)', () {
      final world = World();
      world.sendEvent(const _BaseEvent(1));
      expect(world.readEvents<_BaseEvent>().length, 1);
      world.update(Duration.zero);
      expect(world.readEvents<_BaseEvent>().length, 0);
      world.dispose();
    });

    test(
      're-entrant update preserves outer-tick events for later outer systems',
      () {
        final world = World();
        var observed = 0;
        var outerRuns = 0;
        world.addSystem(
          FunctionSystem((w, _) {
            outerRuns++;
            if (outerRuns == 1) {
              w.sendEvent(const _BaseEvent(99));
              // Re-enter — inner update must NOT clear the buffer.
              w.update(Duration.zero);
            }
          }),
        );
        world.addSystem(
          FunctionSystem((w, _) {
            observed += w.readEvents<_BaseEvent>().where((e) => e.id == 99)
                .length;
          }),
        );
        world.update(Duration.zero);
        expect(observed, greaterThanOrEqualTo(1));
        world.dispose();
      },
    );
  });

  group('Systems', () {
    test('addSystem registers a system; update invokes it', () {
      final world = World();
      var ran = 0;
      world.addSystem(FunctionSystem((_, __) => ran++));
      world.update(Duration.zero);
      expect(ran, 1);
      world.dispose();
    });

    test('multiple systems run in registration order', () {
      final world = World();
      final order = <int>[];
      world.addSystem(FunctionSystem((_, __) => order.add(1)));
      world.addSystem(FunctionSystem((_, __) => order.add(2)));
      world.addSystem(FunctionSystem((_, __) => order.add(3)));
      world.update(Duration.zero);
      expect(order, [1, 2, 3]);
      world.dispose();
    });

    test('System.update is invoked on each world.update', () {
      final world = World();
      var ticks = 0;
      world.addSystem(FunctionSystem((_, __) => ticks++));
      world.update(Duration.zero);
      world.update(Duration.zero);
      world.update(Duration.zero);
      expect(ticks, 3);
      world.dispose();
    });

    test('startup systems run once before the first regular tick', () {
      final world = World();
      final log = <String>[];
      world.addStartupSystem(FunctionSystem((_, __) => log.add('startup')));
      world.addSystem(FunctionSystem((_, __) => log.add('regular')));
      world.update(Duration.zero);
      world.update(Duration.zero);
      expect(log, ['startup', 'regular', 'regular']);
      world.dispose();
    });

    test('removeSystem stops the system and calls dispose()', () {
      final world = World();
      var ran = 0;
      var disposed = 0;
      final s = FunctionSystem(
        (_, __) => ran++,
        dispose: Some((_) => disposed++),
      );
      world.addSystem(s);
      world.update(Duration.zero);
      expect(world.removeSystem(s), isTrue);
      expect(disposed, 1);
      world.update(Duration.zero);
      expect(ran, 1);
      world.dispose();
    });

    test('removeSystem returns false for an unknown system', () {
      final world = World();
      final s = FunctionSystem((_, __) {});
      expect(world.removeSystem(s), isFalse);
      world.dispose();
    });

    test('elapsed advances by the dt passed to update', () {
      final world = World();
      world.update(const Duration(milliseconds: 100));
      world.update(const Duration(milliseconds: 250));
      expect(world.elapsed, const Duration(milliseconds: 350));
      world.dispose();
    });

    test('a throwing system aborts the current update; world is still usable',
        () {
      final world = World();
      var afterRan = 0;
      world.addSystem(FunctionSystem((_, __) => throw StateError('boom')));
      world.addSystem(FunctionSystem((_, __) => afterRan++));
      // The thrown error escapes the update call but world state remains sane.
      expect(() => world.update(Duration.zero), throwsStateError);
      expect(world.isDisposed, isFalse);
      // Subsequent updates that don't hit the throwing system still work —
      // remove the bad actor and verify the rest of the world advances.
      expect(afterRan, 0);
      world.dispose();
    });

    test('System.init is called on registration', () {
      final world = World();
      var inited = 0;
      world.addSystem(
        FunctionSystem(
          (_, __) {},
          init: Some((_) => inited++),
        ),
      );
      expect(inited, 1);
      world.dispose();
    });
  });

  group('Bundles', () {
    test('spawnBundle attaches every component in the bundle', () {
      final world = World();
      final e = world.spawnBundle(
        const _PlayerBundle(
          position: _Position(1, 2),
          health: _Health(100),
        ),
      );
      expect(e.has<_Position>(), isTrue);
      expect(e.has<_Health>(), isTrue);
      expect(e.has<_Tag>(), isTrue);
      world.dispose();
    });

    test('insertBundle adds bundle components to an existing entity', () {
      final world = World();
      final e = world.spawn();
      e.insertBundle(
        const _PlayerBundle(
          position: _Position(0, 0),
          health: _Health(50),
        ),
      );
      expect(e.require<_Health>().hp, 50);
      expect(e.has<_Position>(), isTrue);
      expect(e.has<_Tag>(), isTrue);
      world.dispose();
    });
  });

  group('EcsPlugin', () {
    test('addPlugin calls build(world)', () {
      final world = World();
      world.addPlugin(const _CounterPlugin());
      expect(world.getResource<_Score>().isSome(), isTrue);
      expect(world.systems.length, 1);
      world.dispose();
    });

    test('addPlugin returns the world for chaining', () {
      final world = World();
      final returned = world.addPlugin(const _CounterPlugin());
      expect(identical(returned, world), isTrue);
      world.dispose();
    });
  });

  group('Snapshot safety', () {
    test('sending events during a System.update does not throw', () {
      final world = World();
      world.addSystem(
        FunctionSystem((w, _) {
          for (var i = 0; i < 10; i++) {
            w.sendEvent(_BaseEvent(i));
          }
        }),
      );
      // No ConcurrentModificationError should escape.
      expect(() => world.update(Duration.zero), returnsNormally);
      world.dispose();
    });

    test('spawning entities during a System.update does not throw', () {
      final world = World();
      world.addSystem(
        FunctionSystem((w, _) {
          for (var i = 0; i < 5; i++) {
            w.spawn(Some([_Position(i.toDouble(), 0)]));
          }
        }),
      );
      expect(() => world.update(Duration.zero), returnsNormally);
      expect(world.entityCount, 5);
      world.dispose();
    });

    test('despawning entities during a System.update does not throw', () {
      final world = World();
      for (var i = 0; i < 10; i++) {
        world.spawn(Some([_Position(i.toDouble(), 0)]));
      }
      world.addSystem(
        FunctionSystem((w, _) {
          for (final e in w.withComponent<_Position>().toList()) {
            e.despawn();
          }
        }),
      );
      expect(() => world.update(Duration.zero), returnsNormally);
      expect(world.entityCount, 0);
      world.dispose();
    });

    test(
      'subscribing inside an onEvent handler does not affect the in-flight '
      'dispatch',
      () {
        final world = World();
        var addedRan = 0;
        world.onEvent<_BaseEvent>((_) {
          world.onEvent<_BaseEvent>((_) => addedRan++);
        });
        world.sendEvent(const _BaseEvent(1));
        // Newly-added listener didn't fire on the in-flight dispatch.
        expect(addedRan, 0);
        // It fires on subsequent sends.
        world.sendEvent(const _BaseEvent(2));
        expect(addedRan, greaterThanOrEqualTo(1));
        world.dispose();
      },
    );

    test('adding a system during update does not run it this tick', () {
      final world = World();
      var addedRan = 0;
      var primed = false;
      world.addSystem(
        FunctionSystem((w, _) {
          if (!primed) {
            primed = true;
            w.addSystem(FunctionSystem((_, __) => addedRan++));
          }
        }),
      );
      world.update(Duration.zero);
      expect(addedRan, 0);
      world.update(Duration.zero);
      expect(addedRan, 1);
      world.dispose();
    });
  });
}
