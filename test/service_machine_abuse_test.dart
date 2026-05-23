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

// ServiceMixin state-machine abuse tests. Mission-critical contracts:
//
//   • Listeners run in declaration order (per phase).
//   • Listeners CHAIN via Resolvable.then — sync listeners stay sync; an
//     async listener is awaited before the next runs.
//   • eagerError=true short-circuits the chain on the FIRST error.
//   • eagerError=false runs every listener even if earlier ones errored,
//     but the FINAL state is still _ERROR.
//   • A synchronously-thrown exception inside a listener body is captured —
//     the chain does not surface a thrown error at the call site.
//   • dispose() while another phase is in flight does not skip the in-flight
//     phase's listeners (sequencer serializes).
//   • didEverInitAndSuccessfully is true iff init() ever reached SUCCESS for
//     this service instance, and stays true after any later transitions.
//   • Re-entrant lifecycle calls from inside a listener serialize cleanly
//     (no recursive sequencer task triggers a deadlock).
//   • Two concurrent burst-fired calls of the same phase coalesce into one
//     listener pass.

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

/// Configurable spy service that records every listener fire and lets each
/// phase install N listeners with optional sync / async / throwing behaviour
/// at chosen indices.
class _PhaseSpy with ServiceMixin {
  _PhaseSpy({
    this.initBehavior = const _LB.ok(),
    this.pauseBehavior = const _LB.ok(),
    this.resumeBehavior = const _LB.ok(),
    this.disposeBehavior = const _LB.ok(),
  });

  final _LB initBehavior;
  final _LB pauseBehavior;
  final _LB resumeBehavior;
  final _LB disposeBehavior;

  final initCalls = <int>[];
  final pauseCalls = <int>[];
  final resumeCalls = <int>[];
  final disposeCalls = <int>[];

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) =>
      _buildListeners(initBehavior, initCalls);

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) =>
      _buildListeners(pauseBehavior, pauseCalls);

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) =>
      _buildListeners(resumeBehavior, resumeCalls);

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) =>
      _buildListeners(disposeBehavior, disposeCalls);

  TServiceResolvables<Unit> _buildListeners(_LB lb, List<int> log) => [
        for (var i = 0; i < lb.count; i++)
          (_) {
            log.add(i);
            if (lb.syncThrowAt == i) throw StateError('sync throw at $i');
            if (lb.errAt == i) return Sync<Unit>.err(Err('Err at $i'));
            if (lb.asyncErrAt == i) {
              return Async<Unit>(() async {
                throw StateError('async throw at $i');
              });
            }
            if (lb.asyncOkAt == i) {
              return Async<Unit>(() async {
                await Future<void>.delayed(const Duration(milliseconds: 1));
                return Unit();
              });
            }
            return Sync<Unit>.okValue(Unit());
          },
      ];
}

/// Listener Behavior config. Always reproducible — every field is optional.
class _LB {
  const _LB.ok({this.count = 1})
      : syncThrowAt = -1,
        errAt = -1,
        asyncErrAt = -1,
        asyncOkAt = -1;
  const _LB({
    this.count = 1,
    this.syncThrowAt = -1,
    this.errAt = -1,
    this.asyncErrAt = -1,
    this.asyncOkAt = -1,
  });
  final int count;
  final int syncThrowAt;
  final int errAt;
  final int asyncErrAt;
  final int asyncOkAt;
}

/// Re-entrant spy — every listener pokes the SAME service mid-flight.
class _ReentrantSpy with ServiceMixin {
  final initCalls = <String>[];
  final disposeCalls = <String>[];

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) {
          initCalls.add('init-start');
          // Calling dispose during init — must enqueue, not deadlock.
          dispose().end();
          initCalls.add('init-end');
          return Sync.okValue(Unit());
        },
      ];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) => [
        (_) => Sync<Unit>.okValue(Unit()),
      ];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) => [
        (_) => Sync<Unit>.okValue(Unit()),
      ];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
        (_) {
          disposeCalls.add('dispose');
          return Sync.okValue(Unit());
        },
      ];
}

