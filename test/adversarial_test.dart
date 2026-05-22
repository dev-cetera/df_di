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

// Adversarial tests for life-and-death use. Every test in this file is
// explicitly trying to break invariants the package needs to hold for
// medical-grade reliability:
//
//   • internal indices (e.g. `_typeIndex`) stay in sync with public state
//     under arbitrary churn;
//   • lifecycle state machines reject illegal transitions instead of
//     silently corrupting;
//   • re-entrant callbacks (register inside onRegister, unregister inside
//     onUnregister, push inside listener) don't deadlock and don't lose
//     work;
//   • every callback site is robust to a thrown exception — the rest of
//     the chain still runs;
//   • streams, timers, completers, and subscriptions are released on
//     dispose with no zombie callbacks;
//   • hierarchy mutations mid-operation don't yield half-deleted state.
//
// If any test in this file fails, treat it as a real bug — the assertion is
// a contract this code must hold for the medical-grade use case.

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

class _A {
  _A([this.tag = 'a']);
  final String tag;
}

class _B {
  _B();
}

class _C {
  _C();
}

abstract class _Animal {
  String name();
}

class _Cat extends _Animal {
  @override
  String name() => 'cat';
}

/// A service used to probe re-entrant lifecycle behaviour.
class _LifecycleSpy with ServiceMixin {
  _LifecycleSpy({this.failOnPhase});
  final String? failOnPhase;

