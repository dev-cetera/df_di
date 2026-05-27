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

// Unit tests for `lib/src/services/polling_stream_service.dart`.
//
// Exercises the `PollingStreamService` convenience base + the
// `PollingStreamServiceMixin` timer-driven input stream: producer invoked
// periodically, values reach pushToStream listeners, pause stops polling,
// resume restarts polling, dispose cancels the timer permanently, and
// producer errors (Err / throw) propagate as `Err` results without crashing
// the service.

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

/// A polling service that increments a counter on each poll.
final class _CounterPoller extends PollingStreamService<int> {
  _CounterPoller();

  int pollCount = 0;
  final List<int> received = [];

  @override
  Resolvable<int> onPoll() {
    pollCount++;
    return Sync.okValue(pollCount);
  }

  @override
  Duration providePollingInterval() => const Duration(milliseconds: 10);

  @override
  TServiceResolvables<Result<int>> provideOnPushToStreamListeners() => [
        (data) {
          if (data case Ok(value: final v)) received.add(v);
          return syncUnit();
        },
      ];
}

/// A polling service whose producer returns `Sync.err` to verify Err
/// propagation through the polling timer + broadcast pipeline.
final class _FailingPoller extends PollingStreamService<int> {
  _FailingPoller();
  int pollCount = 0;
  final List<Object> errors = [];
  final List<int> received = [];

  @override
  Resolvable<int> onPoll() {
    pollCount++;
    return Sync.err(Err('poll #$pollCount failed'));
  }

  @override
  Duration providePollingInterval() => const Duration(milliseconds: 10);

  @override
  TServiceResolvables<Result<int>> provideOnPushToStreamListeners() => [
        (data) {
          switch (data) {
            case Ok(value: final v):
              received.add(v);
            case Err(:final error):
              errors.add(error);
          }
          return syncUnit();
        },
      ];
}

/// A polling service whose producer throws synchronously inside an `Async`
/// — verifies the throw is captured into an Err and does not crash the
/// service or terminate polling.
final class _ThrowingPoller extends PollingStreamService<int> {
  _ThrowingPoller();
  int pollCount = 0;
  final List<Object> errors = [];

  @override
  Resolvable<int> onPoll() {
    pollCount++;
    return Async<int>(() async {
      throw StateError('poll #$pollCount blew up');
    });
  }

  @override
  Duration providePollingInterval() => const Duration(milliseconds: 10);

  @override
  TServiceResolvables<Result<int>> provideOnPushToStreamListeners() => [
        (data) {
          if (data case Err(:final error)) errors.add(error);
          return syncUnit();
        },
      ];
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('PollingStreamService: construction', () {
    test('before init, polling is not running', () {
      final s = _CounterPoller();
      expect(s.pollCount, 0);
      expect(s.state, ServiceState.NOT_INITIALIZED);
    });
  });

  group('PollingStreamService: after init', () {
    test('producer is invoked immediately and then periodically', () async {
      final s = _CounterPoller();
      (await s.init().value).end();
      // First poll fires synchronously on subscription.
      expect(s.pollCount, greaterThanOrEqualTo(1));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(
        s.pollCount,
        greaterThan(1),
        reason: 'periodic timer must produce more than one poll',
      );
      (await s.dispose().value).end();
    });

    test('polled values reach pushToStream listeners monotonically', () async {
      final s = _CounterPoller();
      (await s.init().value).end();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(s.received, isNotEmpty);
      for (var i = 1; i < s.received.length; i++) {
        expect(s.received[i], greaterThan(s.received[i - 1]));
      }
      (await s.dispose().value).end();
    });
  });

  group('PollingStreamService: pause/resume', () {
    test('pause halts polling; resume restarts polling', () async {
      final s = _CounterPoller();
      (await s.init().value).end();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(s.pollCount, greaterThan(0));

      (await s.pause().value).end();
      expect(s.state, ServiceState.PAUSE_SUCCESS);
      final beforePause = s.pollCount;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(
        s.pollCount,
        beforePause,
        reason: 'polling must not advance while paused',
      );

      (await s.resume().value).end();
      expect(s.state, ServiceState.RESUME_SUCCESS);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(
        s.pollCount,
        greaterThan(beforePause),
        reason: 'polling must resume after resume()',
      );

      (await s.dispose().value).end();
    });
  });

  group('PollingStreamService: dispose', () {
    test('dispose cancels the timer permanently', () async {
      final s = _CounterPoller();
      (await s.init().value).end();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      final pre = s.pollCount;
      expect(pre, greaterThan(0));

      (await s.dispose().value).end();
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(
        s.pollCount,
        pre,
        reason: 'timer must be cancelled and never fire after dispose',
      );
    });
  });

  group('PollingStreamService: producer errors propagate', () {
    test(
        'Sync.err from onPoll propagates as Err to listeners; service stays up',
        () async {
      final s = _FailingPoller();
      (await s.init().value).end();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(s.state, ServiceState.RUN_SUCCESS);
      expect(s.errors, isNotEmpty);
      expect(s.received, isEmpty);
      // Polling continues despite Err on every tick.
      expect(s.pollCount, greaterThan(1));
      (await s.dispose().value).end();
    });

    test('Async-throw from onPoll surfaces as Err without killing the service',
        () async {
      final s = _ThrowingPoller();
      (await s.init().value).end();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(s.state, ServiceState.RUN_SUCCESS);
      expect(s.errors, isNotEmpty);
      // Polling still fires repeatedly.
      expect(s.pollCount, greaterThan(1));
      (await s.dispose().value).end();
    });
  });

  group('PollingStreamService: lifecycle routes through TaskSequencer', () {
    test('concurrent pause+resume serialise without losing state', () async {
      final s = _CounterPoller();
      (await s.init().value).end();
      final p = s.pause().value;
      final r = s.resume().value;
      (await p).end();
      (await r).end();
      // Final settled state is RESUME_SUCCESS (last in the sequencer chain).
      expect(s.state, ServiceState.RESUME_SUCCESS);
      (await s.dispose().value).end();
    });
  });
}
