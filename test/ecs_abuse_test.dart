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

// ECS abuse tests. Mission-critical contracts:
//
//   • Queries iterate a SNAPSHOT — callers can despawn / spawn during
//     iteration without skipping or crashing.
//   • `mutate` preserves the slot key when the function returns a subclass.
//   • `removeSystem` during update completes the current tick safely.
//   • `addSystem` during update does NOT run the new system this tick.
//   • Recursive `sendEvent` inside a listener does not deadlock.
//   • dispose() during update is honored; further update calls are no-ops.
//   • `clearEntities` does not break resources or systems.
//   • Per-entity component count stays consistent under heavy churn.
//   • The alive-tag is auto-replaced when the last real component leaves.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

class _Position extends Component {
  const _Position(this.x, this.y);
  final int x;
  final int y;
}

class _Velocity extends Component {
  const _Velocity(this.dx, this.dy);
  final int dx;
  final int dy;
}

class _Health extends Component {
  const _Health(this.hp);
  final int hp;
}

class _DamageBuff extends _Health {
  const _DamageBuff(super.hp, this.extra);
  final int extra;
}

class _Score extends Resource {
  const _Score(this.value);
  final int value;
}

class _PlayerSpawned extends Event {
  const _PlayerSpawned(this.id);
  final int id;
}

class _ChainEvent extends Event {
  const _ChainEvent(this.depth);
  final int depth;
}

