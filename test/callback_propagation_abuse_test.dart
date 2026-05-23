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

// Callback error propagation tests. Mission-critical contracts:
//
//   • onRegister callback failures (sync throw, async throw, Sync.err
//     return, Async-resolving-to-Err) ALL surface as Err on register().
//   • onUnregister callback failures: sync throws and Sync.err returns are
//     LOGGED and the chain continues; async throws and Async-resolving-to-Err
//     propagate.
//   • `registerAndInitService` honors the user-supplied `onUnregister`
//     parameter — it must actually be called.
//   • `unregisterAll`'s before/after callbacks await Resolvable returns.

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

final class _A {
  const _A();
}

final class _LifecycleSpy with ServiceMixin {
  _LifecycleSpy();
  final events = <String>[];

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) {
          events.add('init');
          return Sync<Unit>.okValue(Unit());
        },
      ];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) =>
      [(_) => Sync<Unit>.okValue(Unit())];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) =>
      [(_) => Sync<Unit>.okValue(Unit())];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
        (_) {
          events.add('dispose');
          return Sync<Unit>.okValue(Unit());
        },
      ];
}

void main() {
  // ── onRegister failures ───────────────────────────────────────────────────
  group('onRegister: every failure mode surfaces as Err', () {
    test('sync throw → register Err', () async {
      final di = DI();
      final r = await di
          .register<_A>(
            const _A(),
            onRegister: Some((_) {
              throw StateError('boom');
            }),
          )
          .toAsync()
          .value;
      expect(r.isErr(), isTrue, reason: 'sync throw must produce Err');
    });

    test('async throw → register Err', () async {
      final di = DI();
      final r = await di
          .register<_A>(
            const _A(),
            onRegister: Some((_) async {
              throw StateError('async boom');
            }),
          )
          .toAsync()
          .value;
      expect(r.isErr(), isTrue, reason: 'async throw must produce Err');
    });

    test(
      'Sync.err Resolvable return → register Err',
      () async {
        final di = DI();
        final r = await di
            .register<_A>(
              const _A(),
              onRegister: Some(
                (_) => Sync<Unit>.err(Err('returning Sync.err')),
              ),
            )
            .toAsync()
            .value;
        expect(
          r.isErr(),
          isTrue,
          reason:
              'A callback explicitly returning Sync.err is a captured failure '
              '— it must NOT be silently dropped.',
        );
      },
    );

    test(
      'Async-resolving-to-Err Resolvable return → register Err',
      () async {
        final di = DI();
        final r = await di
            .register<_A>(
              const _A(),
              onRegister: Some(
                (_) => Async<Unit>(() async {
                  await Future<void>.delayed(const Duration(milliseconds: 5));
                  throw StateError('async-resolving-to-Err');
                }),
              ),
            )
            .toAsync()
            .value;
        expect(
          r.isErr(),
          isTrue,
          reason:
              'An Async callback that resolves to Err must surface that Err.',
        );
      },
    );
  });

  // ── onUnregister failures ─────────────────────────────────────────────────
  group('onUnregister: sync throws/errs are logged; async errors propagate',
      () {
    test('sync throw → logged, chain continues with Ok', () async {
      final di = DI();
      di
          .register<_A>(
            const _A(),
            onUnregister: Some((_) {
              throw StateError('sync throw');
            }),
          )
          .end();
      // unregister should NOT throw; the sync error is logged and swallowed.
      final r = await di.unregister<_A>().toAsync().value;
      expect(r.isOk(), isTrue);
    });

    test(
      'Sync.err Resolvable return → logged, chain continues with Ok',
      () async {
        final di = DI();
        di
            .register<_A>(
              const _A(),
              onUnregister: Some(
                (_) => Sync<Unit>.err(Err('sync-err return')),
              ),
            )
            .end();
        final r = await di.unregister<_A>().toAsync().value;
        expect(
          r.isOk(),
          isTrue,
          reason: 'A Sync.err return mirrors a sync throw — log and continue.',
        );
      },
    );

    test(
      'async throw → propagates as Err',
      () async {
        final di = DI();
        di
            .register<_A>(
              const _A(),
              onUnregister: Some((_) async {
                await Future<void>.delayed(const Duration(milliseconds: 5));
                throw StateError('async throw');
              }),
            )
            .end();
        final r = await di.unregister<_A>().toAsync().value;
        expect(r.isErr(), isTrue);
      },
    );

    test(
      'Async-resolving-to-Err Resolvable return → propagates as Err',
      () async {
        final di = DI();
        di
            .register<_A>(
              const _A(),
              onUnregister: Some(
                (_) => Async<Unit>(() async {
                  await Future<void>.delayed(const Duration(milliseconds: 5));
                  throw StateError('async-resolving-to-Err');
                }),
              ),
            )
            .end();
        final r = await di.unregister<_A>().toAsync().value;
        expect(r.isErr(), isTrue);
      },
    );
  });

  // ── registerAndInitService passes user onUnregister through ───────────────
  group('registerAndInitService honors the user-supplied onUnregister', () {
    test(
      'a user-supplied onUnregister callback is called on unregister',
      () async {
        final di = DI();
        final svc = _LifecycleSpy();
        var userCallbackRan = false;
        (await di
                .registerAndInitService<_LifecycleSpy>(
                  svc,
                  onUnregister: Some((_) {
                    userCallbackRan = true;
                  }),
                )
                .toAsync()
                .value)
            .end();
        (await di.unregister<_LifecycleSpy>().toAsync().value).end();
        expect(
          userCallbackRan,
          isTrue,
          reason:
              'registerAndInitService must invoke the user-supplied '
              'onUnregister — currently it is passed to consec without '
              'being called.',
        );
        // The service's own dispose still ran.
        expect(svc.events, equals(['init', 'dispose']));
      },
    );

    test(
      'the user-supplied onUnregister callback runs AFTER service.dispose() '
      'has completed',
      () async {
        final di = DI();
        final svc = _LifecycleSpy();
        var disposeStateAtCallback = ServiceState.NOT_INITIALIZED;
        (await di
                .registerAndInitService<_LifecycleSpy>(
                  svc,
                  onUnregister: Some((_) {
                    disposeStateAtCallback = svc.state;
                  }),
                )
                .toAsync()
                .value)
            .end();
        (await di.unregister<_LifecycleSpy>().toAsync().value).end();
        expect(
          disposeStateAtCallback,
          ServiceState.DISPOSE_SUCCESS,
          reason:
              'When the user-supplied onUnregister runs, the service should '
              'already be fully disposed.',
        );
      },
    );
  });

  // ── unregisterAll awaits Resolvable callback returns ──────────────────────
  group('unregisterAll awaits Resolvable callback returns', () {
    test(
      'onBeforeUnregister returning Async actually awaits it',
      () async {
        final di = DI();
        di.register<_A>(const _A()).end();
        var beforeFinished = false;
        (await di
                .unregisterAll(
                  onBeforeUnregister: Some((_) => Async<Unit>(() async {
                        await Future<void>.delayed(
                          const Duration(milliseconds: 10),
                        );
                        beforeFinished = true;
                        return Unit();
                      }),),
                )
                .toAsync()
                .value)
            .end();
        expect(
          beforeFinished,
          isTrue,
          reason:
              'unregisterAll must await onBeforeUnregister Resolvable returns',
        );
        expect(di.isRegistered<_A>(), isFalse);
      },
    );

    test(
      'onAfterUnregister returning Async actually awaits it',
      () async {
        final di = DI();
        di.register<_A>(const _A()).end();
        var afterFinished = false;
        (await di
                .unregisterAll(
                  onAfterUnregister: Some((_) => Async<Unit>(() async {
                        await Future<void>.delayed(
                          const Duration(milliseconds: 10),
                        );
                        afterFinished = true;
                        return Unit();
                      }),),
                )
                .toAsync()
                .value)
            .end();
        expect(
          afterFinished,
          isTrue,
          reason:
              'unregisterAll must await onAfterUnregister Resolvable returns',
        );
      },
    );

    test(
      'per-dep onUnregister returning Async during unregisterAll is awaited',
      () async {
        final di = DI();
        var unregisterFinished = false;
        di
            .register<_A>(
              const _A(),
              onUnregister: Some((_) => Async<Unit>(() async {
                    await Future<void>.delayed(
                      const Duration(milliseconds: 10),
                    );
                    unregisterFinished = true;
                    return Unit();
                  }),),
            )
            .end();
        (await di.unregisterAll().toAsync().value).end();
        expect(
          unregisterFinished,
          isTrue,
          reason:
              "unregisterAll must await the dep's own onUnregister "
              'Resolvable return',
        );
      },
    );
  });
}
