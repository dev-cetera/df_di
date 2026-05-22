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

// Tests for StreamServiceMixin: ordering across emissions, restartStream
// epoch race, init/pause/resume/dispose stream-lifecycle wiring.

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

/// A test stream service driven by a manually-fed [StreamController].
final class TestStreamService extends StreamService<int> {
  TestStreamService();

  final StreamController<Result<int>> _input =
      StreamController<Result<int>>.broadcast();
  final List<int> received = [];

  void emit(int value) => _input.add(Ok(value));
  void emitError(Object error) => _input.add(Err(error));

  @override
  Stream<Result<int>> provideInputStream() => _input.stream;

  @override
  TServiceResolvables<Result<int>> provideOnPushToStreamListeners() {
    return [
      (data) {
        if (data.isOk()) {
          UNSAFE:
          received.add(data.unwrap());
        }
        return syncUnit();
      },
    ];
  }

  Future<void> closeInput() => _input.close();
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('StreamServiceMixin: lifecycle wiring', () {
    test('init starts the stream; stream getter returns a broadcast stream',
        () async {
      final s = TestStreamService();
      (await s.init().value).end();
      expect(s.state, ServiceState.RUN_SUCCESS);
      expect(s.stream.isSome(), isTrue);
      (await s.dispose().value).end();
    });

    test('emitted events flow to pushToStream listeners', () async {
      final s = TestStreamService();
      (await s.init().value).end();
      s.emit(1);
      s.emit(2);
      s.emit(3);
      // Allow stream events to propagate.
      await Future<void>.delayed(Duration.zero);
      expect(s.received, [1, 2, 3]);
      (await s.dispose().value).end();
    });

    test('pause stops events from reaching the broadcast controller', () async {
      final s = TestStreamService();
      (await s.init().value).end();
      (await s.pause().value).end();
      expect(s.state, ServiceState.PAUSE_SUCCESS);

      s.emit(1);
      s.emit(2);
      await Future<void>.delayed(Duration.zero);
      // While paused, listener should not see events.
      expect(s.received, isEmpty);

      (await s.resume().value).end();
      expect(s.state, ServiceState.RESUME_SUCCESS);
      // Buffered events are delivered after resume.
      await Future<void>.delayed(Duration.zero);
      expect(s.received, [1, 2]);

      (await s.dispose().value).end();
    });

    test('dispose stops the stream and closes the controller', () async {
      final s = TestStreamService();
      (await s.init().value).end();
      (await s.dispose().value).end();
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
      // After dispose, the broadcast controller is cleared.
      expect(s.stream.isNone(), isTrue);
    });
  });

  group('StreamServiceMixin: emission ordering', () {
    test('pushToStream listeners observe emissions in arrival order', () async {
      final s = TestStreamService();
      (await s.init().value).end();
      for (var i = 0; i < 50; i++) {
        s.emit(i);
      }
      // Drain the stream.
      await Future<void>.delayed(Duration.zero);
      // Single per-service sequencer ensures monotonic ordering.
      expect(s.received, List.generate(50, (i) => i));
      (await s.dispose().value).end();
    });
  });

  group('StreamServiceMixin: restartStream', () {
    test('restartStream is safe to call repeatedly', () async {
      final s = TestStreamService();
      (await s.init().value).end();
      (await s.restartStream().value).end();
      (await s.restartStream().value).end();
      (await s.restartStream().value).end();
      expect(s.stream.isSome(), isTrue);
      s.emit(42);
      await Future<void>.delayed(Duration.zero);
      expect(s.received, [42]);
      (await s.dispose().value).end();
    });

    test('events arriving on the new stream after restart flow through',
        () async {
      final s = TestStreamService();
      (await s.init().value).end();
      s.emit(1);
      await Future<void>.delayed(Duration.zero);
      (await s.restartStream().value).end();
      s.emit(2);
      await Future<void>.delayed(Duration.zero);
      // Both pre- and post-restart events flow into the listener (pData-style
      // pushToStream listeners are independent of the broadcast controller).
      expect(s.received, [1, 2]);
      (await s.dispose().value).end();
    });
  });

  group('StreamServiceMixin: error handling', () {
    test('emitError on the input stream does not crash pushToStream', () async {
      final s = TestStreamService();
      (await s.init().value).end();
      s.emitError('boom');
      s.emit(1);
      await Future<void>.delayed(Duration.zero);
      // Successful events still flow.
      expect(s.received, [1]);
      (await s.dispose().value).end();
    });
  });

  group('StreamServiceMixin: DI integration', () {
    test('full lifecycle via DI register/unregister', () async {
      final di = DI();
      final s = TestStreamService();
      di
          .register<TestStreamService>(
            s,
            onRegister: Some((svc) => svc.init()),
            onUnregister: const Some(ServiceMixin.unregister),
          )
          .end();

      UNSAFE:
      final retrieved = await di.untilSuper<TestStreamService>().unwrap();
      expect(identical(retrieved, s), isTrue);
      expect(s.state, ServiceState.RUN_SUCCESS);

      s.emit(100);
      await Future<void>.delayed(Duration.zero);
      expect(s.received, [100]);

      (await di.unregister<TestStreamService>().value).end();
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
    });
  });
}
