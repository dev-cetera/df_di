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

// End-to-end mission-critical scenarios that exercise the whole package
// (DI hierarchy + services + streams + lazy singletons + until*) the way a
// real medical/financial app would use it.
//
// Each test models a realistic flow:
//   • boot sequence: register configuration, then services that depend on it
//   • cross-service coordination: serviceB.init() needs serviceA.init() to
//     have finished
//   • teardown: disposing the root cleans up every child
//   • crash recovery: a service that fails to init() is observable and
//     does not corrupt sibling registrations
//   • resource lifecycle: opening and closing a database-like service many
//     times leaves no residue
//
// If any of these flows hang or leak, the package is not ready for the
// medical-grade use case.

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

class _Config {
  const _Config(this.endpoint);
  final String endpoint;
}

class _Database with ServiceMixin {
  _Database(this.config);
  final _Config config;
  bool isOpen = false;
  int openCount = 0;
  int closeCount = 0;

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) => Async<Unit>(() async {
              await Future<void>.delayed(const Duration(milliseconds: 5));
              isOpen = true;
              openCount++;
              return Unit();
            }),
      ];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) => [
        (_) => Sync.okValue(Unit()),
      ];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) => [
        (_) => Sync.okValue(Unit()),
      ];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
        (_) => Async<Unit>(() async {
              await Future<void>.delayed(const Duration(milliseconds: 5));
              isOpen = false;
              closeCount++;
              return Unit();
            }),
      ];
}

class _AuthService with ServiceMixin {
  _AuthService(this.db);
  final _Database db;
  bool authenticated = false;

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) {
          // Hard invariant: AuthService can only init after Database is open.
          if (!db.isOpen) return Sync<Unit>.err(Err('DB not open'));
          authenticated = true;
          return Sync.okValue(Unit());
        },
      ];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) =>
      [(_) => Sync.okValue(Unit())];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) =>
      [(_) => Sync.okValue(Unit())];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
        (_) {
          authenticated = false;
          return Sync.okValue(Unit());
        },
      ];
}

/// Service that throws synchronously during init — used to test that a bad
/// service does not corrupt the rest of the DI graph.
class _CrashingService with ServiceMixin {
  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) {
          throw StateError('boot failed');
        },
      ];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) =>
      [(_) => Sync.okValue(Unit())];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) =>
      [(_) => Sync.okValue(Unit())];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) =>
      [(_) => Sync.okValue(Unit())];
}

