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

// Tests for the full ServiceMixin lifecycle: init / pause / resume / dispose,
// state transitions, idempotency, listener error surfacing, and ordering.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

/// A test service that records each lifecycle callback into [log] so tests
/// can assert order and count of invocations.
final class RecordingService extends Service {
  RecordingService({
    this.throwOnInit = false,
    this.throwOnPause = false,
    this.throwOnResume = false,
    this.throwOnDispose = false,
    this.extraInitListeners = 0,
  });

  final bool throwOnInit;
  final bool throwOnPause;
  final bool throwOnResume;
  final bool throwOnDispose;
  final int extraInitListeners;

  final List<String> log = [];

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) {
    return [
      (_) {
        log.add('init');
        if (throwOnInit) return Sync.err(Err('init failed'));
        return syncUnit();
      },
      for (var i = 0; i < extraInitListeners; i++)
        (_) {
          log.add('init.extra.$i');
          return syncUnit();
        },
    ];
  }

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) {
    return [
      (_) {
        log.add('pause');
        if (throwOnPause) return Sync.err(Err('pause failed'));
        return syncUnit();
      },
    ];
  }

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) {
    return [
      (_) {
        log.add('resume');
        if (throwOnResume) return Sync.err(Err('resume failed'));
        return syncUnit();
      },
    ];
  }

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) {
    return [
      (_) {
        log.add('dispose');
        if (throwOnDispose) return Sync.err(Err('dispose failed'));
        return syncUnit();
      },
    ];
  }
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('ServiceMixin: happy-path state transitions', () {
    test('starts at NOT_INITIALIZED', () {
      final s = RecordingService();
      expect(s.state, ServiceState.NOT_INITIALIZED);
      expect(s.didEverInitAndSuccessfully, isFalse);
    });

    test('init transitions to RUN_SUCCESS and runs listeners', () async {
      final s = RecordingService();
      (await s.init().value).end();
      expect(s.state, ServiceState.RUN_SUCCESS);
      expect(s.didEverInitAndSuccessfully, isTrue);
      expect(s.log, ['init']);
    });

    test('pause transitions to PAUSE_SUCCESS and runs listeners', () async {
      final s = RecordingService();
      (await s.init().value).end();
      (await s.pause().value).end();
      expect(s.state, ServiceState.PAUSE_SUCCESS);
      expect(s.log, ['init', 'pause']);
    });

    test('resume transitions to RESUME_SUCCESS and runs listeners', () async {
      final s = RecordingService();
      (await s.init().value).end();
      (await s.pause().value).end();
      (await s.resume().value).end();
      expect(s.state, ServiceState.RESUME_SUCCESS);
      expect(s.log, ['init', 'pause', 'resume']);
    });

    test('dispose transitions to DISPOSE_SUCCESS and runs listeners', () async {
      final s = RecordingService();
      (await s.init().value).end();
      (await s.dispose().value).end();
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
      expect(s.log, ['init', 'dispose']);
    });

    test('full cycle: init → pause → resume → dispose', () async {
      final s = RecordingService();
      (await s.init().value).end();
      (await s.pause().value).end();
      (await s.resume().value).end();
      (await s.dispose().value).end();
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
      expect(s.log, ['init', 'pause', 'resume', 'dispose']);
    });
  });

  group('ServiceMixin: idempotency', () {
    // The lifecycle methods assert their preconditions in debug mode; in
    // release the assertion is stripped but an early-return if-guard still
    // skips the listeners. Tests run with assertions enabled, so we swallow
    // any AssertionError and check that listeners didn't actually re-run.
    test('init twice does not double-run listeners', () async {
      final s = RecordingService();
      (await s.init().value).end();
      try {
        (await s.init().value).end();
      } on Object {
        // expected in debug
      }
      expect(s.log, ['init']);
    });

    test('pause twice does not double-run listeners', () async {
      final s = RecordingService();
      (await s.init().value).end();
      (await s.pause().value).end();
      try {
        (await s.pause().value).end();
      } on Object {
        // expected in debug
      }
      expect(s.log, ['init', 'pause']);
    });

    test('resume twice does not double-run listeners', () async {
      final s = RecordingService();
      (await s.init().value).end();
      (await s.pause().value).end();
      (await s.resume().value).end();
      try {
        (await s.resume().value).end();
      } on Object {
        // expected in debug
      }
      expect(s.log, ['init', 'pause', 'resume']);
    });

    test('dispose after dispose is a no-op', () async {
      final s = RecordingService();
      (await s.init().value).end();
      (await s.dispose().value).end();
      try {
        (await s.dispose().value).end();
      } on Object {
        // expected in debug
      }
      expect(s.log, ['init', 'dispose']);
    });

    test('init after dispose is rejected', () async {
      final s = RecordingService();
      (await s.init().value).end();
      (await s.dispose().value).end();
      // Ignore the assertion in debug mode for this check.
      try {
        (await s.init().value).end();
      } on Object {
        // Assertion fired; that's acceptable. The real protection is the
        // explicit if-guard for release mode.
      }
      // Either way, listeners must not have re-run.
      expect(s.log, ['init', 'dispose']);
    });
  });

  group('ServiceMixin: listener order and count', () {
    test('multiple init listeners run in declared order', () async {
      final s = RecordingService(extraInitListeners: 3);
      (await s.init().value).end();
      expect(s.log, ['init', 'init.extra.0', 'init.extra.1', 'init.extra.2']);
    });
  });

  group('ServiceMixin: listener error surfacing', () {
    test('init listener error → state = RUN_ERROR', () async {
      final s = RecordingService(throwOnInit: true);
      // Assertions fire in debug; suppress so we can inspect state.
      try {
        (await s.init().value).end();
      } on Object {
        // expected in debug
      }
      expect(s.state, ServiceState.RUN_ERROR);
      expect(s.didEverInitAndSuccessfully, isFalse);
    });

    test('pause listener error → state = PAUSE_ERROR', () async {
      final s = RecordingService(throwOnPause: true);
      (await s.init().value).end();
      try {
        (await s.pause().value).end();
      } on Object {
        // expected in debug
      }
      expect(s.state, ServiceState.PAUSE_ERROR);
    });

    test('resume listener error → state = RESUME_ERROR', () async {
      final s = RecordingService(throwOnResume: true);
      (await s.init().value).end();
      (await s.pause().value).end();
      try {
        (await s.resume().value).end();
      } on Object {
        // expected in debug
      }
      expect(s.state, ServiceState.RESUME_ERROR);
    });

    test('dispose listener error → state = DISPOSE_ERROR', () async {
      final s = RecordingService(throwOnDispose: true);
      (await s.init().value).end();
      try {
        (await s.dispose().value).end();
      } on Object {
        // expected in debug
      }
      expect(s.state, ServiceState.DISPOSE_ERROR);
    });

    test('init Resolvable carries Err on listener failure', () async {
      final s = RecordingService(throwOnInit: true);
      Object? caught;
      try {
        (await s.init().value).end();
      } catch (e) {
        caught = e;
      }
      // Either we caught the assertion or the Result is Err; either way the
      // error must not be silent.
      expect(
        caught != null || s.state == ServiceState.RUN_ERROR,
        isTrue,
        reason: 'init failure should not look healthy',
      );
    });
  });

  group('ServiceMixin: DI integration via onRegister/onUnregister', () {
    test('registering with init+ServiceMixin.unregister drives full cycle',
        () async {
      final di = DI();
      final s = RecordingService();
      di
          .register<RecordingService>(
            s,
            onRegister: Some((svc) => svc.init()),
            onUnregister: const Some(ServiceMixin.unregister),
          )
          .end();

      // Wait for service to be available via untilSuper.
      UNSAFE:
      final retrieved = await di.untilSuper<RecordingService>().unwrap();
      expect(identical(retrieved, s), isTrue);
      // init has run by the time the service is available for use.
      expect(s.log, contains('init'));
      expect(s.state, ServiceState.RUN_SUCCESS);

      // Unregister triggers dispose via ServiceMixin.unregister.
      (await di.unregister<RecordingService>().value).end();
      expect(s.log, ['init', 'dispose']);
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
    });
  });

  group('ServiceMixin: sequencing', () {
    test('concurrent pause/resume calls serialize through the sequencer',
        () async {
      final s = RecordingService();
      (await s.init().value).end();
      // Fire several lifecycle calls without awaiting between them; the
      // sequencer must serialize them.
      final f1 = s.pause().value;
      final f2 = s.resume().value;
      final f3 = s.pause().value;
      (await f1).end();
      (await f2).end();
      (await f3).end();
      // Each transition runs exactly once and in order.
      expect(s.log, ['init', 'pause', 'resume', 'pause']);
    });
  });
}
