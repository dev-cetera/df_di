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

// Unit tests for `lib/src/services/service.dart`.
//
// Exercises the `Service` convenience base class plus the `ServiceMixin`
// state machine (default state, valid transitions, idempotent/invalid
// transitions producing Err rather than silent Ok, listener order,
// TaskSequencer serialization of concurrent lifecycle calls, the
// `ServiceMixin.unregister` static hook used by DI to cascade `dispose()`,
// and the `ServiceState` enum predicates.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

/// Captures the order of lifecycle hook invocations into [log] so tests can
/// assert sequencing and counts.
final class _ProbeService extends Service {
  _ProbeService({
    this.throwOnInit = false,
    this.throwOnDispose = false,
  });

  final bool throwOnInit;
  final bool throwOnDispose;

  final List<String> log = [];

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) {
          log.add('init');
          if (throwOnInit) return Sync.err(Err('init failed'));
          return syncUnit();
        },
      ];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) => [
        (_) {
          log.add('pause');
          return syncUnit();
        },
      ];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) => [
        (_) {
          log.add('resume');
          return syncUnit();
        },
      ];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
        (_) {
          log.add('dispose');
          if (throwOnDispose) return Sync.err(Err('dispose failed'));
          return syncUnit();
        },
      ];
}

/// Bare mixin variant — verifies `ServiceMixin` can be applied without
/// extending the `Service` convenience class.
final class _BareMixinService with ServiceMixin {
  final List<String> log = [];

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) {
          log.add('init');
          return syncUnit();
        },
      ];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) => [];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) => [];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
        (_) {
          log.add('dispose');
          return syncUnit();
        },
      ];
}