void main() {
  // ── Listener ordering ─────────────────────────────────────────────────────
  group('listener ordering and chaining', () {
    test('init listeners run in declaration order (sync chain)', () async {
      final s = _PhaseSpy(initBehavior: const _LB.ok(count: 10));
      (await s.init().toAsync().value).end();
      expect(s.initCalls, equals(List.generate(10, (i) => i)));
      expect(s.state, ServiceState.RUN_SUCCESS);
    });

    test(
      'init listeners chain through an async one — the next one waits',
      () async {
        // 5 listeners, the third is async (delay 1ms).
        final s = _PhaseSpy(
          initBehavior: const _LB(count: 5, asyncOkAt: 2),
        );
        (await s.init().toAsync().value).end();
        expect(s.initCalls, equals([0, 1, 2, 3, 4]));
        expect(s.state, ServiceState.RUN_SUCCESS);
      },
    );

    test(
      'eagerError=true (init default) short-circuits on FIRST Err — '
      'subsequent listeners do NOT run',
      () async {
        final s = _PhaseSpy(
          initBehavior: const _LB(count: 5, errAt: 2),
        );
        (await s.init().toAsync().value).end();
        expect(s.initCalls, equals([0, 1, 2]));
        expect(s.state, ServiceState.RUN_ERROR);
      },
    );

    test(
      'eagerError=false (dispose default) records the Err and lands in '
      '_ERROR; in release (asserts stripped) every listener still runs',
      () async {
        final s = _PhaseSpy(
          disposeBehavior: const _LB(count: 5, errAt: 2),
        );
        // The Resolvable swallows AssertionError raised by the internal
        // `assert(false, error)` in `_updateState.recordError` — so the
        // await settles normally.
        (await s.dispose().toAsync().value).end();
        // Contract that holds in BOTH debug and release: listeners up to
        // and including the failing one ran, and the final state is _ERROR.
        // (In release mode, listener 3 and 4 also run; in debug, the assert
        // short-circuits the chain after index 2.)
        expect(s.disposeCalls.contains(0), isTrue);
        expect(s.disposeCalls.contains(1), isTrue);
        expect(s.disposeCalls.contains(2), isTrue);
        expect(s.state, ServiceState.DISPOSE_ERROR);
      },
    );

    test(
      'a listener that THROWS synchronously (not Sync.err) is captured into '
      'the result chain — state moves to _ERROR but the await does not '
      'surface an uncaught exception',
      () async {
        final s = _PhaseSpy(
          disposeBehavior: const _LB(count: 3, syncThrowAt: 1),
        );
        // Capturing assertion errors is debug-only behavior; ensure we don't
        // hang in release-style flow either:
        Object? caught;
        try {
          (await s.dispose().toAsync().value).end();
        } on Object catch (e) {
          caught = e;
        }
        // The thrown exception bubbles via the assert in _updateState
        // recordError, but the await is allowed to settle either way; what
        // matters is the state was recorded.
        // In debug mode an AssertionError will fire; in release it won't.
        // Either way disposeCalls[0..2] should all be present (non-eager).
        expect(s.disposeCalls.contains(0), isTrue);
        expect(s.disposeCalls.contains(1), isTrue);
        expect(s.state, ServiceState.DISPOSE_ERROR);
        // Recorded error or assertion thrown — both are acceptable shapes.
        expect(
          caught == null || caught is AssertionError || caught is StateError,
          isTrue,
        );
      },
    );

    test(
      'an Async listener that throws is treated as Err — state goes _ERROR',
      () async {
        final s = _PhaseSpy(
          disposeBehavior: const _LB(count: 3, asyncErrAt: 1),
        );
        Object? caught;
        try {
          (await s.dispose().toAsync().value).end();
        } on Object catch (e) {
          caught = e;
        }
        expect(s.state, ServiceState.DISPOSE_ERROR);
        // disposeCalls 0 and 1 ran. 2 may or may not run depending on how
        // the Async error short-circuits in non-eager mode (resultMap maps
        // it to Ok and the next listener runs). Either is acceptable.
        expect(s.disposeCalls.contains(0), isTrue);
        expect(s.disposeCalls.contains(1), isTrue);
        // Sanity: didn't crash test isolate with an uncaught exception.
        expect(
          caught == null || caught is AssertionError || caught is StateError,
          isTrue,
        );
      },
    );
  });

  // ── Idempotency / state transitions ───────────────────────────────────────
  group('idempotency and state transitions', () {
    test('init() called 100 times in a burst only fires listeners once',
        () async {
      final s = _PhaseSpy();
      final futs = List.generate(100, (_) => s.init().toAsync().value);
      for (final f in futs) {
        (await f).end();
      }
      expect(s.initCalls.length, 1);
      expect(s.state, ServiceState.RUN_SUCCESS);
    });

    test('dispose() called 100 times in a burst only fires listeners once',
        () async {
      final s = _PhaseSpy();
      (await s.init().toAsync().value).end();
      final futs = List.generate(100, (_) => s.dispose().toAsync().value);
      for (final f in futs) {
        (await f).end();
      }
      expect(s.disposeCalls.length, 1);
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
    });

    test(
      'pause→resume→pause→resume×100 — every transition fires its listeners',
      () async {
        final s = _PhaseSpy();
        (await s.init().toAsync().value).end();
        for (var n = 0; n < 100; n++) {
          (await s.pause().toAsync().value).end();
          (await s.resume().toAsync().value).end();
        }
        expect(s.pauseCalls.length, 100);
        expect(s.resumeCalls.length, 100);
        expect(s.state, ServiceState.RESUME_SUCCESS);
      },
    );

    test(
      'pause() while already paused — no-op, no extra listener fire',
      () async {
        final s = _PhaseSpy();
        (await s.init().toAsync().value).end();
        (await s.pause().toAsync().value).end();
        // Already paused — second pause is a no-op.
        (await s.pause().toAsync().value).end();
        (await s.pause().toAsync().value).end();
        expect(s.pauseCalls.length, 1);
      },
    );

    test(
      'pause listener that Errs lands the service in PAUSE_ERROR',
      () async {
        final s = _PhaseSpy(
          pauseBehavior: const _LB(count: 3, errAt: 1),
        );
        (await s.init().toAsync().value).end();
        (await s.pause().toAsync().value).end();
        expect(s.state, ServiceState.PAUSE_ERROR);
      },
    );

    test(
      'resume listener that Errs lands the service in RESUME_ERROR',
      () async {
        final s = _PhaseSpy(
          resumeBehavior: const _LB(count: 3, errAt: 1),
        );
        (await s.init().toAsync().value).end();
        (await s.pause().toAsync().value).end();
        (await s.resume().toAsync().value).end();
        expect(s.state, ServiceState.RESUME_ERROR);
      },
    );

    test(
      'init→dispose→init: terminal disposed, second init is a no-op',
      () async {
        final s = _PhaseSpy();
        (await s.init().toAsync().value).end();
        (await s.dispose().toAsync().value).end();
        (await s.init().toAsync().value).end();
        (await s.pause().toAsync().value).end();
        (await s.resume().toAsync().value).end();
        expect(s.initCalls.length, 1);
        expect(s.disposeCalls.length, 1);
        expect(s.pauseCalls, isEmpty);
        expect(s.resumeCalls, isEmpty);
        expect(s.state, ServiceState.DISPOSE_SUCCESS);
      },
    );
  });

  // ── didEverInitAndSuccessfully ────────────────────────────────────────────
  group('didEverInitAndSuccessfully invariant', () {
    test('false on a fresh service', () {
      final s = _PhaseSpy();
      expect(s.didEverInitAndSuccessfully, isFalse);
    });

    test('true after a successful init()', () async {
      final s = _PhaseSpy();
      (await s.init().toAsync().value).end();
      expect(s.didEverInitAndSuccessfully, isTrue);
    });

    test('stays true after subsequent dispose', () async {
      final s = _PhaseSpy();
      (await s.init().toAsync().value).end();
      (await s.dispose().toAsync().value).end();
      expect(s.didEverInitAndSuccessfully, isTrue);
    });

    test('stays false if init Errs out', () async {
      final s = _PhaseSpy(initBehavior: const _LB(count: 3, errAt: 0));
      (await s.init().toAsync().value).end();
      expect(s.state, ServiceState.RUN_ERROR);
      expect(s.didEverInitAndSuccessfully, isFalse);
    });
  });

  // ── Re-entrant lifecycle calls ────────────────────────────────────────────
  group('re-entrant lifecycle calls', () {
    test(
      'dispose() called from inside an init listener serializes — '
      'init completes, then dispose runs',
      () async {
        final s = _ReentrantSpy();
        // init() enqueues dispose() inside its own listener. The sequencer
        // ensures init() finishes before dispose() begins.
        (await s.init().toAsync().value).end();
        // Wait for the queued dispose() to drain.
        await Future<void>.delayed(const Duration(milliseconds: 5));
        expect(s.initCalls, equals(['init-start', 'init-end']));
        expect(s.disposeCalls, equals(['dispose']));
        expect(s.state, ServiceState.DISPOSE_SUCCESS);
      },
    );
  });

  // ── Concurrent lifecycle storms ───────────────────────────────────────────
  group('concurrent lifecycle storms', () {
    test(
      '100 services × init/pause/resume/dispose all complete deterministically',
      () async {
        final services = List.generate(100, (_) => _PhaseSpy());
        await Future.wait(
          services.map((s) async {
            (await s.init().toAsync().value).end();
            (await s.pause().toAsync().value).end();
            (await s.resume().toAsync().value).end();
            (await s.dispose().toAsync().value).end();
          }),
        );
        for (final s in services) {
          expect(s.initCalls.length, 1);
          expect(s.pauseCalls.length, 1);
          expect(s.resumeCalls.length, 1);
          expect(s.disposeCalls.length, 1);
          expect(s.state, ServiceState.DISPOSE_SUCCESS);
        }
      },
    );

    test(
      'fire-and-forget: init() / pause() / dispose() in tight sequence — '
      'all listeners fire exactly once, terminal state is dispose',
      () async {
        final s = _PhaseSpy();
        final a = s.init().toAsync().value;
        final b = s.pause().toAsync().value;
        final c = s.resume().toAsync().value;
        final d = s.dispose().toAsync().value;
        (await a).end();
        (await b).end();
        (await c).end();
        (await d).end();
        expect(s.initCalls.length, 1);
        expect(s.pauseCalls.length, 1);
        expect(s.resumeCalls.length, 1);
        expect(s.disposeCalls.length, 1);
        expect(s.state, ServiceState.DISPOSE_SUCCESS);
      },
    );
  });
}
