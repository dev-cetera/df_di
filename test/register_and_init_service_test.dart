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

// Tests for `registerAndInitService` — the high-level entry point that
// registers a Service in DI, runs init() on register, and runs dispose() on
// unregister. This is the canonical user-facing API for service lifecycles.

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

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('registerAndInitService', () {
    test('runs init() automatically and reaches RUN_SUCCESS', () async {
      final di = DI();
      final s = TestService();

      (await di.registerAndInitService<TestService>(s).toAsync().value).end();

      expect(s.events, ['init']);
      expect(s.state, ServiceState.RUN_SUCCESS);
      expect(di.isRegistered<TestService>(), isTrue);
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

    test('the registered service is the same instance retrieved later',
        () async {
      final di = DI();
      final s = TestService();
      (await di.registerAndInitService<TestService>(s).toAsync().value).end();

      UNSAFE:
      final retrieved = di.getSyncUnsafe<TestService>();
      expect(identical(retrieved, s), isTrue);
    });
  });
}
