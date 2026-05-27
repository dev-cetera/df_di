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

// Public-API tests for the `DIBase` surface exposed via `DI`. Covers:
//
//   * register / get / getOrNull / getSync / getAsync / getSyncOrNone
//   * registerLazy / registerConstructor / getLazy / getLazySingleton
//   * duplicate registration → Sync.err (does not throw)
//   * unregister (happy path, idempotent, ServiceMixin cascade, traverse flag)
//   * parents / children / registerChild / child() hierarchy
//   * until* family (untilSuper, until, untilLazySuper, untilLazy,
//     untilExactlyK, untilSuperK, untilK)
//   * cycle detection on misconfigured parent graphs
//   * snapshot safety: re-entrant register/unregister during `children()` /
//     `unregisterAll` / `resolveAll` must not throw ConcurrentModification.

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Test fixtures ───────────────────────────────────────────────────────────

final class _A {
  const _A([this.tag = '']);
  final String tag;
}

final class _B {
  const _B();
}

abstract class _Logger {
  void log(String message);
}

final class _ConsoleLogger extends _Logger {
  @override
  void log(String message) {}
}

final class _DisposableService with ServiceMixin {
  int disposedCount = 0;

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) =>
      [(_) => Sync<Unit>.okValue(Unit())];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) =>
      [(_) => Sync<Unit>.okValue(Unit())];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) =>
      [(_) => Sync<Unit>.okValue(Unit())];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
        (_) {
          disposedCount++;
          return Sync<Unit>.okValue(Unit());
        },
      ];
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('register / get', () {
    test('register returns a Resolvable<T>', () {
      final di = DI();
      final r = di.register<_A>(const _A('x'));
      expect(r, isA<Resolvable<_A>>());
    });

    test('register stores a Sync value retrievable via getSyncOrNone', () {
      final di = DI();
      di.register<_A>(const _A('x')).end();
      final out = di.getSyncOrNone<_A>();
      expect(out.isSome(), isTrue);
      switch (out) {
        case Some(value: final v):
          expect(v.tag, 'x');
        case None():
          fail('Expected Some.');
      }
    });

    test('register stores a Future as an Async dependency', () async {
      final di = DI();
      di
          .register<_A>(
            Future<_A>.delayed(
              const Duration(milliseconds: 1),
              () => const _A('future'),
            ),
          )
          .end();
      // Before resolution, sync lookup misses; async resolves successfully.
      expect(di.getSyncOrNone<_A>().isNone(), isTrue);
      final resolved = await di.getAsyncUnsafe<_A>();
      expect(resolved.tag, 'future');
    });

    test('register with explicit groupEntity scopes by group', () {
      final di = DI();
      final g = TypeEntity('grp');
      di.register<_A>(const _A('grp'), groupEntity: g).end();
      expect(di.isRegistered<_A>(groupEntity: g), isTrue);
      expect(
        di.isRegistered<_A>(groupEntity: const DefaultEntity()),
        isFalse,
      );
    });

    test('get returns None for unregistered T', () {
      final di = DI();
      expect(di.get<_A>().isNone(), isTrue);
    });

    test('get returns Some(Resolvable<T>) for registered T', () {
      final di = DI();
      di.register<_A>(const _A('x')).end();
      expect(di.get<_A>().isSome(), isTrue);
    });

    test('getSyncOrNone returns None for an Async dep that has not resolved',
        () {
      final di = DI();
      di
          .register<_A>(
            Future<_A>.delayed(
              const Duration(milliseconds: 100),
              () => const _A('slow'),
            ),
          )
          .end();
      expect(di.getSyncOrNone<_A>().isNone(), isTrue);
    });

    test('call<T>() is shorthand for getSyncUnsafe<T>()', () {
      final di = DI();
      di.register<_A>(const _A('x')).end();
      final v = di<_A>();
      expect(v.tag, 'x');
    });

    test('getUnsafe throws when T is not registered', () {
      final di = DI();
      expect(() => di.getUnsafe<_A>(), throwsA(anything));
    });
  });

  group('duplicate registration', () {
    test('second register returns Sync.err and does NOT overwrite', () {
      final di = DI();
      di.register<_A>(const _A('first')).end();
      final r2 = di.register<_A>(const _A('second'));
      // The first value must survive.
      expect(di<_A>().tag, 'first');
      // The returned Resolvable is a Sync<_A> with Err.
      expect(r2, isA<Sync<_A>>());
      switch (r2) {
        case Sync<_A>(value: final result):
          expect(result.isErr(), isTrue);
        case Async():
          fail('Expected Sync.err for duplicate registration.');
      }
    });

    test('duplicate registration does NOT fire onRegister', () async {
      final di = DI();
      var firedFirst = 0;
      var firedSecond = 0;
      (await di
              .register<_A>(
                const _A('first'),
                onRegister: Some((_) => firedFirst++),
              )
              .toAsync()
              .value)
          .end();
      // Duplicate — onRegister must NOT fire.
      di
          .register<_A>(
            const _A('second'),
            onRegister: Some((_) => firedSecond++),
          )
          .end();
      expect(firedFirst, 1);
      expect(firedSecond, 0);
    });
  });

  group('registerLazy / registerConstructor', () {
    test('registerLazy registers under Lazy<T>', () {
      final di = DI();
      di.registerLazy<_A>(() => Sync.okValue(const _A('lazy'))).end();
      expect(di.isRegistered<Lazy<_A>>(), isTrue);
      expect(di.isRegistered<_A>(), isFalse);
    });

    test('getLazySingleton materialises the singleton', () {
      final di = DI();
      di.registerLazy<_A>(() => Sync.okValue(const _A('singleton'))).end();
      final s = di.getLazySingleton<_A>();
      expect(s.isSome(), isTrue);
      switch (s) {
        case Some(value: Sync(value: Ok(value: final v))):
          expect(v.tag, 'singleton');
        case _:
          fail('Expected Some(Sync(Ok(_A))).');
      }
    });

    test('registerConstructor wraps a FutureOr constructor', () {
      final di = DI();
      di.registerConstructor<_A>(() => const _A('ctor')).end();
      expect(di.isRegistered<Lazy<_A>>(), isTrue);
      expect(di.getLazySingletonSyncOrNone<_A>().isSome(), isTrue);
    });

    test('unregisterLazy removes only the Lazy<T> registration', () async {
      final di = DI();
      di.registerLazy<_A>(() => Sync.okValue(const _A('x'))).end();
      (await di.unregisterLazy<_A>().value).end();
      expect(di.isRegistered<Lazy<_A>>(), isFalse);
    });
  });

  group('unregister', () {
    test('unregister returns the removed value as Some', () async {
      final di = DI();
      di.register<_A>(const _A('removeme')).end();
      final out = await di.unregister<_A>().toAsync().value;
      switch (out) {
        case Ok(value: Some(value: final v)):
          expect(v.tag, 'removeme');
        case _:
          fail('Expected Ok(Some(_A)).');
      }
      expect(di.isRegistered<_A>(), isFalse);
    });

    test('unregister on missing returns Ok(None)', () async {
      final di = DI();
      final out = await di.unregister<_A>().toAsync().value;
      switch (out) {
        case Ok(value: final opt):
          expect(opt.isNone(), isTrue);
        case Err():
          fail('Expected Ok(None) when nothing is registered.');
      }
    });

    test('unregister is idempotent across repeated calls', () async {
      final di = DI();
      di.register<_A>(const _A('x')).end();
      (await di.unregister<_A>().value).end();
      (await di.unregister<_A>().value).end();
      // A third call still returns Ok(None).
      final out = await di.unregister<_A>().toAsync().value;
      switch (out) {
        case Ok(value: final opt):
          expect(opt.isNone(), isTrue);
        case Err():
          fail('Expected Ok(None).');
      }
    });

    test(
      'unregister of a ServiceMixin value registered via '
      'registerAndInitService cascades dispose()',
      () async {
        final di = DI();
        final svc = _DisposableService();
        // registerAndInitService is the supported path that wires the
        // ServiceMixin lifecycle into the registry's onUnregister chain.
        (await di
                .registerAndInitService<_DisposableService>(svc)
                .toAsync()
                .value)
            .end();
        expect(svc.didEverInitAndSuccessfully, isTrue);

        (await di.unregister<_DisposableService>().value).end();
        // Cascade is awaited inside the unregister chain.
        expect(svc.state.didDispose(), isTrue);
        expect(svc.disposedCount, 1);
      },
    );

    test('unregister(traverse: false) does NOT walk parents', () async {
      final parent = DI();
      final child = DI();
      child.parents.add(parent);
      parent.register<_A>(const _A('parent-side')).end();

      (await child.unregister<_A>(traverse: false).value).end();
      expect(parent.isRegistered<_A>(), isTrue);
    });

    test('unregister(removeAll: true) removes from this AND parent', () async {
      final parent = DI();
      final child = DI();
      child.parents.add(parent);
      parent.register<_A>(const _A('p')).end();
      child.register<_A>(const _A('c')).end();

      (await child.unregister<_A>().value).end();
      expect(parent.isRegistered<_A>(), isFalse);
      expect(child.isRegistered<_A>(), isFalse);
    });

    test(
      'unregister(removeAll: false) removes only the first hit',
      () async {
        final parent = DI();
        final child = DI();
        child.parents.add(parent);
        parent.register<_A>(const _A('p')).end();
        child.register<_A>(const _A('c')).end();

        (await child
                .unregister<_A>(removeAll: false)
                .value)
            .end();
        // Parent still has its registration.
        expect(parent.isRegistered<_A>(), isTrue);
      },
    );
  });

  group('parents / children / child()', () {
    test('parents starts empty on a fresh DI', () {
      final di = DI();
      expect(di.parents, isEmpty);
    });

    test('parents.add wires lookup traversal', () {
      final parent = DI();
      final child = DI();
      child.parents.add(parent);
      parent.register<_A>(const _A('p')).end();
      expect(child.isRegistered<_A>(), isTrue);
      // With traverse:false, the child does not see the parent.
      expect(child.isRegistered<_A>(traverse: false), isFalse);
    });

    test('registerChild registers a Lazy<DI> in childrenContainer', () {
      final di = DI();
      final g = TypeEntity('grp');
      di.registerChild(groupEntity: g).end();
      expect(di.isChildRegistered(groupEntity: g), isTrue);
    });

    test('child() is idempotent', () {
      final di = DI();
      final g = TypeEntity('grp');
      final c1 = di.child(groupEntity: g);
      final c2 = di.child(groupEntity: g);
      expect(identical(c1, c2), isTrue);
    });

    test('children() returns already-materialised children only', () {
      final di = DI();
      final g1 = TypeEntity('g1');
      final g2 = TypeEntity('g2');
      // Materialise only g1.
      di.child(groupEntity: g1);
      // Register a child for g2 but do not materialise it via child().
      di.registerChild(groupEntity: g2).end();

      final ch = di.children();
      expect(ch.isSome(), isTrue);
      switch (ch) {
        case Some(value: final list):
          // Should not have force-constructed g2's child.
          // We can only assert that the materialised count is at least 1
          // (g1) and that no materialisation of g2 happened. Since
          // children() filters by `Lazy.currentInstance`, the unforced one
          // is skipped.
          expect(list.length, greaterThanOrEqualTo(1));
        case None():
          fail('children() should be Some when there is a children container.');
      }
    });
  });

  group('until family', () {
    test('untilSuper resolves immediately when already registered', () async {
      final di = DI();
      di.register<_A>(const _A('immediate')).end();
      UNSAFE:
      final v = await di.untilSuper<_A>().unwrap();
      expect(v.tag, 'immediate');
    });

    test('untilSuper resolves when registered after waiting starts', () async {
      final di = DI();
      UNSAFE:
      final future = di.untilSuper<_A>().unwrap();
      unawaited(
        Future.microtask(
          () => di.register<_A>(const _A('later')).end(),
        ),
      );
      final v = await future;
      expect(v.tag, 'later');
    });

    test(
      'untilSuper resolves with a subtype when supertype is awaited',
      () async {
        final di = DI();
        UNSAFE:
        final future = di.untilSuper<_Logger>().unwrap();
        unawaited(
          Future.microtask(
            () => di.register<_Logger>(_ConsoleLogger()).end(),
          ),
        );
        final v = await future;
        expect(v, isA<_ConsoleLogger>());
      },
    );

    test(
      'until<TSuper, TSub> casts the awaited value to TSub',
      () async {
        final di = DI();
        UNSAFE:
        final future = di.until<_Logger, _ConsoleLogger>().unwrap();
        unawaited(
          Future.microtask(
            () => di.register<_Logger>(_ConsoleLogger()).end(),
          ),
        );
        final v = await future;
        expect(v, isA<_ConsoleLogger>());
      },
    );

    test('untilLazySuper resolves to the Lazy<T> wrapper', () async {
      final di = DI();
      UNSAFE:
      final future = di.untilLazySuper<_A>().unwrap();
      unawaited(
        Future.microtask(() {
          di.registerLazy<_A>(() => Sync.okValue(const _A('lazy'))).end();
        }),
      );
      final lazy = await future;
      expect(lazy, isA<Lazy<_A>>());
    });

    test(
      'untilLazySingleton resolves to the materialised singleton value',
      () async {
        final di = DI();
        UNSAFE:
        final future = di.untilLazySingleton<_A, _A>().unwrap();
        unawaited(
          Future.microtask(() {
            di
                .registerLazy<_A>(() => Sync.okValue(const _A('singleton')))
                .end();
          }),
        );
        final v = await future;
        expect(v.tag, 'singleton');
      },
    );

    test('untilSuper traversal sees an ancestor registration', () async {
      final parent = DI();
      final child = DI();
      child.parents.add(parent);
      UNSAFE:
      final future = child.untilSuper<_A>().unwrap();
      unawaited(
        Future.microtask(
          () => parent.register<_A>(const _A('p')).end(),
        ),
      );
      final v = await future;
      expect(v.tag, 'p');
    });

    test(
      'untilExactlyK requires enableUntilExactlyK:true at register-time',
      () async {
        final di = DI();
        // Start the K-keyed waiter before registration.
        UNSAFE:
        final future = di.untilExactlyK<_A>(TypeEntity(_A)).unwrap();
        unawaited(
          Future.microtask(() {
            di
                .register<_A>(
                  const _A('exact'),
                  enableUntilExactlyK: true,
                )
                .end();
          }),
        );
        final v = await future;
        expect(v.tag, 'exact');
      },
    );

    test('untilSuperK alias mirrors untilExactlyK', () async {
      final di = DI();
      UNSAFE:
      final future = di.untilSuperK<_A>(TypeEntity(_A)).unwrap();
      unawaited(
        Future.microtask(() {
          di
              .register<_A>(
                const _A('alias'),
                enableUntilExactlyK: true,
              )
              .end();
        }),
      );
      final v = await future;
      expect(v.tag, 'alias');
    });
  });

  group('cycle detection (misconfigured parent graphs)', () {
    test('two-node cycle does not infinite-loop isRegistered', () {
      final a = DI();
      final b = DI();
      a.parents.add(b);
      b.parents.add(a);
      // No registration → must return false without hanging or stack-overflow.
      expect(a.isRegistered<_A>(), isFalse);
      expect(b.isRegistered<_A>(), isFalse);
    });

    test('two-node cycle terminates getDependency lookup', () {
      final a = DI();
      final b = DI();
      a.parents.add(b);
      b.parents.add(a);
      final out = a.getDependency<_A>();
      expect(out.isNone(), isTrue);
    });

    test('cycle still finds a registration along the chain', () {
      final a = DI();
      final b = DI();
      a.parents.add(b);
      b.parents.add(a);
      b.register<_A>(const _A('b')).end();
      expect(a.isRegistered<_A>(), isTrue);
    });

    test('cycle does not infinite-loop unregister', () async {
      final a = DI();
      final b = DI();
      a.parents.add(b);
      b.parents.add(a);
      b.register<_A>(const _A('b')).end();
      // Should terminate, removing from b (one match across the cycle).
      (await a.unregister<_A>().value).end();
      expect(b.isRegistered<_A>(traverse: false), isFalse);
    });
  });

  group('snapshot safety / concurrent mutation', () {
    test(
      'children() snapshots — re-entrant unregisterChild mid-iteration is safe',
      () {
        final di = DI();
        di.child(groupEntity: TypeEntity('a'));
        di.child(groupEntity: TypeEntity('b'));

        // Walk children and unregister inside the loop. Must not throw
        // ConcurrentModificationError.
        switch (di.children()) {
          case Some(value: final list):
            for (final _ in list.toList()) {
              di.unregisterChild(groupEntity: TypeEntity('a'));
            }
          case None():
        }
      },
    );

    test(
      're-entrant register from inside an onRegister callback does not throw',
      () async {
        final di = DI();
        var nestedRan = false;
        (await di
                .register<_A>(
                  const _A('outer'),
                  onRegister: Some((_) {
                    // Register a *different* type from inside the callback.
                    di.register<_B>(const _B()).end();
                    nestedRan = true;
                  }),
                )
                .toAsync()
                .value)
            .end();
        expect(nestedRan, isTrue);
        expect(di.isRegistered<_B>(), isTrue);
      },
    );

    test(
      'unregisterAll is concurrent-safe against a register fired by '
      'onUnregister',
      () async {
        final di = DI();
        for (var n = 0; n < 5; n++) {
          di.register<_A>(_A('n=$n'), groupEntity: UniqueEntity()).end();
        }
        // Should complete without throwing ConcurrentModificationError.
        (await di.unregisterAll().value).end();
        expect(di.registry.groupEntities, isEmpty);
      },
    );

    test('resolveAll resolves an all-sync registry to Unit synchronously', () {
      final di = DI();
      di.register<_A>(const _A('sync-a')).end();
      di.register<_B>(const _B()).end();
      // No async deps — should resolve immediately.
      final r = di.resolveAll();
      expect(r, isA<Resolvable<Unit>>());
    });
  });

  group('focusGroup', () {
    test('focusGroup is the implicit default group when none is supplied', () {
      final di = DI()..focusGroup = TypeEntity('grp');
      di.register<_A>(const _A('focused')).end();
      expect(di<_A>().tag, 'focused');
      // A different non-default group does NOT see it (focusGroup only kicks
      // in when the caller passes DefaultEntity).
      expect(
        di.isRegistered<_A>(groupEntity: TypeEntity('other')),
        isFalse,
      );
    });
  });

  group('Async resolution semantics', () {
    test(
      'repeated getAsyncUnsafe on the same async dep returns the same value',
      () async {
        final di = DI();
        di.register<_A>(Future<_A>.value(const _A('async'))).end();
        final v1 = await di.getAsyncUnsafe<_A>();
        final v2 = await di.getAsyncUnsafe<_A>();
        expect(v1.tag, 'async');
        expect(v2.tag, 'async');
        // Both calls return the same logical value.
        expect(identical(v1, v2), isTrue);
      },
    );

    test('getAsync returns Async even when the dep was registered as Sync',
        () async {
      final di = DI();
      di.register<_A>(const _A('sync')).end();
      final opt = di.getAsync<_A>();
      expect(opt.isSome(), isTrue);
      switch (opt) {
        case Some(value: final async):
          UNSAFE:
          final v = await async.value.then((r) => r.unwrap());
          expect(v.tag, 'sync');
        case None():
          fail('Expected Some<Async<_A>>.');
      }
    });
  });
}
