// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Tests covering the Bevy-inspired ECS layered on top of DIRegistry. They lock
// down: registry-backed storage, the reverse type-index used by queries,
// concurrent-mutation safety, slot stability under [World.mutate], and the
// startup / update / dispose schedule.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class Position extends Component {
  final double x;
  final double y;
  const Position(this.x, this.y);
}

class SpecialPosition extends Position {
  const SpecialPosition(super.x, super.y);
}

class Velocity extends Component {
  final double dx;
  final double dy;
  const Velocity(this.dx, this.dy);
}

class Health extends Component {
  final int current;
  const Health(this.current);
}

class PlayerTag extends Component {
  const PlayerTag();
}

class Counter extends Resource {
  final int value;
  const Counter(this.value);
}

class Tick extends Event {
  final Duration dt;
  const Tick(this.dt);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() {
  group('ECS basic CRUD', () {
    test('spawn / insert / get / has / remove / despawn', () {
      final world = World();
      final e = world.spawn(Some([const Position(0, 0), const PlayerTag()]));
      expect(e.has<Position>(), isTrue);
      expect(e.has<Velocity>(), isFalse);
      expect(e.require<Position>().x, 0);

      e.insert(const Velocity(1, 2));
      expect(e.require<Velocity>().dx, 1);

      final removed = e.remove<Velocity>();
      expect(removed.isSome(), isTrue);
      expect(e.has<Velocity>(), isFalse);
      expect(e.alive, isTrue);

      e.despawn();
      expect(e.alive, isFalse);
      world.dispose();
    });

    test('empty spawn stays alive via alive-tag, removed when despawned', () {
      final world = World();
      final e = world.spawn();
      expect(e.alive, isTrue);
      expect(world.entities, contains(e));
      e.despawn();
      expect(e.alive, isFalse);
      expect(world.entities, isNot(contains(e)));
      world.dispose();
    });

    test('removing the last real component re-attaches the alive-tag', () {
      final world = World();
      final e = world.spawn(Some([const Position(0, 0)]));
      e.remove<Position>().end();
      // Entity is still alive (no real components, but anchored by alive-tag).
      expect(e.alive, isTrue);
      expect(world.entities, contains(e));
      e.despawn();
      expect(e.alive, isFalse);
      world.dispose();
    });

    test('require throws when component absent', () {
      final world = World();
      final e = world.spawn();
      expect(() => e.require<Position>(), throwsStateError);
      world.dispose();
    });
  });

  group('Reverse type-index queries', () {
    test('withComponent returns only matching alive entities', () {
      final world = World();
      final movers = [
        world.spawn(Some([const Position(0, 0), const Velocity(1, 0)])),
        world.spawn(Some([const Position(5, 5), const Velocity(0, 1)])),
      ];
      world.spawn(Some([const Position(9, 9)]));
      expect(world.withComponent<Velocity>().toSet(), movers.toSet());
      expect(world.withComponent<Position>().length, 3);
      world.dispose();
    });

    test('query2 / each2 only yield entities with both types', () {
      final world = World();
      final both = world.spawn(Some([const Position(0, 0), const Velocity(1, 0)]));
      world.spawn(Some([const Position(1, 1)]));
      world.spawn(Some([const Velocity(2, 2)]));
      expect(world.query2<Position, Velocity>().single, both);
      final pairs = world.each2<Position, Velocity>().toList();
      expect(pairs.length, 1);
      expect(pairs.single.$1, both);
      expect(pairs.single.$2.x, 0);
      expect(pairs.single.$3.dx, 1);
      world.dispose();
    });

    test('reverse index pruned on remove / despawn', () {
      final world = World();
      final a = world.spawn(Some([const Position(0, 0)]));
      final b = world.spawn(Some([const Position(1, 1)]));
      expect(world.withComponent<Position>().length, 2);
      a.remove<Position>().end();
      expect(world.withComponent<Position>().toList(), [b]);
      b.despawn();
      expect(world.withComponent<Position>(), isEmpty);
      // The reverse index should be empty too — exposed via the registry.
      expect(world.registry.groupsWithTypeT(Position), isEmpty);
      world.dispose();
    });

    test('queryTypes intersects via the smallest bucket', () {
      final world = World();
      // Lots of Positions, few Velocities — the smallest bucket drives the loop.
      for (var i = 0; i < 100; i++) {
        world.spawn(Some([Position(i.toDouble(), 0)]));
      }
      final movers = [
        world.spawn(Some([const Position(0, 0), const Velocity(1, 0)])),
        world.spawn(Some([const Position(5, 5), const Velocity(2, 0)])),
      ];
      expect(
        world.queryTypes([Position, Velocity]).toSet(),
        movers.toSet(),
      );
      world.dispose();
    });
  });

  group('Concurrent-mutation safety', () {
    test('despawn while iterating withComponent does not throw', () {
      final world = World();
      for (var i = 0; i < 10; i++) {
        world.spawn(Some([Position(i.toDouble(), 0)]));
      }
      final seen = <WorldEntity>[];
      for (final e in world.withComponent<Position>()) {
        seen.add(e);
        e.despawn();
      }
      expect(seen.length, 10);
      expect(world.withComponent<Position>(), isEmpty);
      world.dispose();
    });

    test('despawn while iterating each2 does not throw', () {
      final world = World();
      for (var i = 0; i < 10; i++) {
        world.spawn(Some([Position(i.toDouble(), 0), Velocity(i.toDouble(), 0)]));
      }
      final seen = <WorldEntity>[];
      for (final (e, _, __) in world.each2<Position, Velocity>()) {
        seen.add(e);
        e.despawn();
      }
      expect(seen.length, 10);
      world.dispose();
    });

    test('addSystem inside a running system does not throw', () {
      final world = World();
      var inner = 0;
      world.addSystem(
        FunctionSystem((w, _) {
          w.addSystem(FunctionSystem((_, __) => inner++));
        }),
      );
      // Should not raise ConcurrentModificationError.
      world.update(Duration.zero);
      // The new system is registered but only runs on the NEXT update.
      expect(inner, 0);
      world.update(Duration.zero);
      expect(inner, 1);
      world.dispose();
    });
  });

  group('mutate slot stability', () {
    test('mutate preserves the slot key under T, not next.runtimeType', () {
      final world = World();
      final e = world.spawn(Some([const Position(0, 0)]));
      final result = e.mutate<Position>(
        (p) => SpecialPosition(p.x + 1, p.y + 1),
      );
      expect(result.isSome(), isTrue);
      // The Position slot now holds the SpecialPosition value — there should be
      // exactly one component, not two.
      expect(e.has<Position>(), isTrue);
      expect(e.has<SpecialPosition>(), isFalse);
      expect(e.require<Position>(), isA<SpecialPosition>());
      world.dispose();
    });

    test('mutate is a no-op when the component is missing', () {
      final world = World();
      final e = world.spawn();
      final result = e.mutate<Position>((p) => Position(p.x + 1, p.y));
      expect(result.isNone(), isTrue);
      expect(e.has<Position>(), isFalse);
      world.dispose();
    });
  });

  group('Resources', () {
    test('insert / get / require / remove resource', () {
      final world = World();
      world.insertResource(const Counter(5));
      expect(world.requireResource<Counter>().value, 5);
      world.insertResource(const Counter(7));
      expect(world.requireResource<Counter>().value, 7);
      final removed = world.removeResource<Counter>();
      expect(removed.isSome(), isTrue);
      expect(world.getResource<Counter>().isNone(), isTrue);
      expect(() => world.requireResource<Counter>(), throwsStateError);
      world.dispose();
    });

    test('resource group is not exposed as an entity', () {
      final world = World();
      world.insertResource(const Counter(1));
      expect(world.entities, isEmpty);
      expect(world.entityCount, 0);
      world.dispose();
    });
  });

  group('Systems & schedule', () {
    test('startup systems run once before regular systems', () {
      final world = World();
      final log = <String>[];
      world.addStartupSystem(
        FunctionSystem((w, _) => log.add('startup')),
      );
      world.addSystem(FunctionSystem((w, _) => log.add('update')));
      world.update(const Duration(milliseconds: 16));
      world.update(const Duration(milliseconds: 16));
      expect(log, ['startup', 'update', 'update']);
      world.dispose();
    });

    test('removeSystem calls dispose and stops the system', () {
      final world = World();
      var ran = 0;
      var disposed = 0;
      final s = FunctionSystem(
        (w, _) => ran++,
        dispose: Some((_) { disposed++; }),
      );
      world.addSystem(s);
      world.update(Duration.zero);
      expect(ran, 1);
      expect(world.removeSystem(s), isTrue);
      expect(disposed, 1);
      world.update(Duration.zero);
      expect(ran, 1);
      world.dispose();
    });

    test('elapsed advances by dt', () {
      final world = World();
      world.update(const Duration(milliseconds: 100));
      world.update(const Duration(milliseconds: 50));
      expect(world.elapsed, const Duration(milliseconds: 150));
      world.dispose();
    });

    test('dispose disposes systems and makes update a no-op', () {
      final world = World();
      var ran = 0;
      var disposed = 0;
      world.addSystem(
        FunctionSystem(
          (w, _) => ran++,
          dispose: Some((_) { disposed++; }),
        ),
      );
      world.dispose();
      expect(disposed, 1);
      expect(world.isDisposed, isTrue);
      world.update(Duration.zero);
      expect(ran, 0);
    });
  });

  group('Events', () {
    test('onEvent fires synchronously on sendEvent', () {
      final world = World();
      final received = <Duration>[];
      world.onEvent<Tick>((e) => received.add(e.dt));
      world.sendEvent(const Tick(Duration(milliseconds: 16)));
      world.sendEvent(const Tick(Duration(milliseconds: 33)));
      expect(received, [
        const Duration(milliseconds: 16),
        const Duration(milliseconds: 33),
      ]);
      world.dispose();
    });

    test('readEvents drains at end of update', () {
      final world = World();
      world.addSystem(
        FunctionSystem((w, dt) => w.sendEvent(Tick(dt))),
      );
      var seen = <Duration>[];
      world.addSystem(
        FunctionSystem((w, _) {
          for (final e in w.readEvents<Tick>()) {
            seen.add(e.dt);
          }
        }),
      );
      world.update(const Duration(milliseconds: 16));
      expect(seen, [const Duration(milliseconds: 16)]);
      // Buffer cleared at end of update.
      seen = [];
      world.update(Duration.zero);
      expect(seen, [Duration.zero]);
      world.dispose();
    });

    test('unsubscribe stops further callbacks', () {
      final world = World();
      var n = 0;
      final off = world.onEvent<Tick>((_) => n++);
      world.sendEvent(const Tick(Duration.zero));
      off();
      world.sendEvent(const Tick(Duration.zero));
      expect(n, 1);
      world.dispose();
    });
  });

  group('DIRegistry coupling', () {
    test('World.registry sees components as DI dependencies', () {
      final world = World();
      final e = world.spawn(Some([const Position(1, 2)]));
      // The component is a real DI dependency keyed by TypeEntity(Position).
      final group = world.registry.getGroup(groupEntity: e);
      expect(group.containsKey(TypeEntity(Position)), isTrue);
      world.dispose();
    });

    test('registry.groupsWithTypeT mirrors withComponent', () {
      final world = World();
      world.spawn(Some([const Position(1, 2)]));
      world.spawn(Some([const Position(3, 4)]));
      world.spawn(Some([const Velocity(0, 0)]));
      expect(world.registry.groupsWithTypeT(Position).length, 2);
      expect(world.registry.groupsWithTypeT(Velocity).length, 1);
      world.dispose();
    });

    test('registry.clear via World.dispose empties everything', () {
      final world = World()..insertResource(const Counter(1));
      world.spawn(Some([const Position(0, 0)]));
      world.dispose();
      expect(world.registry.groupEntities, isEmpty);
      expect(world.registry.groupsWithTypeT(Position), isEmpty);
    });
  });
}
