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
//
// Audit pass 14 ECS: type-keying consistency and ServiceMixin cascade.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

abstract class _Vehicle extends Component {
  const _Vehicle();
}

final class _Car extends _Vehicle {
  const _Car(this.wheels);
  final int wheels;
}

final class _SpawnedEvent extends Event {
  const _SpawnedEvent(this.id);
  final int id;
}

final class _DespawnedEvent extends _SpawnedEvent {
  const _DespawnedEvent(super.id);
}

class _Score extends Resource with ServiceMixin {
  int value = 0;
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

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // 1. Insert a subclass `_Car`, read by base class `_Vehicle` — currently
  //    the insert keys by `_Car.runtimeType` and the read keys by static
  //    `_Vehicle`, so it returns None. With the fix, insert by `_Vehicle`
  //    (when invoked as `set(entity, car)` and T is Component — actually
  //    set's signature doesn't take T, so we still key by runtime type.
  //    But read with `get<_Car>()` should find a Car inserted as _Car).
  //
  //    The realistic bug to test: `world.set(entity, _Car(4))` inserts under
  //    `_Car`; `world.get<_Car>(entity)` should find it. That already works.
  //    The broken case: `world.set(entity, _Car(4))` inserts under `_Car`;
  //    `world.get<_Vehicle>(entity)` finds nothing. Verify the documented
  //    behavior (you get what you ask for) is consistent.
  // ─────────────────────────────────────────────────────────────────────────
  group('ECS: component type-keying', () {
    test(
      'get<Concrete> finds a component inserted as Concrete',
      () {
        final w = World();
        final e = w.spawn();
        w.set(e, const _Car(4));
        expect(w.get<_Car>(e).isSome(), isTrue);
        w.dispose();
      },
    );

    test(
      'get<Base> on a component inserted as Concrete returns None — '
      'documented "you get what you ask for" behavior',
      () {
        final w = World();
        final e = w.spawn();
        w.set(e, const _Car(4));
        // The current keying contract: insert keys by runtime type, read
        // keys by static type. Cross-hierarchy reads return None.
        expect(w.get<_Vehicle>(e).isNone(), isTrue);
        w.dispose();
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Event keying: sendEvent<DerivedEvent> should reach onEvent<BaseEvent>
  //    listeners (subtype propagation) AND should be readable via
  //    readEvents<BaseEvent>().
  //
  //    Current bug: sendEvent keys by runtimeType, onEvent/readEvents key
  //    by static E. A `DespawnedEvent` sent triggers only `DespawnedEvent`
  //    listeners, not `SpawnedEvent` listeners.
  // ─────────────────────────────────────────────────────────────────────────
  group('ECS: event subtype propagation', () {
    test(
      'sendEvent<DerivedEvent> reaches onEvent<BaseEvent> listeners',
      () {
        final w = World();
        var derivedHits = 0;
        var baseHits = 0;
        w.onEvent<_SpawnedEvent>((_) => baseHits++);
        w.onEvent<_DespawnedEvent>((_) => derivedHits++);
        w.sendEvent(const _DespawnedEvent(42));
        expect(derivedHits, equals(1),
            reason: 'Derived listener must fire on derived event',);
        expect(
          baseHits,
          equals(1),
          reason:
              'Base listener must also fire on derived event — Liskov '
              'substitution applies to ECS events.',
        );
        w.dispose();
      },
    );

    test(
      'readEvents<BaseEvent> returns derived events sent this tick',
      () {
        final w = World();
        w.sendEvent(const _DespawnedEvent(7));
        final base = w.readEvents<_SpawnedEvent>().toList();
        expect(
          base.length,
          equals(1),
          reason:
              'readEvents<Base> must include events sent as Derived for '
              'consistent subtype semantics with onEvent.',
        );
        expect(base.first.id, equals(7));
        w.dispose();
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 3. ServiceMixin cascade on Resource removal.
  //
  //    A Resource that mixes ServiceMixin must have dispose() called when
  //    removed from the world — otherwise streams/timers leak.
  // ─────────────────────────────────────────────────────────────────────────
  group('ECS: ServiceMixin Resource cascade', () {
    test(
      'removeResource<Service> calls dispose()',
      () async {
        final w = World();
        final svc = _Score();
        (await svc.init().toAsync().value).end();
        w.insertResource(svc);
        w.removeResource<_Score>().end();
        // Cascade is fire-and-forget — let the microtask drain.
        await Future<void>.delayed(Duration.zero);
        expect(
          svc.didDispose,
          isTrue,
          reason:
              'A ServiceMixin Resource removed from the world must have '
              "its dispose() called, otherwise it'll leak its subscription "
              'and polling timers.',
        );
        w.dispose();
      },
    );

    test(
      'world.dispose disposes every ServiceMixin Resource',
      () async {
        final w = World();
        final svc = _Score();
        (await svc.init().toAsync().value).end();
        w.insertResource(svc);
        w.dispose();
        await Future<void>.delayed(Duration.zero);
        expect(svc.didDispose, isTrue);
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Re-entrant update must not clear the event buffer mid-outer-tick.
  //    A system that re-enters world.update should not lose events that
  //    OTHER outer-tick systems haven't observed yet.
  // ─────────────────────────────────────────────────────────────────────────
  group('ECS: re-entrant update preserves outer event buffer', () {
    test(
      'a system sending an event then re-entering update; subsequent systems '
      'in the OUTER tick still see the event',
      () {
        final w = World();
        var event1Seen = 0;
        var event2Seen = 0;
        var outerRuns = 0;
        late final FunctionSystem outer;
        outer = FunctionSystem((world, _) {
          outerRuns++;
          if (outerRuns == 1) {
            world.sendEvent(const _SpawnedEvent(1));
            // Re-enter update ONCE. Previously this cleared event buffers
            // at the end of the inner update, losing event1 before observer
            // ran on the outer tick.
            world.update(Duration.zero);
          }
        });
        final observer = FunctionSystem((world, _) {
          for (final e in world.readEvents<_SpawnedEvent>()) {
            if (e.id == 1) event1Seen++;
          }
          for (final _ in world.readEvents<_DespawnedEvent>()) {
            event2Seen++;
          }
        });
        w.addSystem(outer);
        w.addSystem(observer);
        w.update(Duration.zero);
        expect(
          event1Seen,
          greaterThanOrEqualTo(1),
          reason:
              'An event sent by a system before a re-entrant update should '
              'remain visible to later systems in the outer tick.',
        );
        expect(event2Seen, equals(0));
        w.dispose();
      },
    );
  });
}
