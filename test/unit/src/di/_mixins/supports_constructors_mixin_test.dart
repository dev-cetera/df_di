// ignore_for_file: sendable

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

// Tests targeted at `SupportsConstructorsMixin`: registerLazy /
// registerConstructor / unregisterLazy / getLazy{,SyncOrNone,Unsafe} /
// untilLazySuper / untilLazy / resetLazySingleton / getLazySingleton{,...} /
// getFactory{,...} / untilFactorySuper / untilFactory. The mixin only exposes
// generic-typed (`<T>`) entry points — T/K-keyed wrappers live in their own
// mixins and have their own test files.

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

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
    test('does not construct value until singleton is read', () {
      final di = DI();
      di.registerLazy<Heavy>(() => Sync.okValue(Heavy(7))).end();
      expect(Heavy.constructionCount, 0);

      UNSAFE:
      final lazy = di.getLazy<Heavy>().unwrap().sync().unwrap().unwrap();
      expect(Heavy.constructionCount, 0);

      UNSAFE:
      final v = lazy.singleton.sync().unwrap().value.unwrap();
      expect(Heavy.constructionCount, 1);
      expect(v.id, 7);
    });

    test('registerLazy returns a Resolvable<Lazy<T>>', () {
      final di = DI();
      final r = di.registerLazy<Repo>(() => Sync.okValue(Repo('a')));
      expect(r, isA<Resolvable<Lazy<Repo>>>());
    });
  });

  group('registerConstructor', () {
    test('exposes lazy + factory semantics', () {
      final di = DI();
      var counter = 0;
      di.registerConstructor<Repo>(() => Repo('r${++counter}')).end();

      UNSAFE:
      final f1 = di.getFactory<Repo>().unwrap().sync().unwrap().unwrap();
      UNSAFE:
      final f2 = di.getFactory<Repo>().unwrap().sync().unwrap().unwrap();
      expect(f1.label, 'r1');
      expect(f2.label, 'r2');
      expect(identical(f1, f2), isFalse);

      UNSAFE:
      final s1 = di.getLazySingleton<Repo>().unwrap().sync().unwrap().unwrap();
      UNSAFE:
      final s2 = di.getLazySingleton<Repo>().unwrap().sync().unwrap().unwrap();
      expect(identical(s1, s2), isTrue);
    });
  });

  group('getLazy variants', () {
    test('getLazySyncOrNone returns None when unregistered', () {
      final di = DI();
      expect(di.getLazySyncOrNone<Repo>().isNone(), isTrue);
    });

    test('getLazySyncOrNone returns Some(Lazy<T>) when registered', () {
      final di = DI();
      di.registerLazy<Repo>(() => Sync.okValue(Repo('x'))).end();
      final out = di.getLazySyncOrNone<Repo>();
      expect(out.isSome(), isTrue);
    });

    test('getLazySingletonSyncOrNone returns None when unregistered', () {
      final di = DI();
      expect(di.getLazySingletonSyncOrNone<Repo>().isNone(), isTrue);
    });

    test('getLazySingletonSyncOrNone returns Some after singleton is read', () {
      final di = DI();
      di.registerLazy<Repo>(() => Sync.okValue(Repo('s'))).end();
      // Force singleton construction.
      di.getLazySingleton<Repo>().end();
      UNSAFE:
      final v = di.getLazySingletonSyncOrNone<Repo>().unwrap();
      expect(v.label, 's');
    });
  });

  group('unregisterLazy', () {
    test('unregisterLazy<T> removes a Lazy<T> registration', () async {
      final di = DI();
      di.registerLazy<Repo>(() => Sync.okValue(Repo('lazy'))).end();
      expect(di.isRegistered<Lazy<Repo>>(), isTrue);
      (await di.unregisterLazy<Repo>().toAsync().value).end();
      expect(di.isRegistered<Lazy<Repo>>(), isFalse);
    });
  });

  group('resetLazySingleton', () {
    test('drops cached instance so next read constructs a fresh one', () {
      final di = DI();
      var n = 0;
      di.registerLazy<Repo>(() => Sync.okValue(Repo('r${++n}'))).end();

      UNSAFE:
      final a = di.getLazySingleton<Repo>().unwrap().sync().unwrap().unwrap();
      expect(a.label, 'r1');

      di.resetLazySingleton<Repo>().end();

      UNSAFE:
      final b = di.getLazySingleton<Repo>().unwrap().sync().unwrap().unwrap();
      expect(b.label, 'r2');
      expect(identical(a, b), isFalse);
    });

    test('resetLazySingleton on unregistered type returns syncUnit', () {
      final di = DI();
      final r = di.resetLazySingleton<Repo>();
      expect(r.isSync(), isTrue);
    });
  });

  group('untilLazySingleton / untilLazySingletonSuper', () {
    test('resolves to the singleton when registered after the wait', () async {
      final di = DI();
      UNSAFE:
      final waiter = di.untilLazySingletonSuper<Repo>().unwrap();

      unawaited(
        Future<void>.microtask(() {
          di.registerLazy<Repo>(() => Sync.okValue(Repo('done'))).end();
        }),
      );

      final repo = await waiter;
      expect(repo.label, 'done');
    });
  });

  group('untilFactory / untilFactorySuper', () {
    test('resolves to a freshly-constructed factory instance', () async {
      final di = DI();
      UNSAFE:
      final waiter = di.untilFactorySuper<Repo>().unwrap();

      unawaited(
        Future<void>.microtask(() {
          di.registerLazy<Repo>(() => Sync.okValue(Repo('fac'))).end();
        }),
      );

      final repo = await waiter;
      expect(repo.label, 'fac');
    });
  });
}
