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
// Audit pass 14: state machine invariants + hierarchy-mutation completer
// cleanup. Each test demonstrates a mission-critical reliability gap that
// callers would observe before the fix.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

class _Svc with ServiceMixin {
  int initRuns = 0;
  int disposeRuns = 0;

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) => Sync<Unit>(() {
              initRuns++;
              return Unit();
            }),
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
              disposeRuns++;
              return Unit();
            }),
      ];
}

final class _A {
  const _A();
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // 1. init() called after dispose() must NOT silently succeed.
  //    A caller of `await svc.init()` who got Ok back currently has no way
  //    to tell whether init actually ran or was silently dropped because
  //    the service was already disposed.
  // ─────────────────────────────────────────────────────────────────────────
  group('service: init-after-dispose must error', () {
    test(
      'init() after dispose() resolves to Err (not Ok), and does not run '
      'init listeners',
      () async {
        final svc = _Svc();
        (await svc.init().toAsync().value).end();
        (await svc.dispose().toAsync().value).end();
        expect(svc.state.didDispose(), isTrue);

        final initRunsBefore = svc.initRuns;
        final result = await svc.init().toAsync().value;
        expect(svc.initRuns, equals(initRunsBefore),
            reason: 'init listeners must NOT re-run after dispose',);
        expect(
          result.isErr(),
          isTrue,
          reason:
              'init() after dispose() must resolve to Err so callers can '
              'distinguish "init succeeded" from "init was skipped because '
              'service is already disposed".',
        );
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. pause() / resume() must not silently run when the service has never
  //    been initialized — that's an invariant gap that lets the state
  //    machine reach PAUSE_SUCCESS without ever passing through RUN_*.
  // ─────────────────────────────────────────────────────────────────────────
  group('service: pause/resume invariants', () {
    test(
      'pause() on never-inited service resolves to Err',
      () async {
        final svc = _Svc();
        expect(svc.state, equals(ServiceState.NOT_INITIALIZED));
        final result = await svc.pause().toAsync().value;
        expect(
          result.isErr(),
          isTrue,
          reason:
              'pause() before init() is a contract violation — must Err so '
              'lifecycle bugs surface instead of silently transitioning.',
        );
        expect(svc.state, equals(ServiceState.NOT_INITIALIZED),
            reason: 'state must remain NOT_INITIALIZED on invalid pause',);
      },
    );

    test(
      'resume() on never-inited service resolves to Err',
      () async {
        final svc = _Svc();
        final result = await svc.resume().toAsync().value;
        expect(result.isErr(), isTrue);
        expect(svc.state, equals(ServiceState.NOT_INITIALIZED));
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 3. `untilSuper` cleanup must survive hierarchy mutation between seed
  //    and resolution. If a parent is added or removed mid-wait, the
  //    completer must still be reachable for unregister.
  // ─────────────────────────────────────────────────────────────────────────
  group('untilSuper: completer cleanup under hierarchy mutation', () {
    test(
      'cleanup walks the ORIGINAL seeded ancestors, not the current ones',
      () async {
        final parent = DI();
        final child = DI();
        child.parents.add(parent);

        // Start a waiter: this seeds a completer into child + parent.
        final waiter = child.untilSuper<_A>().toAsync().value;

        // Add a NEW parent AFTER seeding.
        final newParent = DI();
        child.parents.add(newParent);

        // Now register at the original parent.
        parent.register<_A>(const _A()).end();

        // The waiter must resolve. The seeded completer was in child + ORIGINAL
        // parent (not newParent). After resolution, cleanup runs unregister
        // and must remove the completer from the ORIGINAL seeded locations.
        final result = await waiter;
        expect(result.isOk(), isTrue);

        // Verify the completer is not leaked in either parent. (Iterates the
        // registry; an orphaned completer would show up here.)
        var orphanCount = 0;
        for (final di in [parent, newParent, child]) {
          for (final group in di.registry.state.values) {
            for (final dep in group.values) {
              if (dep.value is Sync) {
                final v = dep.value as Sync;
                final r = v.value;
                if (r.isOk()) {
                  UNSAFE:
                  if (r.unwrap().runtimeType.toString().contains(
                        'ReservedSafeCompleter',
                      )) {
                    orphanCount++;
                  }
                }
              }
            }
          }
        }
        expect(
          orphanCount,
          equals(0),
          reason:
              'After untilSuper resolves, no ReservedSafeCompleter should '
              'remain registered in any container in the hierarchy.',
        );
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Two `untilSuper` waiters from sibling children sharing one parent —
  //    each MUST get its own completer (or share but resolve independently
  //    via identity-based cleanup). Currently shared completer is fine, but
  //    one resolving must not orphan the other.
  // ─────────────────────────────────────────────────────────────────────────
  group('untilSuper: sibling waiters do not interfere', () {
    test(
      'sibling waiters both resolve when parent registers, no leaked '
      'completers',
      () async {
        final parent = DI();
        final c1 = DI();
        final c2 = DI();
        c1.parents.add(parent);
        c2.parents.add(parent);

        final f1 = c1.untilSuper<_A>().toAsync().value;
        final f2 = c2.untilSuper<_A>().toAsync().value;

        parent.register<_A>(const _A()).end();

        await f1;
        await f2;

        // After both resolve, neither child nor parent should still hold a
        // ReservedSafeCompleter for _A.
        var orphanCount = 0;
        for (final di in [parent, c1, c2]) {
          for (final group in di.registry.state.values) {
            for (final dep in group.values) {
              if (dep.value is Sync) {
                final v = dep.value as Sync;
                final r = v.value;
                if (r.isOk()) {
                  UNSAFE:
                  if (r.unwrap().runtimeType.toString().contains(
                        'ReservedSafeCompleter',
                      )) {
                    orphanCount++;
                  }
                }
              }
            }
          }
        }
        expect(
          orphanCount,
          equals(0),
          reason:
              'Sibling waiters resolving independently must not orphan '
              "each other's completers.",
        );
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 5. StreamSubscription cancel that throws must not poison the rest of
  //    the stopStream chain.
  // ─────────────────────────────────────────────────────────────────────────
  // (Direct test of internal robustness deferred to integration; the
  //  symptomatic failure is "the sequencer chain hangs forever". Hard to
  //  reproduce without a controllable Stream. Skipping for now.)
}