void main() {
  // ── Boot sequence ────────────────────────────────────────────────────────
  group('boot sequence', () {
    test(
      'configure → register database → register auth: auth observes the open '
      'database when it finally inits',
      () async {
        final di = DI();
        di.register<_Config>(const _Config('prod://srv')).end();

        // Resolve config sync via DI.
        UNSAFE:
        final cfg = di.getSyncUnsafe<_Config>();
        final db = _Database(cfg);

        // Register the DB. The onRegister kicks off init. We then untilSuper
        // for it to be visible.
        di
            .register<_Database>(
              db,
              onRegister: Some((s) => s.init()),
              onUnregister: const Some(ServiceMixin.unregister),
            )
            .end();

        // Wait for DB to be ready.
        UNSAFE:
        final retrievedDb = await di.untilSuper<_Database>().toAsync().value;
        UNSAFE:
        expect(retrievedDb.unwrap().isOpen, isTrue);

        // Now register auth, which depends on db being open.
        UNSAFE:
        final auth = _AuthService(retrievedDb.unwrap());
        di
            .register<_AuthService>(
              auth,
              onRegister: Some((s) => s.init()),
              onUnregister: const Some(ServiceMixin.unregister),
            )
            .end();

        UNSAFE:
        final retrievedAuth =
            (await di.untilSuper<_AuthService>().toAsync().value).unwrap();
        expect(retrievedAuth.authenticated, isTrue);

        // Teardown in reverse.
        (await di.unregister<_AuthService>().value).end();
        (await di.unregister<_Database>().value).end();

        expect(retrievedAuth.state, ServiceState.DISPOSE_SUCCESS);
        UNSAFE:
        expect(retrievedDb.unwrap().state, ServiceState.DISPOSE_SUCCESS);
        UNSAFE:
        expect(retrievedDb.unwrap().isOpen, isFalse);
      },
    );

    test(
      'untilSuper for the not-yet-registered service resolves once register '
      'and its onRegister have both finished',
      () async {
        final di = DI();
        di.register<_Config>(const _Config('prod://srv')).end();
        UNSAFE:
        final cfg = di.getSyncUnsafe<_Config>();

        // Start a waiter BEFORE registering. By contract (audit C6), the
        // waiter should only resolve once onRegister completes.
        final waiterFut = di.untilSuper<_Database>().toAsync().value;

        final db = _Database(cfg);
        di
            .register<_Database>(
              db,
              onRegister: Some((s) => s.init()),
              onUnregister: const Some(ServiceMixin.unregister),
            )
            .end();

        UNSAFE:
        final resolvedDb = (await waiterFut).unwrap();
        // db.isOpen must be true by the time the waiter resolves.
        expect(resolvedDb.isOpen, isTrue);
      },
    );
  });

  // ── Crash recovery ───────────────────────────────────────────────────────
  group('crash recovery', () {
    test(
      'a service whose init throws is observable and does not corrupt '
      'sibling registrations',
      () async {
        final di = DI();
        di.register<_Config>(const _Config('prod://srv')).end();
        UNSAFE:
        final cfg = di.getSyncUnsafe<_Config>();
        final db = _Database(cfg);
        di
            .register<_Database>(
              db,
              onRegister: Some((s) => s.init()),
              onUnregister: const Some(ServiceMixin.unregister),
            )
            .end();
        UNSAFE:
        (await di.untilSuper<_Database>().toAsync().value).unwrap();
        // Now register a bad service.
        final bad = _CrashingService();
        di
            .register<_CrashingService>(
              bad,
              onRegister: Some((s) => s.init()),
              onUnregister: const Some(ServiceMixin.unregister),
            )
            .end();
        // Wait long enough for init() to attempt + fail.
        await Future<void>.delayed(const Duration(milliseconds: 30));
        // The bad service is in RUN_ERROR.
        expect(bad.state, ServiceState.RUN_ERROR);
        // The good service is still in RUN_SUCCESS.
        expect(db.state, ServiceState.RUN_SUCCESS);
        // The Config registration is still intact.
        UNSAFE:
        expect(di.getSyncUnsafe<_Config>().endpoint, 'prod://srv');
      },
    );
  });

  // ── Hierarchy lifecycle ──────────────────────────────────────────────────
  group('hierarchy lifecycle', () {
    test(
      'three-level hierarchy: root holds Config, child holds DB, '
      'grandchild holds Auth — each level sees its ancestors',
      () async {
        final root = DI();
        root.register<_Config>(const _Config('root://srv')).end();

        // Child layer.
        final child = root.child(groupEntity: UniqueEntity());
        UNSAFE:
        final cfg = child.getSyncUnsafe<_Config>();
        expect(cfg.endpoint, 'root://srv');
        final db = _Database(cfg);
        child
            .register<_Database>(
              db,
              onRegister: Some((s) => s.init()),
              onUnregister: const Some(ServiceMixin.unregister),
            )
            .end();
        UNSAFE:
        (await child.untilSuper<_Database>().toAsync().value).unwrap();

        // Grandchild layer.
        final grand = child.child(groupEntity: UniqueEntity());
        UNSAFE:
        final dbFromGrand = grand.getSyncUnsafe<_Database>();
        expect(identical(dbFromGrand, db), isTrue);
        final auth = _AuthService(dbFromGrand);
        grand
            .register<_AuthService>(
              auth,
              onRegister: Some((s) => s.init()),
              onUnregister: const Some(ServiceMixin.unregister),
            )
            .end();
        UNSAFE:
        (await grand.untilSuper<_AuthService>().toAsync().value).unwrap();
        expect(auth.authenticated, isTrue);

        // Root cannot see child registrations.
        expect(root.isRegistered<_Database>(traverse: false), isFalse);
        expect(root.isRegistered<_AuthService>(traverse: false), isFalse);

        // Teardown grandchild then child.
        (await grand.unregister<_AuthService>().value).end();
        (await child.unregister<_Database>().value).end();
        expect(auth.state, ServiceState.DISPOSE_SUCCESS);
        expect(db.state, ServiceState.DISPOSE_SUCCESS);
      },
    );
  });

  // ── Repeated open/close ──────────────────────────────────────────────────
  group('repeated register/unregister cycles', () {
    test(
      'opening and closing a database service 50 times never lingers state',
      () async {
        final di = DI();
        di.register<_Config>(const _Config('cycle://srv')).end();
        UNSAFE:
        final cfg = di.getSyncUnsafe<_Config>();
        for (var n = 0; n < 50; n++) {
          final db = _Database(cfg);
          di
              .register<_Database>(
                db,
                onRegister: Some((s) => s.init()),
                onUnregister: const Some(ServiceMixin.unregister),
              )
              .end();
          UNSAFE:
          (await di.untilSuper<_Database>().toAsync().value).unwrap();
          expect(db.isOpen, isTrue);
          expect(db.openCount, 1);
          (await di.unregister<_Database>().value).end();
          expect(db.state, ServiceState.DISPOSE_SUCCESS);
          expect(db.closeCount, 1);
          expect(db.isOpen, isFalse);
        }
        // After 50 cycles, registry has no _Database left.
        expect(di.isRegistered<_Database>(), isFalse);
        expect(
          di.registry.groupsWithTypeK(
            TypeEntity(Sync, [TypeEntity(_Database)]),
          ),
          isEmpty,
        );
      },
    );
  });

  // ── Concurrent untilSuper waiters ────────────────────────────────────────
  group('concurrent waiters', () {
    test(
      '50 untilSuper waiters in parallel — all resolve when the dep is '
      'registered once',
      () async {
        final di = DI();
        di.register<_Config>(const _Config('para://srv')).end();
        UNSAFE:
        final cfg = di.getSyncUnsafe<_Config>();
        final futures = List.generate(
          50,
          (_) => di.untilSuper<_Database>().toAsync().value,
        );
        // Now register the database.
        final db = _Database(cfg);
        di
            .register<_Database>(
              db,
              onRegister: Some((s) => s.init()),
              onUnregister: const Some(ServiceMixin.unregister),
            )
            .end();
        final settled = await Future.wait(futures);
        UNSAFE:
        for (final r in settled) {
          expect(identical(r.unwrap(), db), isTrue);
        }
        // db's init must have completed for all 50 to observe it.
        expect(db.isOpen, isTrue);
        (await di.unregister<_Database>().value).end();
      },
    );
  });
}