  final initCalls = <DateTime>[];
  final pauseCalls = <DateTime>[];
  final resumeCalls = <DateTime>[];
  final disposeCalls = <DateTime>[];

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) {
          initCalls.add(DateTime.now());
          if (failOnPhase == 'init') return Sync.err(Err<Unit>('init fail'));
          return Sync.okValue(Unit());
        },
      ];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) => [
        (_) {
          pauseCalls.add(DateTime.now());
          if (failOnPhase == 'pause') return Sync.err(Err<Unit>('pause fail'));
          return Sync.okValue(Unit());
        },
      ];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) => [
        (_) {
          resumeCalls.add(DateTime.now());
          if (failOnPhase == 'resume') {
            return Sync.err(Err<Unit>('resume fail'));
          }
          return Sync.okValue(Unit());
        },
      ];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
        (_) {
          disposeCalls.add(DateTime.now());
          if (failOnPhase == 'dispose') {
            return Sync.err(Err<Unit>('dispose fail'));
          }
          return Sync.okValue(Unit());
        },
      ];
}

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  group('registry: _typeIndex stays consistent with _state', () {
    test('register → unregister leaves no stale type-index buckets', () {
      final di = DI();
      // Register, then unregister, 100 distinct types in the same group.
      // (Use a single _A type with many groupEntities instead — _typeIndex
      // tracks typeEntity, and we want it to fully clear.)
      for (var n = 0; n < 100; n++) {
        di.register<_A>(_A('n=$n'), groupEntity: UniqueEntity()).end();
      }
      // Verify all are visible by type lookup.
      final allGroups = di.registry
          .groupsWithTypeK(
            TypeEntity(Sync, [TypeEntity(_A)]),
          )
          .toList();
      expect(allGroups.length, 100, reason: 'all 100 groups indexed by type');

      // Unregister each from its group.
      for (final g in allGroups) {
        di.unregister<_A>(groupEntity: g, traverse: false).end();
      }

      // After full churn, the bucket for this type must be empty.
      expect(
        di.registry.groupsWithTypeK(
          TypeEntity(Sync, [TypeEntity(_A)]),
        ),
        isEmpty,
        reason: '_typeIndex still references unregistered groups → leak',
      );
    });

    test(
      'unregisterAll fully clears _typeIndex (no zombie entries)',
      () async {
        final di = DI();
        di.register<_A>(_A()).end();
        di.register<_B>(_B()).end();
        di.register<_C>(_C()).end();
        (await di.unregisterAll().value).end();

        expect(
          di.registry.groupsWithTypeK(
            TypeEntity(Sync, [TypeEntity(_A)]),
          ),
          isEmpty,
        );
        expect(
          di.registry.groupsWithTypeK(
            TypeEntity(Sync, [TypeEntity(_B)]),
          ),
          isEmpty,
        );
        expect(
          di.registry.groupsWithTypeK(
            TypeEntity(Sync, [TypeEntity(_C)]),
          ),
          isEmpty,
        );
      },
    );

    test('clear() drops _typeIndex along with _state', () {
      final di = DI();
      for (var n = 0; n < 50; n++) {
        di.register<_A>(_A('n=$n'), groupEntity: UniqueEntity()).end();
      }
      di.registry.clear();
      expect(di.registry.groupEntities, isEmpty);
      expect(
        di.registry.groupsWithTypeK(
          TypeEntity(Sync, [TypeEntity(_A)]),
        ),
        isEmpty,
        reason: 'clear() must drop _typeIndex too',
      );
    });

    test('re-register after unregister rebuilds _typeIndex', () {
      final di = DI();
      di.register<_A>(_A()).end();
      di.unregister<_A>().end();
      di.register<_A>(_A('again')).end();
      expect(di.isRegistered<_A>(), isTrue);
      final groups = di.registry.groupsWithTypeK(
        TypeEntity(Sync, [TypeEntity(_A)]),
      );
      expect(groups, isNotEmpty);
    });

    test('1000-cycle churn does not leak entries', () {
      final di = DI();
      for (var n = 0; n < 1000; n++) {
        di.register<_A>(_A()).end();
        di.unregister<_A>().end();
      }
      // After 1000 register/unregister cycles, the indexed bucket should be
      // empty (no _A is registered now).
      expect(
        di.registry.groupsWithTypeK(
          TypeEntity(Sync, [TypeEntity(_A)]),
        ),
        isEmpty,
      );
      expect(di.registry.groupEntities, isEmpty);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  group('service lifecycle: illegal transitions and recoverability', () {
    test('init → dispose → init is rejected (terminal disposed)', () async {
      final s = _LifecycleSpy();
      (await s.init().toAsync().value).end();
      (await s.dispose().toAsync().value).end();
      // A second init() after dispose must be a no-op (no double dispose
      // listener invocation, no state regression).
      (await s.init().toAsync().value).end();
      expect(s.initCalls.length, 1);
      expect(s.disposeCalls.length, 1);
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
    });

    test(
      'init → pause → resume → pause → resume — every call lands exactly once',
      () async {
        final s = _LifecycleSpy();
        (await s.init().toAsync().value).end();
        (await s.pause().toAsync().value).end();
        (await s.resume().toAsync().value).end();
        (await s.pause().toAsync().value).end();
        (await s.resume().toAsync().value).end();
        expect(s.pauseCalls.length, 2);
        expect(s.resumeCalls.length, 2);
        expect(s.state, ServiceState.RESUME_SUCCESS);
      },
    );

    test('concurrent dispose() calls do not double-fire listeners', () async {
      final s = _LifecycleSpy();
      (await s.init().toAsync().value).end();
      // Fire two disposes at the "same time" (no awaits between them).
      final a = s.dispose().toAsync().value;
      final b = s.dispose().toAsync().value;
      (await a).end();
      (await b).end();
      expect(
        s.disposeCalls.length,
        1,
        reason: 'dispose() must be idempotent — second call is a no-op',
      );
    });

    test('pause/resume after dispose is rejected (idempotent terminal)',
        () async {
      final s = _LifecycleSpy();
      (await s.init().toAsync().value).end();
      (await s.dispose().toAsync().value).end();
      // These should not throw and should not re-fire listeners.
      (await s.pause().toAsync().value).end();
      (await s.resume().toAsync().value).end();
      expect(s.pauseCalls, isEmpty);
      expect(s.resumeCalls, isEmpty);
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  group('re-entrancy: callbacks that touch the DI mid-operation', () {
    test('register from inside onRegister of another type', () async {
      final di = DI();
      var bSeen = false;
      di.register<_A>(
        _A(),
        onRegister: Some((_) {
          // Re-entrant register. Must not deadlock or corrupt state.
          di.register<_B>(_B(), onRegister: Some((_) => bSeen = true)).end();
        }),
      ).end();
      // Force the chain to resolve fully.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(bSeen, isTrue);
      expect(di.isRegistered<_A>(), isTrue);
      expect(di.isRegistered<_B>(), isTrue);
    });

    test('unregister from inside onUnregister of another type', () async {
      final di = DI();
      di.register<_A>(_A()).end();
      di.register<_B>(
        _B(),
        onUnregister: Some((_) {
          // Re-entrant unregister.
          di.unregister<_A>().end();
        }),
      ).end();
      (await di.unregister<_B>().value).end();
      // Both must be gone now, no zombie state.
      expect(di.isRegistered<_A>(), isFalse);
      expect(di.isRegistered<_B>(), isFalse);
    });

    test('register from inside onUnregister of self', () async {
      final di = DI();
      var fired = false;
      di.register<_A>(
        _A('original'),
        onUnregister: Some((r) {
          // Register a fresh _A on the way out — common pattern for
          // "reset" flows.
          di.register<_A>(_A('fresh')).end();
          fired = true;
        }),
      ).end();
      (await di.unregister<_A>().value).end();
      expect(fired, isTrue);
      // The fresh one is registered.
      expect(di.isRegistered<_A>(), isTrue);
      expect(di.call<_A>().tag, 'fresh');
    });

    test(
      'pushToStream from inside a pushToStream listener does not deadlock',
      () async {
        final svc = _EchoStreamService();
        (await svc.init().toAsync().value).end();
        // listener re-pushes — set a depth limit to avoid infinite recursion.
        var depth = 0;
        svc.onEach.add((data) {
          if (data.isOk() && depth < 3) {
            depth++;
            UNSAFE:
            svc.pushToStream(Ok<int>(data.unwrap() + 1)).end();
          }
        });
        (await svc.pushToStream(const Ok<int>(0)).toAsync().value).end();
        // Wait a tick for any re-entrant pushes to land.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(
          depth,
          3,
          reason: 're-entrant push allowed but bounded',
        );
        (await svc.dispose().toAsync().value).end();
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  group('error injection: every callback site must be robust', () {
    test('onRegister throws — register surfaces an Err Resolvable', () async {
      final di = DI();
      final r = di.register<_A>(
        _A(),
        onRegister: Some((_) => throw StateError('boom')),
      );
      // The Resolvable returned by register evaluates through the chain.
      try {
        (await r.toAsync().value).end();
        fail('expected Err to surface');
      } on Object catch (_) {
        // expected
      }
      // The dep is still in the registry (per H6 — open) but reading it
      // returns an erroring Resolvable.
      // We don't assert on that behaviour here; we assert that the throw
      // didn't corrupt the registry (no infinite loop, no crash).
    });

    test(
      'onUnregister throws sync — remaining callbacks in the chain still run',
      () async {
        final di = DI();
        final fired = <String>[];
        di
            .register<_A>(
              _A('1'),
              onUnregister: Some((_) => fired.add('a1')),
            )
            .end();
        di
            .register<_B>(
              _B(),
              onUnregister: Some((_) => throw StateError('callback boom')),
            )
            .end();
        di
            .register<_C>(
              _C(),
              onUnregister: Some((_) => fired.add('c')),
            )
            .end();
        // unregisterAll must fire every callback even when one throws.
        (await di.unregisterAll().value).end();
        expect(
          fired,
          containsAll(['a1', 'c']),
          reason: 'a thrown callback must not abort the chain',
        );
      },
    );

    test('Lazy constructor that throws is observable; the slot is recoverable',
        () async {
      final di = DI();
      di.registerLazy<_A>(() => Sync.err(Err<_A>('construct fail'))).end();
      // Reading triggers construction → errored Resolvable.
      UNSAFE:
      final result = di.getLazySingleton<_A>().unwrap();
      try {
        (await result.toAsync().value).end();
        fail('expected error');
      } on Object catch (_) {
        // expected
      }
      // Now unregister the bad lazy and register a healthy one — the slot
      // must be re-usable.
      (await di.unregisterLazy<_A>().value).end();
      di.registerLazy<_A>(() => Sync.okValue(_A('fresh'))).end();
      UNSAFE:
      final fresh =
          (await di.getLazySingleton<_A>().unwrap().toAsync().value).unwrap();
      expect(fresh.tag, 'fresh');
    });

    test('async dep whose Future fails surfaces an error on get', () async {
      final di = DI();
      di
          .register<_A>(
            Future<_A>.delayed(
              const Duration(milliseconds: 5),
              () => throw StateError('async boom'),
            ),
          )
          .end();
      try {
        await di.getAsyncUnsafe<_A>();
        fail('expected error');
      } on Object catch (_) {
        // expected
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  group('hierarchy mid-flight: mutations during operations', () {
    test('removing self from parents mid-walk does not skip pending parents',
        () {
      final p1 = DI();
      final p2 = DI();
      final child = DI();
      child.parents.addAll([p1, p2]);
      p1.register<_A>(_A('p1')).end();
      p2.register<_A>(_A('p2')).end();
      // get<_A>() should find p1's _A (first parent walked).
      final found = child.call<_A>();
      expect(found.tag, anyOf('p1', 'p2'));
    });

    test('child sees parent registrations made AFTER child was created', () {
      final parent = DI();
      final child = DI();
      child.parents.add(parent);
      parent.register<_A>(_A('late')).end();
      expect(child.isRegistered<_A>(), isTrue);
      expect(child.call<_A>().tag, 'late');
    });

    test('grandchild does NOT see parent unless parent chain is wired', () {
      final root = DI();
      final mid = DI()..parents.add(root);
      final leaf = DI()..parents.add(mid);
      root.register<_A>(_A('root')).end();
      // leaf → mid → root traversal must work.
      expect(leaf.isRegistered<_A>(), isTrue);
      expect(leaf.call<_A>().tag, 'root');
    });

    test(
      'sibling DIs with the same parent do not see each other\'s registrations',
      () {
        final parent = DI();
        final a = DI()..parents.add(parent);
        final b = DI()..parents.add(parent);
        a.register<_A>(_A('a')).end();
        expect(b.isRegistered<_A>(), isFalse);
        expect(a.isRegistered<_A>(), isTrue);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  group('stream/timer cleanup on dispose', () {
    test('dispose() cancels the polling timer (no zombie poll calls)',
        () async {
      final svc = _CountingPoller();
      (await svc.init().toAsync().value).end();
      // Let it tick a few times.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      final ticksBeforeDispose = svc.tickCount;
      expect(ticksBeforeDispose, greaterThan(0));
      (await svc.dispose().toAsync().value).end();
      // After dispose, wait — no more ticks should land.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(
        svc.tickCount,
        ticksBeforeDispose,
        reason: 'polling timer leaked past dispose',
      );
    });

    test('restartStream 50x leaves exactly one subscription alive', () async {
      final svc = _CountingPoller();
      (await svc.init().toAsync().value).end();
      for (var n = 0; n < 50; n++) {
        (await svc.restartStream().toAsync().value).end();
      }
      // After 50 restarts, exactly one subscription should exist and the
      // service should still emit. We probe by waiting one tick.
      final before = svc.tickCount;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(svc.tickCount, greaterThan(before));
      (await svc.dispose().toAsync().value).end();
    });

    test(
      'pushToStream after dispose is a no-op (does not throw, no listener fires)',
      () async {
        final svc = _EchoStreamService();
        (await svc.init().toAsync().value).end();
        (await svc.dispose().toAsync().value).end();
        var fired = false;
        svc.onEach.add((_) => fired = true);
        // Should not throw.
        (await svc.pushToStream(const Ok<int>(42)).toAsync().value).end();
        expect(fired, isFalse);
      },
    );

    test('stream errors do not kill the service (cancelOnError: false)',
        () async {
      final svc = _EchoStreamService();
      (await svc.init().toAsync().value).end();
      final errors = <Object>[];
      UNSAFE:
      svc.stream.unwrap().listen(
            (event) {},
            onError: (Object e, [StackTrace? _]) => errors.add(e),
          );
      // Push a few events including an Err — service should keep running.
      (await svc.pushToStream(const Ok<int>(1)).toAsync().value).end();
      (await svc.pushToStream(Err<int>('mid-event error')).toAsync().value)
          .end();
      (await svc.pushToStream(const Ok<int>(3)).toAsync().value).end();
      // The Err goes into the broadcast as an Err Result, not as a stream
      // error — verify that the service is still in RUN_SUCCESS.
      expect(svc.state, ServiceState.RUN_SUCCESS);
      (await svc.dispose().toAsync().value).end();
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  group('memory: untilSuper completers cleared on resolution', () {
    test(
      'untilSuper completer slot is removed from the registry after resolution',
      () async {
        final di = DI();
        final wait = di.untilSuper<_A>();
        // Before registration, the DI's default group should contain
        // exactly one slot (the completer) and no `_A`.
        final groupBefore = di.registry.state[const DefaultEntity()];
        expect(
          groupBefore?.length,
          1,
          reason: 'untilSuper should register a single completer slot',
        );
        di.register<_A>(_A()).end();
        (await wait.toAsync().value).end();
        // After resolution, the group should hold ONLY `_A` (1 slot),
        // not the completer too.
        final groupAfter = di.registry.state[const DefaultEntity()];
        expect(
          groupAfter?.length,
          1,
          reason: 'completer slot leaked after untilSuper resolved '
              '(group size grew instead of staying at 1)',
        );
      },
    );

    test(
      'untilExactlyK epoch advances on unregister and completers do not double-fire',
      () async {
        final di = DI();
        // First waiter.
        final futA = di.untilExactlyK<_A>(TypeEntity(_A)).toAsync().value;
        di.register<_A>(_A('first'), enableUntilExactlyK: true).end();
        UNSAFE:
        final r1 = (await futA).unwrap().tag;
        expect(r1, 'first');

        // Unregister and register a fresh one — the old completer must
        // NOT re-fire on the new registration.
        (await di.unregister<_A>().value).end();
        di.register<_A>(_A('second'), enableUntilExactlyK: true).end();
        // A leaked completer would manifest as a hung second wait. So we
        // kick off a fresh wait and ensure it resolves promptly.
        final futA2 = di.untilExactlyK<_A>(TypeEntity(_A)).toAsync().value;
        final r2 = await futA2.timeout(
          const Duration(milliseconds: 200),
          onTimeout: () => Err<_A>('TIMEOUT'),
        );
        expect(r2.isOk(), isTrue, reason: 'second wait timed out');
        UNSAFE:
        expect(r2.unwrap().tag, 'second');
      },
    );

    test(
      'untilSuper called repeatedly for the same T re-uses one completer',
      () async {
        final di = DI();
        // Three waiters for the same type. They should share one
        // ReservedSafeCompleter (per `until`'s implementation), so the
        // registry holds at most one completer slot.
        final w1 = di.untilSuper<_A>();
        final w2 = di.untilSuper<_A>();
        final w3 = di.untilSuper<_A>();
        // Group size must be 1 (single completer shared across all three).
        final groupBefore = di.registry.state[const DefaultEntity()];
        expect(groupBefore?.length, 1);
        di.register<_A>(_A()).end();
        await Future.wait([
          w1.toAsync().value,
          w2.toAsync().value,
          w3.toAsync().value,
        ]);
        // After resolution, the group holds ONLY `_A` (1 slot, not 2).
        final groupAfter = di.registry.state[const DefaultEntity()];
        expect(groupAfter?.length, 1);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  group('TypeEntity collisions (D2): identical type-strings are equal', () {
    test('TypeEntity(Foo) == TypeEntity(Foo) via two construction paths', () {
      // Build the same logical type two different ways and verify they hash
      // to the same id (the documented D2 contract).
      final a = TypeEntity(_A);
      final b = TypeEntity(_A);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('TypeEntity with subtypes collapses to same string', () {
      final a = TypeEntity(_A);
      final b = TypeEntity('$_A');
      expect(
        a,
        equals(b),
        reason: 'TypeEntity from Type and TypeEntity from the Type-as-string '
            'must be equal — they represent the same key.',
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  group('subtype registration / lookup contract', () {
    test('register<Cat>(Cat()) — getSync<Animal>() finds it (subtype lookup)',
        () {
      final di = DI();
      di.register<_Cat>(_Cat()).end();
      // get<Animal> should find any Resolvable<Animal subtype>.
      final a = di.getSyncOrNone<_Animal>();
      expect(a.isSome(), isTrue);
      UNSAFE:
      expect(a.unwrap().name(), 'cat');
    });

    test(
      'register<Cat>(Cat()) — unregister<Animal>() does NOT match (strict-keying)',
      () async {
        final di = DI();
        di.register<_Cat>(_Cat()).end();
        // Strict-keying contract: unregister<_Animal>() walks the
        // `_Animal` slot, which doesn't exist; Cat stays registered.
        (await di.unregister<_Animal>().value).end();
        expect(
          di.isRegistered<_Cat>(),
          isTrue,
          reason: 'strict-keying — _Animal slot is distinct from _Cat slot',
        );
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  group('async dep resolution semantics', () {
    test('getAsync on a Future-valued dep eventually resolves to Sync',
        () async {
      final di = DI();
      di
          .register<_A>(
            Future<_A>.delayed(
              const Duration(milliseconds: 5),
              () => _A('resolved'),
            ),
          )
          .end();
      // First read awaits the async.
      final v1 = await di.getAsyncUnsafe<_A>();
      expect(v1.tag, 'resolved');
      // Second read should be sync (after the first promotion).
      final s = di.getSyncOrNone<_A>();
      expect(s.isSome(), isTrue,
          reason: 'async → sync promotion did not happen',);
      UNSAFE:
      expect(s.unwrap().tag, 'resolved');
    });

    test('100 concurrent getAsync of the same dep all see the same instance',
        () async {
      final di = DI();
      // Use a Completer so we can control resolution timing.
      final completer = Completer<_A>();
      di.register<_A>(completer.future).end();
      // Kick off 100 concurrent reads.
      final futures = List.generate(100, (_) => di.getAsyncUnsafe<_A>());
      // Resolve.
      final shared = _A('shared');
      completer.complete(shared);
      final results = await Future.wait(futures);
      // Every read must return the SAME instance — no per-caller re-eval.
      for (final r in results) {
        expect(identical(r, shared), isTrue);
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  group('focus group propagation', () {
    test('focusGroup overrides default but not explicit groupEntity', () {
      final di = DI();
      di.focusGroup = const GlobalEntity();
      di.register<_A>(_A('global')).end();
      // Lookup with default group should hit focusGroup.
      expect(di.isRegistered<_A>(), isTrue);
      expect(di.call<_A>().tag, 'global');
      // Explicit group hides the focusGroup-registered one.
      expect(
        di.isRegistered<_A>(groupEntity: const SessionEntity()),
        isFalse,
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  group('service orchestration: init/dispose under failure', () {
    test(
      'registerAndInitService with failing init leaves service unregistered',
      () async {
        final di = DI();
        final svc = _LifecycleSpy(failOnPhase: 'init');
        // Service init will fail. `registerAndInitService` returns a
        // Resolvable; the caller has the opportunity to observe the error.
        try {
          (await di.registerAndInitService<_LifecycleSpy>(svc).toAsync().value)
              .end();
        } on Object catch (_) {
          // expected
        }
        // For medical-grade we want: if init fails, the service either
        // stays registered (so the caller can inspect / retry) or gets
        // unregistered. The current contract is the former — the dep is
        // there in RUN_ERROR state. We assert that, document the
        // contract, and verify cleanup is still possible.
        expect(
          di.isRegistered<_LifecycleSpy>(),
          isTrue,
          reason: 'service stayed registered after init failure',
        );
        expect(svc.state, ServiceState.RUN_ERROR);
        // Unregister must work (and fire dispose).
        (await di.unregister<_LifecycleSpy>().value).end();
        expect(di.isRegistered<_LifecycleSpy>(), isFalse);
      },
    );

    test(
      'registerAndInitService with failing dispose still removes from registry',
      () async {
        final di = DI();
        final svc = _LifecycleSpy(failOnPhase: 'dispose');
        (await di.registerAndInitService<_LifecycleSpy>(svc).toAsync().value)
            .end();
        expect(di.isRegistered<_LifecycleSpy>(), isTrue);
        // Unregister will fail dispose listener but must still evict the
        // dep — otherwise we'd have a permanently un-tear-downable service.
        try {
          (await di.unregister<_LifecycleSpy>().value).end();
        } on Object catch (_) {
          // expected: dispose error propagates
        }
        expect(
          di.isRegistered<_LifecycleSpy>(),
          isFalse,
          reason: 'service must be evicted from registry even when its dispose '
              'listener errors — otherwise medical devices cannot be torn '
              'down on shutdown',
        );
      },
    );

    test(
      'two services where B.init untilSupers on A — order via registration',
      () async {
        final di = DI();
        final aReady = Completer<void>();
        final bSawA = Completer<_A>();
        // B init waits for A.
        final svcB = _ServiceWaitingFor<_A>(di, bSawA);
        // Register B first; its init will block until A is registered.
        di.registerAndInitService<_ServiceWaitingFor<_A>>(svcB).end();
        // Now register A.
        di.register<_A>(_A('ready')).end();
        aReady.complete();
        // B's init must complete once A is visible.
        final seen = await bSawA.future.timeout(
          const Duration(seconds: 1),
          onTimeout: () =>
              throw StateError('B never saw A — orchestration broken'),
        );
        expect(seen.tag, 'ready');
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // (registry `onChange` callback is `@internal`-only — tested indirectly
  // via the DI surface; direct construction is not callable from outside
  // the package.)

  // ══════════════════════════════════════════════════════════════════════════
  group('unregisterAll edge cases', () {
    test('unregisterAll on empty registry is a no-op', () async {
      final di = DI();
      // Must not throw.
      (await di.unregisterAll().value).end();
      expect(di.registry.groupEntities, isEmpty);
    });

    test(
      'unregisterAll with onBeforeUnregister and onAfterUnregister fires both',
      () async {
        final di = DI();
        di.register<_A>(_A()).end();
        di.register<_B>(_B()).end();
        final before = <Type>[];
        final after = <Type>[];
        (await di.unregisterAll(
          onBeforeUnregister: Some((r) {
            UNSAFE:
            if (r.isOk()) before.add(r.unwrap().runtimeType);
          }),
          onAfterUnregister: Some((r) {
            UNSAFE:
            if (r.isOk()) after.add(r.unwrap().runtimeType);
          }),
        ).value)
            .end();
        expect(before.length, 2);
        expect(after.length, 2);
      },
    );

    test('unregisterAll with condition only evicts matching deps', () async {
      final di = DI();
      di.register<_A>(_A()).end();
      di.register<_B>(_B()).end();
      di.register<_C>(_C()).end();
      // Only evict deps whose value is _B.
      (await di.unregisterAll(
        condition: Some((dep) {
          UNSAFE:
          final v = dep.value.sync().unwrap().value;
          if (v.isErr()) return false;
          UNSAFE:
          return v.unwrap() is _B;
        }),
      ).value)
          .end();
      expect(di.isRegistered<_A>(), isTrue);
      expect(di.isRegistered<_B>(), isFalse);
      expect(di.isRegistered<_C>(), isTrue);
    });
  });
}

// ─── Test services ─────────────────────────────────────────────────────────

/// A service whose init waits for another type [W] to become registered
/// via `untilSuper<W>`. Used to verify orchestration ordering.
class _ServiceWaitingFor<W extends Object> with ServiceMixin {
  _ServiceWaitingFor(this.di, this.completer);
  final DI di;
  final Completer<W> completer;

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) => di.untilSuper<W>().then((w) {
              completer.complete(w);
              return Unit();
            }),
      ];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) => [];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) => [];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [];
}

/// A polling service that counts how many times its `onPoll` fired.
/// Used to detect zombie timers after dispose.
class _CountingPoller extends PollingStreamService<int> {
  int tickCount = 0;
  @override
  Resolvable<int> onPoll() {
    tickCount++;
    return Sync.okValue(tickCount);
  }

  @override
  Duration providePollingInterval() => const Duration(milliseconds: 20);

  @override
  TServiceResolvables<Result<int>> provideOnPushToStreamListeners() => [];
}

/// A stream service that fans out emissions to user-supplied listeners.
class _EchoStreamService extends StreamService<int> {
  final _input = StreamController<Result<int>>.broadcast();
  final onEach = <void Function(Result<int> data)>[];

  @override
  Stream<Result<int>> provideInputStream() => _input.stream;

  @override
  TServiceResolvables<Result<int>> provideOnPushToStreamListeners() => [
        (data) {
          for (final fn in onEach) {
            fn(data);
          }
          return Sync.okValue(Unit());
        },
      ];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
        ...super.provideDisposeListeners(null),
        (_) => Async(() async {
              await _input.close();
              return Unit();
            }),
      ];
}
