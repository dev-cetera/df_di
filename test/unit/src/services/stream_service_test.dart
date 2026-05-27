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

// Unit tests for `lib/src/services/stream_service.dart`.
//
// Exercises the `StreamService` convenience base class plus the
// `StreamServiceMixin` wiring: broadcast `stream` getter, pushToStream
// fan-out, broadcast semantics for late subscribers, lifecycle wiring
// (init/pause/resume/dispose) routed through TaskSequencer, multi-subscriber
// fan-out, subscription cancellation, restartStream epoch handling, and
// the post-dispose drop contract.

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

/// A stream service backed by a manually-fed broadcast controller so tests
/// can drive emissions deterministically.
final class _IntStreamService extends StreamService<int> {
  _IntStreamService();

  final StreamController<Result<int>> _input =
      StreamController<Result<int>>.broadcast();
  final List<int> received = [];

  void emit(int value) => _input.add(Ok(value));

  @override
  Stream<Result<int>> provideInputStream() => _input.stream;

  @override
  TServiceResolvables<Result<int>> provideOnPushToStreamListeners() => [
        (data) {
          if (data case Ok(value: final v)) {
            received.add(v);
          }
          return syncUnit();
        },
      ];
}

/// Bare mixin variant — proves `StreamServiceMixin` can be applied directly
/// on top of `ServiceMixin` without the `StreamService` convenience base.
final class _BareStream with ServiceMixin, StreamServiceMixin<int> {
  final StreamController<Result<int>> _input =
      StreamController<Result<int>>.broadcast();
  final List<int> received = [];

  void emit(int value) => _input.add(Ok(value));

  @override
  Stream<Result<int>> provideInputStream() => _input.stream;

  @override
  TServiceResolvables<Result<int>> provideOnPushToStreamListeners() => [
        (data) {
          if (data case Ok(value: final v)) {
            received.add(v);
          }
          return syncUnit();
        },
      ];
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('StreamService: construction', () {
    test('before init, stream getter is None', () {
      final s = _IntStreamService();
      expect(s.stream.isNone(), isTrue);
      expect(s.state, ServiceState.NOT_INITIALIZED);
    });

    test('bare ServiceMixin + StreamServiceMixin works without Service base',
        () async {
      final s = _BareStream();
      expect(s.stream.isNone(), isTrue);
      (await s.init().value).end();
      expect(s.state, ServiceState.RUN_SUCCESS);
      expect(s.stream.isSome(), isTrue);
      s.emit(7);
      await Future<void>.delayed(Duration.zero);
      expect(s.received, [7]);
      (await s.dispose().value).end();
    });
  });

