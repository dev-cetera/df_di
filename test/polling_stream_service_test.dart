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

// Tests for PollingStreamServiceMixin: the polling timer must respect
// service lifecycle (start on init, stop on pause/dispose, restart on resume).

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

/// A test polling service that increments a counter on each poll.
final class TestPollingService extends PollingStreamService<int> {
  TestPollingService({this.interval = const Duration(milliseconds: 20)});

  final Duration interval;
  int pollCount = 0;
  final List<int> received = [];

  @override
  Resolvable<int> onPoll() {
    pollCount++;
    return Sync.okValue(pollCount);
  }

  @override
  Duration providePollingInterval() => interval;

  @override
  TServiceResolvables<Result<int>> provideOnPushToStreamListeners() {
    return [
      (data) {
        UNSAFE:
        if (data.isOk()) received.add(data.unwrap());
        return syncUnit();
      },
    ];
  }
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('PollingStreamServiceMixin: timer lifecycle', () {
    test('init starts polling and fires immediately', () async {
      final s = TestPollingService();
      (await s.init().value).end();
      // First poll fires synchronously on onListen → startTimer.
      expect(s.pollCount, greaterThanOrEqualTo(1));
      // Let several intervals elapse.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(s.pollCount, greaterThan(1));
      (await s.dispose().value).end();
    });

    test('pause stops the polling timer', () async {
      final s = TestPollingService();
      (await s.init().value).end();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      final beforePause = s.pollCount;
      expect(beforePause, greaterThan(0));

      (await s.pause().value).end();
      expect(s.state, ServiceState.PAUSE_SUCCESS);
      // Wait longer than the polling interval — count must NOT grow.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(
        s.pollCount,
        beforePause,
        reason: 'polling timer must stop when service is paused',
      );

      (await s.dispose().value).end();
    });

    test('resume restarts the polling timer', () async {
      final s = TestPollingService();
      (await s.init().value).end();
      (await s.pause().value).end();
      final beforeResume = s.pollCount;

      (await s.resume().value).end();
      expect(s.state, ServiceState.RESUME_SUCCESS);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(
        s.pollCount,
        greaterThan(beforeResume),
        reason: 'polling timer must resume when service resumes',
      );

      (await s.dispose().value).end();
    });

    test('dispose stops the polling timer permanently', () async {
      final s = TestPollingService();
      (await s.init().value).end();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      final beforeDispose = s.pollCount;

      (await s.dispose().value).end();
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
      // Wait longer than the polling interval — count must NOT grow.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(
        s.pollCount,
        beforeDispose,
        reason: 'polling timer must stop on dispose',
      );
    });
  });

  group('PollingStreamServiceMixin: data flow', () {
    test('polled values reach pushToStream listeners', () async {
      final s = TestPollingService();
      (await s.init().value).end();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(s.received, isNotEmpty);
      // Received values must be monotonically increasing.
      for (var i = 1; i < s.received.length; i++) {
        expect(s.received[i], greaterThan(s.received[i - 1]));
      }
      (await s.dispose().value).end();
    });
  });

  group('PollingStreamServiceMixin: DI integration', () {
    test('full lifecycle via DI register/unregister', () async {
      final di = DI();
      final s = TestPollingService();
      di
          .register<TestPollingService>(
            s,
            onRegister: Some((svc) => svc.init()),
            onUnregister: const Some(ServiceMixin.unregister),
          )
          .end();

      UNSAFE:
      final retrieved = await di.untilSuper<TestPollingService>().unwrap();
      expect(identical(retrieved, s), isTrue);
      expect(s.state, ServiceState.RUN_SUCCESS);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(s.pollCount, greaterThan(0));

      (await di.unregister<TestPollingService>().value).end();
      expect(s.state, ServiceState.DISPOSE_SUCCESS);

      // After dispose, polling must not continue.
      final finalCount = s.pollCount;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(s.pollCount, finalCount);
    });
  });
}