void main() {
  // ── Query snapshot safety ─────────────────────────────────────────────────
  group('queries are snapshot-safe', () {
    test(
      'despawning entities during each1 iteration does not crash and yields a '
      'consistent snapshot',
      () {
        final w = World();
        for (var i = 0; i < 100; i++) {
          w.spawn(Some([_Position(i, 0)]));
        }
        final seen = <int>[];
        for (final (entity, pos) in w.each1<_Position>()) {
          seen.add(pos.x);
          // Despawn every other entity mid-iteration.
          if (pos.x.isOdd) entity.despawn();
        }
        expect(seen.length, 100);
        // After iteration, only even-x entities remain.
        final remaining = w.each1<_Position>().map((e) => e.$2.x).toSet();
        for (var n = 0; n < 100; n++) {
          if (n.isEven) {
            expect(remaining.contains(n), isTrue);
          } else {
            expect(remaining.contains(n), isFalse);
          }
        }
        w.dispose();
      },
    );

    test('spawning new entities during each1 does NOT include them this pass',
        () {
      final w = World();
      for (var i = 0; i < 10; i++) {
        w.spawn(Some([_Position(i, 0)]));
      }
      var iter = 0;
      for (final (_, _) in w.each1<_Position>()) {
        iter++;
        // Spawn during iteration — must NOT lengthen this iteration.
        if (iter == 1) {
          for (var n = 0; n < 5; n++) {
            w.spawn(Some([_Position(100 + n, 0)]));
          }
        }
      }
      expect(iter, 10, reason: 'snapshot must be 10, not 15');
      // The next pass sees all 15.
      expect(w.each1<_Position>().length, 15);
      w.dispose();
    });
  });

  // ── mutate semantics ──────────────────────────────────────────────────────
  group('mutate semantics', () {
    test(
      'mutate that returns a subclass keeps the slot keyed by T, not subclass',
      () {
        final w = World();
        final e = w.spawn(const Some([_Health(10)]));
        // Mutate _Health: return a _DamageBuff (subclass).
        final newVal = e.mutate<_Health>((h) => _DamageBuff(h.hp + 5, 3));
        UNSAFE:
        expect(newVal.unwrap().hp, 15);
        // Reading via get<_Health>() should return the new value (NOT None,
        // because the slot remains keyed by _Health).
        UNSAFE:
        final read = e.get<_Health>().unwrap();
        expect(read.hp, 15);
        expect(read, isA<_DamageBuff>());
        w.dispose();
      },
    );

    test('mutate on a missing component returns None', () {
      final w = World();
      final e = w.spawn();
      final out = e.mutate<_Health>((h) => _Health(h.hp + 1));
      expect(out.isNone(), isTrue);
      w.dispose();
    });
  });

  // ── alive-tag invariant ───────────────────────────────────────────────────
  group('alive-tag invariant', () {
    test(
      'entity spawned with no components stays visible in entities/until '
      'despawn',
      () {
        final w = World();
        final e = w.spawn();
        expect(w.entities.contains(e), isTrue);
        expect(e.alive, isTrue);
        e.despawn();
        expect(e.alive, isFalse);
        w.dispose();
      },
    );

    test(
      'removing the LAST real component re-attaches the alive-tag so the '
      'entity remains visible',
      () {
        final w = World();
        final e = w.spawn(const Some([_Position(1, 1)]));
        expect(w.entities.contains(e), isTrue);
        e.remove<_Position>().end();
        // After removing the only real component, alive-tag must be back.
        expect(w.entities.contains(e), isTrue);
        expect(e.alive, isTrue);
        // Adding a real component replaces the alive-tag.
        e.insert(const _Health(10));
        expect(w.entities.contains(e), isTrue);
        w.dispose();
      },
    );
  });

  // ── System schedule mutations ────────────────────────────────────────────
  group('system schedule mutations during update', () {
    test('removing a system during its own update completes this tick safely',
        () {
      final w = World();
      late FunctionSystem suicide;
      var ticks = 0;
      suicide = FunctionSystem((world, _) {
        ticks++;
        world.removeSystem(suicide);
      });
      w.addSystem(suicide);
      w.update(Duration.zero);
      expect(ticks, 1);
      // Second update: system is gone, no tick.
      w.update(Duration.zero);
      expect(ticks, 1);
      w.dispose();
    });

    test('adding a system during update does NOT fire the new one this tick',
        () {
      final w = World();
      var addedRan = 0;
      var addedSeen = false;
      w.addSystem(FunctionSystem((world, _) {
        if (!addedSeen) {
          addedSeen = true;
          world.addSystem(FunctionSystem((_, __) {
            addedRan++;
          }),);
        }
      }),);
      w.update(Duration.zero);
      expect(addedRan, 0, reason: 'newly-added system runs on the NEXT tick');
      w.update(Duration.zero);
      expect(addedRan, 1);
      w.dispose();
    });

    test(
      'startup systems run exactly once before any regular tick',
      () {
        final w = World();
        var startupTicks = 0;
        var regularTicks = 0;
        w.addStartupSystem(FunctionSystem((_, __) => startupTicks++));
        w.addSystem(FunctionSystem((_, __) => regularTicks++));
        w.update(Duration.zero);
        w.update(Duration.zero);
        w.update(Duration.zero);
        expect(startupTicks, 1);
        expect(regularTicks, 3);
        w.dispose();
      },
    );
  });

  // ── Resources ─────────────────────────────────────────────────────────────
  group('resources', () {
    test('insertResource overwrites the existing value', () {
      final w = World();
      w.insertResource(const _Score(0));
      UNSAFE:
      expect(w.getResource<_Score>().unwrap().value, 0);
      w.insertResource(const _Score(42));
      UNSAFE:
      expect(w.getResource<_Score>().unwrap().value, 42);
      w.dispose();
    });

    test('requireResource throws on missing', () {
      final w = World();
      expect(() => w.requireResource<_Score>(), throwsStateError);
      w.dispose();
    });

    test('removeResource clears it', () {
      final w = World();
      w.insertResource(const _Score(1));
      final out = w.removeResource<_Score>();
      UNSAFE:
      expect(out.unwrap().value, 1);
      expect(w.getResource<_Score>().isNone(), isTrue);
      w.dispose();
    });

    test('clearEntities does NOT remove resources', () {
      final w = World();
      w.insertResource(const _Score(7));
      w.spawn(const Some([_Position(0, 0)]));
      w.spawn(const Some([_Position(1, 1)]));
      w.clearEntities();
      expect(w.entityCount, 0);
      // Resource survives.
      expect(w.getResource<_Score>().isSome(), isTrue);
      w.dispose();
    });
  });

  // ── Events ────────────────────────────────────────────────────────────────
  group('events', () {
    test('synchronous dispatch fires every subscriber in order', () {
      final w = World();
      final order = <String>[];
      w.onEvent<_PlayerSpawned>((e) => order.add('A:${e.id}'));
      w.onEvent<_PlayerSpawned>((e) => order.add('B:${e.id}'));
      w.sendEvent(const _PlayerSpawned(7));
      expect(order, equals(['A:7', 'B:7']));
      w.dispose();
    });

    test(
      'unsubscribing inside a handler does NOT affect the in-flight dispatch',
      () {
        final w = World();
        final order = <String>[];
        late void Function() unsubB;
        unsubB = w.onEvent<_PlayerSpawned>((e) {
          order.add('B:${e.id}');
          unsubB();
        });
        w.onEvent<_PlayerSpawned>((e) => order.add('C:${e.id}'));
        w.sendEvent(const _PlayerSpawned(1));
        // B and C both fire on this dispatch.
        expect(order, equals(['B:1', 'C:1']));
        order.clear();
        w.sendEvent(const _PlayerSpawned(2));
        // B is gone now.
        expect(order, equals(['C:2']));
        w.dispose();
      },
    );

    test(
      'recursive sendEvent inside a listener does not deadlock or stack '
      'overflow',
      () {
        final w = World();
        final depths = <int>[];
        w.onEvent<_ChainEvent>((e) {
          depths.add(e.depth);
          if (e.depth < 5) {
            w.sendEvent(_ChainEvent(e.depth + 1));
          }
        });
        w.sendEvent(const _ChainEvent(0));
        expect(depths, equals([0, 1, 2, 3, 4, 5]));
        w.dispose();
      },
    );

    test('readEvents returns events sent this tick; clears after update', () {
      final w = World();
      w.sendEvent(const _PlayerSpawned(1));
      w.sendEvent(const _PlayerSpawned(2));
      expect(w.readEvents<_PlayerSpawned>().length, 2);
      w.update(Duration.zero);
      // After update, the buffer clears.
      expect(w.readEvents<_PlayerSpawned>().length, 0);
      w.dispose();
    });
  });

  // ── Dispose ───────────────────────────────────────────────────────────────
  group('dispose', () {
    test('update after dispose is a no-op', () {
      final w = World();
      var ticks = 0;
      w.addSystem(FunctionSystem((_, __) => ticks++));
      w.update(Duration.zero);
      expect(ticks, 1);
      w.dispose();
      w.update(Duration.zero);
      w.update(Duration.zero);
      expect(ticks, 1);
    });

    test(
      'dispose cleans up systems, registry, event listeners, event buffers',
      () {
        final w = World();
        w.addSystem(FunctionSystem((_, __) {}));
        w.insertResource(const _Score(1));
        w.spawn(const Some([_Position(0, 0)]));
        w.onEvent<_PlayerSpawned>((_) {});
        w.sendEvent(const _PlayerSpawned(1));
        w.dispose();
        expect(w.systems, isEmpty);
        expect(w.entityCount, 0);
        expect(w.getResource<_Score>().isNone(), isTrue);
        expect(w.readEvents<_PlayerSpawned>().length, 0);
        expect(w.isDisposed, isTrue);
      },
    );
  });

  // ── High-throughput sanity ────────────────────────────────────────────────
  group('high-throughput sanity', () {
    test(
      '5000 entities × 3 components each — query and despawn all stay '
      'consistent',
      () {
        final w = World();
        for (var i = 0; i < 5000; i++) {
          w.spawn(Some([
            _Position(i, i),
            const _Velocity(1, 1),
            const _Health(100),
          ]),);
        }
        expect(w.entityCount, 5000);
        expect(w.each2<_Position, _Velocity>().length, 5000);
        expect(w.each3<_Position, _Velocity, _Health>().length, 5000);

        // Despawn every entity with x divisible by 3.
        for (final entity in w.entities.toList()) {
          UNSAFE:
          final pos = entity.get<_Position>().unwrap();
          if (pos.x % 3 == 0) {
            entity.despawn();
          }
        }
        // Remaining count: 5000 - ceil(5000/3) = 5000 - 1667 = 3333.
        expect(w.entityCount, 5000 - (5000 / 3).ceil());
        w.dispose();
      },
    );

    test('500 mutations on a single component preserve slot identity', () {
      final w = World();
      final e = w.spawn(const Some([_Health(0)]));
      for (var i = 1; i <= 500; i++) {
        e.mutate<_Health>((h) => _Health(h.hp + 1)).end();
      }
      UNSAFE:
      expect(e.get<_Health>().unwrap().hp, 500);
      w.dispose();
    });
  });
}
