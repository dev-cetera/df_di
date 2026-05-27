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

// Tests targeted at `SupportsServiceMixin`: `registerAndInitService` drives
// the full service lifecycle automatically — init on register, dispose on
// unregister — and routes user-supplied callbacks in the right order.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

final class TestService extends Service {
  TestService();

  final List<String> events = [];

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) {
          events.add('init');
          return syncUnit();
        },
      ];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) => [
        (_) {
          events.add('pause');
          return syncUnit();
        },
      ];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) => [
        (_) {
          events.add('resume');
          return syncUnit();
        },
      ];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
        (_) {
          events.add('dispose');
          return syncUnit();
        },
      ];
}

final class _FailingInitService extends Service {
  _FailingInitService();

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) =>
      [(_) => Sync.err(Err('init failed'))];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) =>
      [(_) => syncUnit()];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) =>
      [(_) => syncUnit()];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) =>
      [(_) => syncUnit()];
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('registerAndInitService — happy path', () {
    test('runs init() automatically and reaches RUN_SUCCESS', () async {
      final di = DI();
      final s = TestService();

      (await di.registerAndInitService<TestService>(s).toAsync().value).end();

      expect(s.events, ['init']);
      expect(s.state, ServiceState.RUN_SUCCESS);
      expect(di.isRegistered<TestService>(), isTrue);
    });

    test('the registered service is retrievable as the same instance', () async {
      final di = DI();
      final s = TestService();
      (await di.registerAndInitService<TestService>(s).toAsync().value).end();

      UNSAFE:
      final retrieved = di.getSyncUnsafe<TestService>();
      expect(identical(retrieved, s), isTrue);
    });

    test('unregister runs dispose() automatically', () async {
      final di = DI();
      final s = TestService();
      (await di.registerAndInitService<TestService>(s).toAsync().value).end();

      (await di.unregister<TestService>().toAsync().value).end();

      expect(s.events, ['init', 'dispose']);
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
      expect(di.isRegistered<TestService>(), isFalse);
    });
  });

  group('registerAndInitService — onRegister / onUnregister', () {
    test('onRegister fires after init() and sees a fully-initialised service',
        () async {
      final di = DI();
      final s = TestService();
      String? observedState;

      (await di
              .registerAndInitService<TestService>(
                s,
                onRegister: Some((svc) {
                  observedState = svc.state.toString();
                  return null;
                }),
              )
              .toAsync()
              .value)
          .end();

      // The user's onRegister observed the service AFTER init ran.
      expect(s.events, ['init']);
      expect(observedState, equals(ServiceState.RUN_SUCCESS.toString()));
    });

    test('onUnregister fires after dispose()', () async {
      final di = DI();
      final s = TestService();
      Result<TestService>? observedResult;

      (await di
              .registerAndInitService<TestService>(
                s,
                onUnregister: Some((r) {
                  observedResult = r;
                  return null;
                }),
              )
              .toAsync()
              .value)
          .end();

      (await di.unregister<TestService>().toAsync().value).end();

      expect(s.events, ['init', 'dispose']);
      expect(observedResult, isNotNull);
      expect(observedResult!.isOk(), isTrue);
    });
  });

  group('registerAndInitService — error path', () {
    test('init failure surfaces on the returned Resolvable', () async {
      final di = DI();
      final s = _FailingInitService();
      final r = await di
          .registerAndInitService<_FailingInitService>(s)
          .toAsync()
          .value;
      // The chain bubbles the init failure up.
      expect(r.isErr(), isTrue);
    });
  });

  group('registerAndInitService — enableUntilExactlyK', () {
    test(
      'a waiter via untilExactlyK fires when the service is registered',
      () async {
        final di = DI();
        final s = TestService();
        final waiter =
            di.untilExactlyK<TestService>(TypeEntity(TestService)).toAsync().value;

        (await di
                .registerAndInitService<TestService>(
                  s,
                  enableUntilExactlyK: true,
                )
                .toAsync()
                .value)
            .end();

        UNSAFE:
        final observed = (await waiter).unwrap();
        expect(identical(observed, s), isTrue);
      },
    );
  });

  group('registerAndInitService — groupEntity', () {
    test('respects the groupEntity for isolation', () async {
      final di = DI();
      final s1 = TestService();
      final s2 = TestService();
      final groupA = TypeEntity('serviceA');
      final groupB = TypeEntity('serviceB');

      (await di
              .registerAndInitService<TestService>(s1, groupEntity: groupA)
              .toAsync()
              .value)
          .end();
      (await di
              .registerAndInitService<TestService>(s2, groupEntity: groupB)
              .toAsync()
              .value)
          .end();

      expect(di.isRegistered<TestService>(groupEntity: groupA), isTrue);
      expect(di.isRegistered<TestService>(groupEntity: groupB), isTrue);

      UNSAFE:
      expect(
        identical(di.getSyncUnsafe<TestService>(groupEntity: groupA), s1),
        isTrue,
      );
      UNSAFE:
      expect(
        identical(di.getSyncUnsafe<TestService>(groupEntity: groupB), s2),
        isTrue,
      );
    });
  });
}
