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

// Tests for the unsafe + sync-or-none accessors on the lazy / factory APIs.
// These are commonly-used convenience entry points whose throw-on-missing
// behaviour callers rely on (e.g. service-locator-style call sites).

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

final class Item {
  Item(this.tag);
  final String tag;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('getLazySingletonUnsafe', () {
    test('returns the singleton when registered', () {
      final di = DI();
      di.registerLazy<Item>(() => Sync.okValue(Item('s'))).end();

      UNSAFE:
      final item = di.getLazySingletonUnsafe<Item>() as Item;
      expect(item.tag, 's');
    });

    test('returns same instance across calls', () {
      final di = DI();
      var counter = 0;
      di.registerLazy<Item>(() => Sync.okValue(Item('s${++counter}'))).end();

      UNSAFE:
      final a = di.getLazySingletonUnsafe<Item>() as Item;
      UNSAFE:
      final b = di.getLazySingletonUnsafe<Item>() as Item;
      expect(identical(a, b), isTrue);
    });
  });

  group('getFactoryUnsafe', () {
    test('returns a fresh instance per call', () {
      final di = DI();
      var counter = 0;
      di.registerConstructor<Item>(() => Item('f${++counter}')).end();

      UNSAFE:
      final a = di.getFactoryUnsafe<Item>() as Item;
      UNSAFE:
      final b = di.getFactoryUnsafe<Item>() as Item;
      expect(a.tag, 'f1');
      expect(b.tag, 'f2');
      expect(identical(a, b), isFalse);
    });
  });

  group('getLazySingletonSyncOrNone', () {
    test('Some on a registered lazy', () {
      final di = DI();
      di.registerLazy<Item>(() => Sync.okValue(Item('present'))).end();

      final result = di.getLazySingletonSyncOrNone<Item>();
      expect(result.isSome(), isTrue);
      UNSAFE:
      expect(result.unwrap().tag, 'present');
    });

    test('None when nothing is registered', () {
      final di = DI();
      expect(di.getLazySingletonSyncOrNone<Item>().isNone(), isTrue);
    });
  });

  group('getFactorySyncOrNone', () {
    test('Some on a registered factory', () {
      final di = DI();
      di.registerConstructor<Item>(() => Item('factory')).end();

      final result = di.getFactorySyncOrNone<Item>();
      expect(result.isSome(), isTrue);
      UNSAFE:
      expect(result.unwrap().tag, 'factory');
    });

    test('None when nothing is registered', () {
      final di = DI();
      expect(di.getFactorySyncOrNone<Item>().isNone(), isTrue);
    });
  });
}
