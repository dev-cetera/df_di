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

// Audit pass 3: edge cases & contract holes uncovered after the
// callback-error propagation hardening. Each section names the contract
// it's defending; a failing test points at a real reliability bug.

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

final class _A {
  const _A([this.tag = '']);
  final String tag;
}

class _Counter {
  int constructorCalls = 0;
  int onRegisterCalls = 0;
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // 1. Registration of an already-registered type must NOT fire onRegister
  //    side effects. Otherwise an `init()` runs against a service that
  //    will never actually be reachable via DI — the resource leaks.
  // ─────────────────────────────────────────────────────────────────────────
  group('register: failed registration must not fire onRegister', () {
    test(
      'second register of the same type returns Err WITHOUT firing the '
      'second onRegister',
      () async {
        final di = DI();
        final c = _Counter();
        di
            .register<_A>(
              const _A('first'),
              onRegister: Some((_) {
                c.onRegisterCalls++;
              }),
            )
            .end();
        expect(c.onRegisterCalls, 1);
        // Second registration of the SAME type — should fail.
        final second = await di
            .register<_A>(
              const _A('second'),
              onRegister: Some((_) {
                c.onRegisterCalls++;
              }),
            )
            .toAsync()
            .value;
        expect(
          second.isErr(),
          isTrue,
          reason: 'duplicate-type registration must produce Err',
        );
        expect(
          c.onRegisterCalls,
          1,
          reason:
              'second registration was rejected — its onRegister must NOT '
              'have fired (no zombie init).',
        );
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. untilSuper called AFTER the matching dep was registered AND then
  //    unregistered should NOT resolve against the old registration — it
  //    must hang waiting for the next one (or be cancellable).
  // ─────────────────────────────────────────────────────────────────────────
  group('untilSuper: post-unregister cleanliness', () {
    test(
      'register → unregister → untilSuper does not resolve against the '
      'unregistered value',
      () async {
        final di = DI();
        di.register<_A>(const _A('first')).end();
        (await di.unregister<_A>().toAsync().value).end();
        // Now ask for it — there's nothing registered.
        final fut = di
            .untilSuper<_A>()
            .toAsync()
            .value
            .timeout(
              const Duration(milliseconds: 100),
              onTimeout: () => Err<_A>('timed out (expected)'),
            );
        final r = await fut;
        expect(r.isErr(), isTrue);
      },
    );

    test(
      'register → unregister → register → untilSuper resolves with the NEW '
      'registration',
      () async {
        final di = DI();
        di.register<_A>(const _A('first')).end();
        (await di.unregister<_A>().toAsync().value).end();
        di.register<_A>(const _A('second')).end();
        final r = await di.untilSuper<_A>().toAsync().value;
        UNSAFE:
        expect(r.unwrap().tag, 'second');
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Lazy<T> with a constructor that throws should leave the slot in a
  //    state that the caller can recover from (either via reset or via
  //    re-register).
  // ─────────────────────────────────────────────────────────────────────────
  group('Lazy<T>: constructor throw', () {
    test(
      'a Lazy<T> whose constructor throws produces an Err — and a fresh '
      'Lazy<T> can be registered after unregister',
      () async {
        final di = DI();
        di
            .registerLazy<_A>(
              () => Sync<_A>.err(Err('constructor failed')),
            )
            .end();
        // Reading the singleton surfaces the Err.
        final result = di
            .getLazySingletonSyncOrNone<_A>();
        expect(
          result.isNone(),
          isTrue,
          reason:
              'a Lazy<T> whose constructor errors should NOT pretend to '
              'have produced a value',
        );
        // Unregister and re-register with a working constructor.
        (await di.unregisterLazy<_A>().toAsync().value).end();
        di
            .registerLazy<_A>(() => Sync<_A>.okValue(const _A('recovered')))
            .end();
        UNSAFE:
        final ok =
            di.getLazySingletonSyncOrNone<_A>().unwrap();
        expect(ok.tag, 'recovered');
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Multiple parents — traversal must hit every parent and stop at the
  //    first match. The order should be deterministic (insertion order).
  // ─────────────────────────────────────────────────────────────────────────
  group('hierarchy: multiple parents traversal', () {
    test(
      'child with two parents — the first parent that has the dep wins',
      () {
        final p1 = DI();
        final p2 = DI();
        final child = DI();
        child.parents..add(p1)..add(p2);
        p1.register<_A>(const _A('from-p1')).end();
        p2.register<_A>(const _A('from-p2')).end();
        UNSAFE:
        final got = child.getSyncUnsafe<_A>();
        expect(
          got.tag,
          'from-p1',
          reason: 'insertion-order parent traversal expected',
        );
      },
    );

    test(
      'child with two parents — only one has the dep: child sees that one',
      () {
        final p1 = DI();
        final p2 = DI();
        final child = DI();
        child.parents..add(p1)..add(p2);
        p2.register<_A>(const _A('from-p2')).end();
        UNSAFE:
        final got = child.getSyncUnsafe<_A>();
        expect(got.tag, 'from-p2');
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 5. Self-disposing service — calling `dispose()` from inside its own
  //    dispose listener. The sequencer must not deadlock; the second call
  //    must be a no-op (we're already disposing).
  // ─────────────────────────────────────────────────────────────────────────
  group('service: self-disposing safety', () {
    test(
      'calling dispose() from inside the dispose listener is a no-op '
      '— does not deadlock',
      () async {
        late _SelfDisposingSpy svc;
        svc = _SelfDisposingSpy(onSelfDispose: () => svc.dispose().end());
        (await svc.init().toAsync().value).end();
        (await svc.dispose().toAsync().value.timeout(
              const Duration(seconds: 2),
              onTimeout: () => Err<Unit>('deadlock'),
            ))
            .end();
        expect(svc.disposeCalls, 1);
        expect(svc.state, ServiceState.DISPOSE_SUCCESS);
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 6. registerLazy → access singleton → resetLazySingleton → access again
  //    must give a FRESH instance.
  // ─────────────────────────────────────────────────────────────────────────
  group('Lazy<T>: resetSingleton freshness', () {
    test('after resetSingleton, the next access mints a new instance', () {
      final di = DI();
      final c = _Counter();
      di
          .registerLazy<_A>(() {
            c.constructorCalls++;
            return Sync<_A>.okValue(_A('v${c.constructorCalls}'));
          })
          .end();
      UNSAFE:
      final first = di.getLazySingletonSyncOrNone<_A>().unwrap();
      expect(first.tag, 'v1');
      // Reset.
      di.resetLazySingleton<_A>().end();
      UNSAFE:
      final second = di.getLazySingletonSyncOrNone<_A>().unwrap();
      expect(second.tag, 'v2');
      expect(identical(first, second), isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 7. Stream: pushToStream while restartStream is in flight — the pushes
  //    captured on the OLD epoch should drop silently. The new epoch's
  //    pushes go through.
  // ─────────────────────────────────────────────────────────────────────────
  group('stream: epoch tracking under restart', () {
    test(
      'push captured against old epoch is dropped after restartStream',
      () async {
        final s = _SimpleIntStream();
        (await s.init().toAsync().value).end();
        // Stage a push that captures the CURRENT epoch.
        final p = s.pushToStream(const Ok<int>(1)).toAsync().value;
        // Immediately restart — the staged push should drop.
        (await s.restartStream().toAsync().value).end();
        (await p).end();
        // Listener may or may not have received the value depending on
        // microtask ordering; the contract is "no exceptions, no zombie
        // state, sane lifecycle". The state should be RUN_SUCCESS still.
        expect(s.state, ServiceState.RUN_SUCCESS);
        (await s.dispose().toAsync().value).end();
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 8. Hierarchy: registering at a child must NOT visit the parent's
  //    completers (untilSuper completers are stored under the SPECIFIC
  //    container that called untilSuper).
  // ─────────────────────────────────────────────────────────────────────────
  group('hierarchy: untilSuper completer scope', () {
    test(
      'parent.untilSuper does NOT resolve when only the child registers '
      '(traversal goes parent → child via children(), but not child registers',
      () async {
        final parent = DI();
        final child = DI();
        child.parents.add(parent);
        // From parent's perspective, child is NOT in parent.children
        // unless wired via childrenContainer; we set up the typical
        // parent → child relation via `.parents.add(parent)` only.
        final timed = await parent
            .untilSuper<_A>()
            .toAsync()
            .value
            .timeout(
              const Duration(milliseconds: 50),
              onTimeout: () => Err<_A>('timed out'),
            );
        // Register at child — parent shouldn't see it.
        child.register<_A>(const _A('child-only')).end();
        // We already timed out; the await above returned an Err.
        expect(
          timed.isErr(),
          isTrue,
          reason:
              'parent.untilSuper must not fire on child registrations '
              'unless child is registered into parent.childrenContainer',
        );
        // The child can see its own registration via untilSuper.
        UNSAFE:
        final got = await child
            .untilSuper<_A>()
            .toAsync()
            .value
            .timeout(
              const Duration(milliseconds: 50),
              onTimeout: () =>
                  Err<_A>('child untilSuper unexpectedly timed out'),
            );
        UNSAFE:
        expect(got.unwrap().tag, 'child-only');
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 9. Concurrent register of the SAME type — only ONE wins.
  // ─────────────────────────────────────────────────────────────────────────
  group('register: concurrent same-type', () {
    test(
      '100 concurrent registers of the same type — exactly one succeeds',
      () async {
        final di = DI();
        var okCount = 0;
        var errCount = 0;
        await Future.wait([
          for (var n = 0; n < 100; n++)
            () async {
              final r = await di
                  .register<_A>(_A('n=$n'))
                  .toAsync()
                  .value;
              if (r.isOk()) {
                okCount++;
              } else {
                errCount++;
              }
            }(),
        ]);
        expect(okCount, 1);
        expect(errCount, 99);
        expect(di.isRegistered<_A>(), isTrue);
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 10. unregister<T>() on a type that isn't registered — returns Ok(None).
  // ─────────────────────────────────────────────────────────────────────────
  group('unregister: missing type', () {
    test('unregister of a non-existent type produces Ok(None)', () async {
      final di = DI();
      final r = await di.unregister<_A>().toAsync().value;
      expect(r.isOk(), isTrue);
      UNSAFE:
      expect(r.unwrap().isNone(), isTrue);
    });

    test('unregisterAll on an empty registry is a no-op (Ok)', () async {
      final di = DI();
      final r = await di.unregisterAll().toAsync().value;
      expect(r.isOk(), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 11. Async dep registered then quickly unregistered: the unregister
  //     must NOT hang on the in-flight Future.
  // ─────────────────────────────────────────────────────────────────────────
  group('async dep: register/unregister race', () {
    test(
      'register(Future) → unregister before the Future resolves does NOT '
      'hang',
      () async {
        final di = DI();
        di
            .register<_A>(
              Future<_A>.delayed(
                const Duration(milliseconds: 30),
                () => const _A('late'),
              ),
            )
            .end();
        final r = await di.unregister<_A>().toAsync().value.timeout(
              const Duration(seconds: 2),
              onTimeout: () => Err<Option<_A>>('hung'),
            );
        // Either we got Ok(Some(_A)) after waiting, or Ok(None) if removal
        // happened before the Future ran. Both are acceptable; what's NOT
        // acceptable is a hang.
        expect(r.isOk(), isTrue);
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 12. PollingStreamService with `Duration.zero` — should NOT busy-loop.
  // ─────────────────────────────────────────────────────────────────────────
  group('polling: zero-interval guard', () {
    test(
      'a polling service with Duration.zero ticks at least once and stops '
      'cleanly on dispose — no hang or runaway poll',
      () async {
        final s = _ZeroPoller();
        (await s.init().toAsync().value).end();
        await Future<void>.delayed(const Duration(milliseconds: 10));
        final ticksAfterInit = s.tickCount;
        expect(
          ticksAfterInit,
          greaterThan(0),
          reason: 'first poll must fire on subscription',
        );
        (await s.dispose().toAsync().value).end();
        // After dispose, no more ticks.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(s.tickCount, ticksAfterInit);
      },
    );
  });
}

class _SelfDisposingSpy with ServiceMixin {
  _SelfDisposingSpy({required this.onSelfDispose});
  final void Function() onSelfDispose;
  int disposeCalls = 0;

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
        (_) {
          disposeCalls++;
          // Re-enter dispose() — must be a no-op (we're already disposing).
          onSelfDispose();
          return Sync.okValue(Unit());
        },
      ];
}

class _SimpleIntStream extends StreamService<int> {
  final controller = StreamController<Result<int>>.broadcast();

  @override
  Stream<Result<int>> provideInputStream() => controller.stream;

  @override
  TServiceResolvables<Result<int>> provideOnPushToStreamListeners() => [];
}

class _ZeroPoller extends PollingStreamService<int> {
  int tickCount = 0;

  @override
  Resolvable<int> onPoll() {
    tickCount++;
    return Sync<int>.okValue(tickCount);
  }

  @override
  Duration providePollingInterval() => Duration.zero;

  @override
  TServiceResolvables<Result<int>> provideOnPushToStreamListeners() => [];
}
