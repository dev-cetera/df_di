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

// Audit pass 4: more reliability holes uncovered after passes 1-3 of
// hardening. Each test asserts a contract that should hold for
// medical-grade callers.

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

final class _A {
  const _A([this.tag = '']);
  final String tag;
}

class _ErringSvc with ServiceMixin {
  _ErringSvc({this.failOn = 'init'});
  final String failOn;
  final trace = <String>[];

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) {
          trace.add('init');
          if (failOn == 'init') return Sync<Unit>.err(Err('init fail'));
          return Sync<Unit>.okValue(Unit());
        },
      ];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) => [
        (_) {
          trace.add('pause');
          if (failOn == 'pause') return Sync<Unit>.err(Err('pause fail'));
          return Sync<Unit>.okValue(Unit());
        },
      ];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) => [
        (_) {
          trace.add('resume');
          if (failOn == 'resume') return Sync<Unit>.err(Err('resume fail'));
          return Sync<Unit>.okValue(Unit());
        },
      ];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
        (_) {
          trace.add('dispose');
          if (failOn == 'dispose') {
            return Sync<Unit>.err(Err('dispose fail'));
          }
          return Sync<Unit>.okValue(Unit());
        },
      ];
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // 1. Lazy<T> with an Async constructor that rejects must surface Err on
  //    singleton access.
  // ─────────────────────────────────────────────────────────────────────────
  group('Lazy<T>: async constructor failure', () {
    test(
      'Async constructor that rejects → singleton access surfaces Err',
      () async {
        final di = DI();
        di
            .registerLazy<_A>(
              () => Async<_A>(() async {
                await Future<void>.delayed(const Duration(milliseconds: 5));
                throw StateError('async constructor failed');
              }),
            )
            .end();
        UNSAFE:
        final lazy = di.getLazy<_A>().unwrap().sync().unwrap().unwrap();
        final r = await lazy.singleton.toAsync().value;
        expect(
          r.isErr(),
          isTrue,
          reason:
              'An Async Lazy constructor that throws must surface as Err on '
              'singleton access — not hang.',
        );
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Service lifecycle after init Err — pause / resume / dispose must
  //    still serialize and reach terminal states deterministically.
  // ─────────────────────────────────────────────────────────────────────────
  group('service: lifecycle after init Err', () {
    test('init Err → pause → resume → dispose all complete deterministically',
        () async {
      final s = _ErringSvc();
      (await s.init().toAsync().value).end();
      expect(s.state, ServiceState.RUN_ERROR);
      (await s.pause().toAsync().value).end();
      expect(s.state, ServiceState.PAUSE_SUCCESS);
      (await s.resume().toAsync().value).end();
      expect(s.state, ServiceState.RESUME_SUCCESS);
      (await s.dispose().toAsync().value).end();
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
      // The init listener ran (and failed) exactly once; pause/resume/dispose
      // each ran once.
      expect(
        s.trace,
        equals(['init', 'pause', 'resume', 'dispose']),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 3. registerAndInitService: a user-supplied onRegister that throws
  //    surfaces as Err on the returned Resolvable.
  // ─────────────────────────────────────────────────────────────────────────
  group('registerAndInitService: user onRegister failure', () {
    test('user onRegister sync throw → Err result', () async {
      final di = DI();
      final s = _ErringSvc(failOn: 'never');
      final r = await di
          .registerAndInitService<_ErringSvc>(
            s,
            onRegister: Some((_) {
              throw StateError('user onRegister fail');
            }),
          )
          .toAsync()
          .value;
      expect(r.isErr(), isTrue);
      // service.init() did run (before the user hook), but the overall
      // registration is failed and the service is not retrievable.
      expect(s.state, ServiceState.RUN_SUCCESS);
    });

    test('user onRegister async throw → Err result', () async {
      final di = DI();
      final s = _ErringSvc(failOn: 'never');
      final r = await di
          .registerAndInitService<_ErringSvc>(
            s,
            onRegister: Some((_) async {
              await Future<void>.delayed(const Duration(milliseconds: 5));
              throw StateError('user onRegister async fail');
            }),
          )
          .toAsync()
          .value;
      expect(r.isErr(), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 4. SafeCompleter — second `complete` returns an Err Resolvable; the
  //    first value remains the only one observable.
  // ─────────────────────────────────────────────────────────────────────────
  group('SafeCompleter: double-complete', () {
    test('second complete returns Err and does not overwrite the value',
        () async {
      final c = SafeCompleter<int>();
      final first = await c.complete(1).toAsync().value;
      UNSAFE:
      expect(first.unwrap(), 1);
      final second = await c.complete(2).toAsync().value;
      expect(
        second.isErr(),
        isTrue,
        reason: 'a SafeCompleter must reject a second complete',
      );
      // The completer's stored value is the FIRST one.
      UNSAFE:
      final stored = await c.resolvable().toAsync().value;
      UNSAFE:
      expect(stored.unwrap(), 1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 5. Stream service — listener that calls pushToStream re-entrantly
  //    serializes via the shared push sequencer (no deadlock, ordering
  //    preserved).
  // ─────────────────────────────────────────────────────────────────────────
  group('stream: re-entrant pushToStream from a listener', () {
    test(
      'a listener that pushes a sentinel value during the first emission '
      'sees that sentinel as a subsequent emission, not a nested one',
      () async {
        final s = _ReEntrantStream();
        (await s.init().toAsync().value).end();
        s.input.add(const Ok<int>(1));
        // Allow chain to drain.
        await Future<void>.delayed(const Duration(milliseconds: 30));
        // First emission: 1. Listener responded with sentinel 100.
        // So 100 should also have been received.
        expect(s.received.contains(1), isTrue);
        expect(s.received.contains(100), isTrue);
        (await s.dispose().toAsync().value).end();
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 6. Cross-container dispose isolation: disposing service A's dispose
  //    listener that touches the SAME DI container does not corrupt
  //    surviving registrations.
  // ─────────────────────────────────────────────────────────────────────────
  group('cross-container teardown', () {
    test(
      'service A onUnregister that unregisters service B inside the same '
      'DI does not corrupt the registry — B is gone, registry stays '
      'consistent',
      () async {
        final di = DI();
        final aSvc = _ErringSvc(failOn: 'never');
        final bSvc = _ErringSvc(failOn: 'never');
        (await di
                .registerAndInitService<_ErringSvc>(
                  aSvc,
                  groupEntity: const _GroupA(),
                  onUnregister: Some((_) {
                    di
                        .unregister<_ErringSvc>(
                          groupEntity: const _GroupB(),
                        )
                        .end();
                  }),
                )
                .toAsync()
                .value)
            .end();
        (await di
                .registerAndInitService<_ErringSvc>(
                  bSvc,
                  groupEntity: const _GroupB(),
                )
                .toAsync()
                .value)
            .end();
        // Now unregister A — its onUnregister tears down B.
        (await di
                .unregister<_ErringSvc>(
                  groupEntity: const _GroupA(),
                )
                .toAsync()
                .value)
            .end();
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(
          di.isRegistered<_ErringSvc>(groupEntity: const _GroupA()),
          isFalse,
        );
        expect(
          di.isRegistered<_ErringSvc>(groupEntity: const _GroupB()),
          isFalse,
        );
        expect(
          di.registry
              .groupsWithTypeK(TypeEntity(Sync, [TypeEntity(_ErringSvc)])),
          isEmpty,
        );
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 7. unregister(removeAll: false) on a hierarchy — only the first match
  //    removed (this container first, then parents).
  // ─────────────────────────────────────────────────────────────────────────
  group('unregister(removeAll: false): hierarchy', () {
    test(
      'parent and child both have the dep; child.unregister(removeAll: false) '
      'removes only from child',
      () async {
        final parent = DI();
        final child = DI();
        child.parents.add(parent);
        parent.register<_A>(const _A('parent')).end();
        child.register<_A>(const _A('child')).end();
        (await child.unregister<_A>(removeAll: false).toAsync().value).end();
        // Parent still has it; child no longer registered locally — but
        // via traversal, child reaches parent's registration.
        expect(parent.isRegistered<_A>(), isTrue);
        UNSAFE:
        final got = child.getSyncUnsafe<_A>();
        expect(got.tag, 'parent');
      },
    );

    test(
      'child.unregister(removeAll: true) removes from BOTH child and parent',
      () async {
        final parent = DI();
        final child = DI();
        child.parents.add(parent);
        parent.register<_A>(const _A('parent')).end();
        child.register<_A>(const _A('child')).end();
        (await child.unregister<_A>().toAsync().value).end();
        expect(parent.isRegistered<_A>(), isFalse);
        expect(child.isRegistered<_A>(traverse: false), isFalse);
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 8. The `assert(prev2.isErr(), ...)` dead-code in pushToStream — verify
  //    the actual error logging still works (Log.err is the live path).
  // ─────────────────────────────────────────────────────────────────────────
  group('pushToStream: erroring listener observability', () {
    test(
      'an erroring listener does not crash subsequent emissions',
      () async {
        final s = _ErroringListenerStream();
        (await s.init().toAsync().value).end();
        s.input.add(const Ok<int>(1));
        s.input.add(const Ok<int>(2));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        // Both emissions should reach the GOOD listener.
        expect(s.received, equals([1, 2]));
        (await s.dispose().toAsync().value).end();
      },
    );
  });
}

final class _GroupA extends Entity {
  const _GroupA() : super.reserved(-91001);
}

final class _GroupB extends Entity {
  const _GroupB() : super.reserved(-91002);
}

class _ReEntrantStream extends StreamService<int> {
  final input = StreamController<Result<int>>.broadcast();
  final received = <int>[];
  bool _sentinelSent = false;

  @override
  Stream<Result<int>> provideInputStream() => input.stream;

  @override
  TServiceResolvables<Result<int>> provideOnPushToStreamListeners() => [
        (data) {
          switch (data) {
            case Ok(value: final v):
              received.add(v);
              // First time we see a real value, re-enter pushToStream with a
              // sentinel. Must NOT deadlock; the sentinel arrives as a later
              // emission on the SAME push sequencer.
              if (!_sentinelSent) {
                _sentinelSent = true;
                pushToStream(const Ok<int>(100)).end();
              }
            case Err():
          }
          return Sync<Unit>.okValue(Unit());
        },
      ];
}

class _ErroringListenerStream extends StreamService<int> {
  final input = StreamController<Result<int>>.broadcast();
  final received = <int>[];

  @override
  Stream<Result<int>> provideInputStream() => input.stream;

  @override
  TServiceResolvables<Result<int>> provideOnPushToStreamListeners() => [
        (data) {
          // BAD listener — always errs.
          return Sync<Unit>.err(Err('listener bomb'));
        },
        (data) {
          // GOOD listener — records.
          switch (data) {
            case Ok(value: final v):
              received.add(v);
            case Err():
          }
          return Sync<Unit>.okValue(Unit());
        },
      ];
}