  group('StreamService: after init', () {
    test('stream is exposed and subscribable', () async {
      final s = _IntStreamService();
      (await s.init().value).end();
      expect(s.stream.isSome(), isTrue);
      expect(s.state, ServiceState.RUN_SUCCESS);

      // Confirm the broadcast stream itself is subscribable.
      final stream = switch (s.stream) {
        Some(value: final st) => st,
        None() => fail('expected stream after init'),
      };
      final got = <int>[];
      final sub = stream.listen((r) {
        if (r case Ok(value: final v)) got.add(v);
      });
      s.emit(1);
      s.emit(2);
      await Future<void>.delayed(Duration.zero);
      expect(got, [1, 2]);
      await sub.cancel();
      (await s.dispose().value).end();
    });

    test('pushToStream fans out to every subscriber', () async {
      final s = _IntStreamService();
      (await s.init().value).end();
      final stream = switch (s.stream) {
        Some(value: final st) => st,
        None() => fail('expected stream after init'),
      };

      final a = Completer<int>();
      final b = Completer<int>();
      final subA = stream.listen((r) {
        if (r case Ok(value: final v) when !a.isCompleted) a.complete(v);
      });
      final subB = stream.listen((r) {
        if (r case Ok(value: final v) when !b.isCompleted) b.complete(v);
      });

      s.emit(42);
      expect(await a.future, 42);
      expect(await b.future, 42);
      await subA.cancel();
      await subB.cancel();
      (await s.dispose().value).end();
    });

    test('subscription cancellation stops further deliveries', () async {
      final s = _IntStreamService();
      (await s.init().value).end();
      final stream = switch (s.stream) {
        Some(value: final st) => st,
        None() => fail('expected stream after init'),
      };
      final got = <int>[];
      final sub = stream.listen((r) {
        if (r case Ok(value: final v)) got.add(v);
      });
      s.emit(1);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      s.emit(2);
      s.emit(3);
      await Future<void>.delayed(Duration.zero);
      expect(got, [1]);
      // Internal listener still records emissions.
      expect(s.received, [1, 2, 3]);
      (await s.dispose().value).end();
    });

    test('late subscribers do NOT receive historical events (broadcast)',
        () async {
      final s = _IntStreamService();
      (await s.init().value).end();
      s.emit(1);
      s.emit(2);
      await Future<void>.delayed(Duration.zero);

      final stream = switch (s.stream) {
        Some(value: final st) => st,
        None() => fail('expected stream after init'),
      };
      final late = <int>[];
      final sub = stream.listen((r) {
        if (r case Ok(value: final v)) late.add(v);
      });
      // No historical replay on broadcast streams.
      await Future<void>.delayed(Duration.zero);
      expect(late, isEmpty);

      s.emit(3);
      await Future<void>.delayed(Duration.zero);
      expect(late, [3]);
      await sub.cancel();
      (await s.dispose().value).end();
    });
  });

  group('StreamService: lifecycle wiring through TaskSequencer', () {
    test('pause halts internal listener; resume restarts delivery', () async {
      final s = _IntStreamService();
      (await s.init().value).end();
      (await s.pause().value).end();
      expect(s.state, ServiceState.PAUSE_SUCCESS);

      s.emit(1);
      s.emit(2);
      await Future<void>.delayed(Duration.zero);
      expect(s.received, isEmpty);

      (await s.resume().value).end();
      expect(s.state, ServiceState.RESUME_SUCCESS);
      await Future<void>.delayed(Duration.zero);
      expect(s.received, [1, 2]);

      (await s.dispose().value).end();
    });

    test('concurrent init+dispose serialise via TaskSequencer', () async {
      final s = _IntStreamService();
      // Fire both without intermediate await.
      final initFut = s.init().value;
      final disposeFut = s.dispose().value;
      try {
        (await initFut).end();
      } on Object {/* ok */}
      try {
        (await disposeFut).end();
      } on Object {/* ok */}
      // Whatever the resolution, the service must end in a disposed state
      // (init then dispose was the requested sequence).
      expect(s.state.didDispose(), isTrue);
    });
  });

  group('StreamService: after dispose', () {
    test('stream is closed; getter returns None', () async {
      final s = _IntStreamService();
      (await s.init().value).end();
      final stream = switch (s.stream) {
        Some(value: final st) => st,
        None() => fail('expected stream after init'),
      };
      final done = Completer<void>();
      final sub = stream.listen(
        (_) {},
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
      );

      (await s.dispose().value).end();
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
      // Subscribers receive onDone when the controller closes.
      await done.future.timeout(const Duration(seconds: 1));
      await sub.cancel();
      expect(s.stream.isNone(), isTrue);
    });

    test('emit after dispose is a silent no-op (drop)', () async {
      final s = _IntStreamService();
      (await s.init().value).end();
      (await s.dispose().value).end();

      // Drive `pushToStream` directly; the service must drop on disposed.
      try {
        (await s.pushToStream(const Ok(99)).value).end();
      } on Object {
        // Drop may signal via Err / assertion in debug — acceptable contract.
      }
      // The defining contract: no emission reaches the internal listener.
      expect(s.received, isEmpty);
    });
  });
}
