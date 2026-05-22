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

// Tests for `registerLazy` / `registerConstructor` and the strict-keying
// contract the review asked for: a `Lazy<T>` registration is keyed under
// `Lazy<T>` and is reachable ONLY via the explicit `<Lazy<T>>` / `Lazy`-aware
// APIs. Callers wanting to clean up a lazy use `unregisterLazy<T>()` (or
// `unregister<Lazy<T>>()`), not `unregister<T>()`.

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Test fixtures ───────────────────────────────────────────────────────────

final class Heavy {
  Heavy(this.id) {
    constructionCount++;
  }
  final int id;
  static int constructionCount = 0;

  static void resetCounter() => constructionCount = 0;
}

final class Repo {
  Repo(this.label);
  final String label;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  setUp(Heavy.resetCounter);

  group('registerLazy', () {
    test('Lazy<T> is not constructed until singleton is read', () {
      final di = DI();
      di.registerLazy<Heavy>(() => Sync.okValue(Heavy(1))).end();
      expect(Heavy.constructionCount, 0);

      UNSAFE:
      final lazy = di.getLazy<Heavy>().unwrap().sync().unwrap().unwrap();
      // Reading the registration alone does NOT construct.
      expect(Heavy.constructionCount, 0);

      // Reading the singleton DOES construct exactly once.
      UNSAFE:
      final v1 = lazy.singleton.sync().unwrap().value.unwrap();
      expect(Heavy.constructionCount, 1);
      expect(v1.id, 1);

      // A second read of the singleton reuses the same instance.
      UNSAFE:
      final v2 = lazy.singleton.sync().unwrap().value.unwrap();
      expect(Heavy.constructionCount, 1);
      expect(identical(v1, v2), isTrue);
    });

    test('registerConstructor exposes lazy + factory semantics', () {
      final di = DI();
      var counter = 0;
      di.registerConstructor<Repo>(() => Repo('r${++counter}')).end();

      // factory: each call constructs a fresh instance
      UNSAFE:
      final f1 = di.getFactory<Repo>().unwrap().sync().unwrap().unwrap();
      UNSAFE:
      final f2 = di.getFactory<Repo>().unwrap().sync().unwrap().unwrap();
      expect(f1.label, 'r1');
      expect(f2.label, 'r2');
      expect(identical(f1, f2), isFalse);

      // singleton: stable instance after first read
      UNSAFE:
      final s1 = di.getLazySingleton<Repo>().unwrap().sync().unwrap().unwrap();
      UNSAFE:
      final s2 = di.getLazySingleton<Repo>().unwrap().sync().unwrap().unwrap();
      expect(identical(s1, s2), isTrue);
    });

    test('resetLazySingleton drops cached instance', () {
      final di = DI();
      var counter = 0;
      di.registerLazy<Repo>(() => Sync.okValue(Repo('r${++counter}'))).end();

      UNSAFE:
      final a = di.getLazySingleton<Repo>().unwrap().sync().unwrap().unwrap();
      expect(a.label, 'r1');

      di.resetLazySingleton<Repo>().end();

      UNSAFE:
      final b = di.getLazySingleton<Repo>().unwrap().sync().unwrap().unwrap();
      expect(b.label, 'r2');
      expect(identical(a, b), isFalse);
    });
  });

  group('strict keying contract', () {
    test(
      'Lazy<T> registration is reachable only via Lazy<T>-aware APIs',
      () {
        final di = DI();
        di.registerLazy<Repo>(() => Sync.okValue(Repo('lazy'))).end();

        // Direct <T> probe DOES NOT see the lazy registration.
        expect(di.isRegistered<Repo>(), isFalse);
        // Direct <Lazy<T>> probe DOES see it.
        expect(di.isRegistered<Lazy<Repo>>(), isTrue);
      },
    );

    test('unregisterLazy<T>() removes a Lazy<T> registration', () async {
      final di = DI();
      di.registerLazy<Repo>(() => Sync.okValue(Repo('lazy'))).end();
      expect(di.isRegistered<Lazy<Repo>>(), isTrue);

      (await di.unregisterLazy<Repo>().toAsync().value).end();

      expect(di.isRegistered<Lazy<Repo>>(), isFalse);
    });

    test('unregister<T>() does NOT remove a Lazy<T> registration', () async {
      final di = DI();
      di.registerLazy<Repo>(() => Sync.okValue(Repo('lazy'))).end();

      // <T> probe finds nothing (strict), so unregister<T>() is a no-op.
      UNSAFE:
      final removed = await di.unregister<Repo>().unwrap();
      expect(removed.isNone(), isTrue);

      // Lazy<Repo> survives — caller has to use the explicit lazy API.
      expect(di.isRegistered<Lazy<Repo>>(), isTrue);
    });

    test(
      'direct <T> and Lazy<T> registrations coexist and remove independently',
      () async {
        final di = DI();
        di.register<Repo>(Repo('direct')).end();
        di.registerLazy<Repo>(() => Sync.okValue(Repo('lazy'))).end();

        expect(di.isRegistered<Repo>(), isTrue);
        expect(di.isRegistered<Lazy<Repo>>(), isTrue);

        // Removing direct leaves the lazy untouched.
        UNSAFE:
        (await di.unregister<Repo>().unwrap()).end();
        expect(di.isRegistered<Repo>(), isFalse);
        expect(di.isRegistered<Lazy<Repo>>(), isTrue);

        // And vice versa.
        (await di.unregisterLazy<Repo>().toAsync().value).end();
        expect(di.isRegistered<Lazy<Repo>>(), isFalse);
      },
    );
  });

  group('untilLazySingleton', () {
    test('resolves to the singleton when registered after the wait', () async {
      final di = DI();
      UNSAFE:
      final waiter = di.untilLazySingletonSuper<Repo>().unwrap();

      unawaited(
        Future<void>.microtask(() {
          di.registerLazy<Repo>(() => Sync.okValue(Repo('built'))).end();
        }),
      );

      final repo = await waiter;
      expect(repo.label, 'built');
    });
  });
}