/// Service whose first init listener defers via an `Async` so we can prove
/// the TaskSequencer serialises later concurrent lifecycle calls.
final class _AsyncInitService extends Service {
  final List<String> log = [];

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) => Async<Unit>(() async {
              await Future<void>.delayed(const Duration(milliseconds: 5));
              log.add('init');
              return Unit();
            }),
      ];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) => [
        (_) {
          log.add('pause');
          return syncUnit();
        },
      ];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) => [
        (_) {
          log.add('resume');
          return syncUnit();
        },
      ];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
        (_) {
          log.add('dispose');
          return syncUnit();
        },
      ];
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('Service / ServiceMixin: defaults', () {
    test('default state is NOT_INITIALIZED', () {
      final s = _ProbeService();
      expect(s.state, ServiceState.NOT_INITIALIZED);
      expect(s.state.isNotInitialized, isTrue);
      expect(s.didEverInitAndSuccessfully, isFalse);
    });

    test('bare ServiceMixin (no Service base) still works', () async {
      final s = _BareMixinService();
      expect(s.state, ServiceState.NOT_INITIALIZED);
      (await s.init().value).end();
      expect(s.state, ServiceState.RUN_SUCCESS);
      expect(s.log, ['init']);
      (await s.dispose().value).end();
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
      expect(s.log, ['init', 'dispose']);
    });
  });

  group('ServiceMixin.init: valid transitions', () {
    test('init() runs listeners and reaches RUN_SUCCESS', () async {
      final s = _ProbeService();
      final res = await s.init().value;
      expect(res.isOk(), isTrue);
      expect(s.state, ServiceState.RUN_SUCCESS);
      expect(s.didEverInitAndSuccessfully, isTrue);
      expect(s.log, ['init']);
    });

    test('didEverInitAndSuccessfully stays true even after dispose', () async {
      final s = _ProbeService();
      (await s.init().value).end();
      (await s.dispose().value).end();
      expect(s.didEverInitAndSuccessfully, isTrue);
    });
  });

  group('ServiceMixin.init: invalid transitions return Err', () {
    test('second init() returns Err and does not re-run listeners', () async {
      final s = _ProbeService();
      (await s.init().value).end();
      Result<Unit>? second;
      try {
        second = await s.init().value;
      } on AssertionError {
        // expected in debug
      }
      // Either we got an Err result or the assertion fired in debug — the
      // listener log must remain unchanged.
      if (second != null) {
        expect(second.isErr(), isTrue);
      }
      expect(s.log, ['init']);
    });

    test('init() after dispose() returns Err (terminal)', () async {
      final s = _ProbeService();
      (await s.init().value).end();
      (await s.dispose().value).end();
      Result<Unit>? r;
      try {
        r = await s.init().value;
      } on AssertionError {
        // expected in debug
      }
      if (r != null) {
        expect(r.isErr(), isTrue);
      }
      expect(s.log, ['init', 'dispose']);
    });
  });

  group('ServiceMixin.pause', () {
    test('pause() transitions to PAUSE_SUCCESS and fires listener', () async {
      final s = _ProbeService();
      (await s.init().value).end();
      (await s.pause().value).end();
      expect(s.state, ServiceState.PAUSE_SUCCESS);
      expect(s.log, ['init', 'pause']);
    });

    test('pause() before init() returns Err', () async {
      final s = _ProbeService();
      Result<Unit>? r;
      try {
        r = await s.pause().value;
      } on AssertionError {
        // expected in debug
      }
      if (r != null) {
        expect(r.isErr(), isTrue);
      }
      expect(s.state, ServiceState.NOT_INITIALIZED);
      expect(s.log, isEmpty);
    });

    test('pause() while paused is idempotent (Ok(None), no re-run)', () async {
      final s = _ProbeService();
      (await s.init().value).end();
      (await s.pause().value).end();
      final r = await s.pause().value;
      expect(r.isOk(), isTrue);
      expect(s.log, ['init', 'pause']);
      expect(s.state, ServiceState.PAUSE_SUCCESS);
    });

    test('pause() after dispose() returns Err', () async {
      final s = _ProbeService();
      (await s.init().value).end();
      (await s.dispose().value).end();
      Result<Unit>? r;
      try {
        r = await s.pause().value;
      } on AssertionError {
        // expected in debug
      }
      if (r != null) {
        expect(r.isErr(), isTrue);
      }
      expect(s.log, ['init', 'dispose']);
    });
  });

  group('ServiceMixin.resume', () {
    test('resume() after pause() reaches RESUME_SUCCESS', () async {
      final s = _ProbeService();
      (await s.init().value).end();
      (await s.pause().value).end();
      (await s.resume().value).end();
      expect(s.state, ServiceState.RESUME_SUCCESS);
      expect(s.log, ['init', 'pause', 'resume']);
    });

    test('resume() while not paused (already RUN_SUCCESS) returns Ok(None)',
        () async {
      // The contract: resume() while `didResume()` is a no-op. RUN_SUCCESS
      // is NOT a resume substate, so direct resume() after init() runs
      // listeners and transitions to RESUME_SUCCESS.
      final s = _ProbeService();
      (await s.init().value).end();
      (await s.resume().value).end();
      expect(s.state, ServiceState.RESUME_SUCCESS);
      expect(s.log, ['init', 'resume']);
    });

    test('resume() while already in RESUME_SUCCESS is idempotent', () async {
      final s = _ProbeService();
      (await s.init().value).end();
      (await s.pause().value).end();
      (await s.resume().value).end();
      final r = await s.resume().value;
      expect(r.isOk(), isTrue);
      expect(s.log, ['init', 'pause', 'resume']);
    });

    test('resume() before init() returns Err', () async {
      final s = _ProbeService();
      Result<Unit>? r;
      try {
        r = await s.resume().value;
      } on AssertionError {
        // expected in debug
      }
      if (r != null) {
        expect(r.isErr(), isTrue);
      }
      expect(s.state, ServiceState.NOT_INITIALIZED);
    });

    test('resume() after dispose() returns Err', () async {
      final s = _ProbeService();
      (await s.init().value).end();
      (await s.dispose().value).end();
      Result<Unit>? r;
      try {
        r = await s.resume().value;
      } on AssertionError {
        // expected in debug
      }
      if (r != null) {
        expect(r.isErr(), isTrue);
      }
    });
  });

  group('ServiceMixin.dispose', () {
    test('dispose() transitions to DISPOSE_SUCCESS and fires listener',
        () async {
      final s = _ProbeService();
      (await s.init().value).end();
      (await s.dispose().value).end();
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
      expect(s.log, ['init', 'dispose']);
    });

    test('dispose() while already disposed is idempotent Ok(None)', () async {
      final s = _ProbeService();
      (await s.init().value).end();
      (await s.dispose().value).end();
      final r = await s.dispose().value;
      expect(r.isOk(), isTrue);
      expect(s.log, ['init', 'dispose']);
    });

    test('dispose() before init() is allowed (terminal early)', () async {
      // dispose() is permitted from NOT_INITIALIZED — its only guard is
      // the didDispose() short-circuit. Listeners do run.
      final s = _ProbeService();
      final r = await s.dispose().value;
      expect(r.isOk(), isTrue);
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
      expect(s.log, ['dispose']);
    });
  });

  group('ServiceMixin: listener error surfacing', () {
    test('init listener Err → RUN_ERROR', () async {
      final s = _ProbeService(throwOnInit: true);
      try {
        (await s.init().value).end();
      } on Object {
        // expected in debug
      }
      expect(s.state, ServiceState.RUN_ERROR);
      expect(s.didEverInitAndSuccessfully, isFalse);
    });

    test('dispose listener Err → DISPOSE_ERROR', () async {
      final s = _ProbeService(throwOnDispose: true);
      (await s.init().value).end();
      try {
        (await s.dispose().value).end();
      } on Object {
        // expected in debug
      }
      expect(s.state, ServiceState.DISPOSE_ERROR);
    });
  });

  group('ServiceMixin: TaskSequencer serialization', () {
    test('two concurrent init() calls do not double-run listeners', () async {
      final s = _AsyncInitService();
      // Fire both inits without awaiting between them.
      final a = s.init().value;
      final b = s.init().value;
      try {
        (await a).end();
      } on Object {/*ok*/}
      try {
        (await b).end();
      } on Object {/*ok*/}
      // Listeners run at most once per service lifetime.
      expect(s.log.where((l) => l == 'init').length, 1);
    });

    test('init → pause → resume → dispose fire in order under interleave',
        () async {
      // Use the all-sync probe so behaviour matches the existing
      // `service_lifecycle_test.dart::concurrent pause/resume` test.
      final s = _ProbeService();
      (await s.init().value).end();
      final f1 = s.pause().value;
      final f2 = s.resume().value;
      final f3 = s.dispose().value;
      (await f1).end();
      (await f2).end();
      (await f3).end();
      expect(s.log, ['init', 'pause', 'resume', 'dispose']);
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
    });
  });

  group('ServiceMixin.unregister static hook (DI cascade)', () {
    test('unregister on Ok service result calls dispose()', () async {
      final s = _ProbeService();
      (await s.init().value).end();
      final hook = ServiceMixin.unregister(Ok<ServiceMixin>(s));
      (await hook.value).end();
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
      expect(s.log, ['init', 'dispose']);
    });

    test('unregister on Err service result is a no-op (Ok(unit))', () async {
      final hook = ServiceMixin.unregister(Err<ServiceMixin>('missing'));
      final r = await hook.value;
      expect(r.isOk(), isTrue);
    });

    test('register+unregister via DI cascades into service.dispose()',
        () async {
      final di = DI();
      final s = _ProbeService();
      di
          .register<_ProbeService>(
            s,
            onRegister: Some((svc) => svc.init()),
            onUnregister: const Some(ServiceMixin.unregister),
          )
          .end();

      UNSAFE:
      final retrieved = await di.untilSuper<_ProbeService>().unwrap();
      expect(identical(retrieved, s), isTrue);
      expect(s.state, ServiceState.RUN_SUCCESS);

      (await di.unregister<_ProbeService>().value).end();
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
      expect(s.log, ['init', 'dispose']);
    });
  });

  group('ServiceState enum predicates', () {
    test('isNotInitialized', () {
      expect(ServiceState.NOT_INITIALIZED.isNotInitialized, isTrue);
      expect(ServiceState.RUN_SUCCESS.isNotInitialized, isFalse);
    });

    test('didRun() covers all RUN_* substates', () {
      expect(ServiceState.RUN_ATTEMPT.didRun(), isTrue);
      expect(ServiceState.RUN_SUCCESS.didRun(), isTrue);
      expect(ServiceState.RUN_ERROR.didRun(), isTrue);
      expect(ServiceState.NOT_INITIALIZED.didRun(), isFalse);
      expect(ServiceState.PAUSE_SUCCESS.didRun(), isFalse);
    });

    test('didPause() covers all PAUSE_* substates', () {
      expect(ServiceState.PAUSE_ATTEMPT.didPause(), isTrue);
      expect(ServiceState.PAUSE_SUCCESS.didPause(), isTrue);
      expect(ServiceState.PAUSE_ERROR.didPause(), isTrue);
      expect(ServiceState.RUN_SUCCESS.didPause(), isFalse);
    });

    test('didResume() covers all RESUME_* substates', () {
      expect(ServiceState.RESUME_ATTEMPT.didResume(), isTrue);
      expect(ServiceState.RESUME_SUCCESS.didResume(), isTrue);
      expect(ServiceState.RESUME_ERROR.didResume(), isTrue);
      expect(ServiceState.PAUSE_SUCCESS.didResume(), isFalse);
    });

    test('didDispose() covers all DISPOSE_* substates', () {
      expect(ServiceState.DISPOSE_ATTEMPT.didDispose(), isTrue);
      expect(ServiceState.DISPOSE_SUCCESS.didDispose(), isTrue);
      expect(ServiceState.DISPOSE_ERROR.didDispose(), isTrue);
      expect(ServiceState.RUN_SUCCESS.didDispose(), isFalse);
      expect(ServiceState.NOT_INITIALIZED.didDispose(), isFalse);
    });
  });
}
