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

// Tests for DI container basics: register, retrieve, isRegistered, unregister.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Test fixtures ───────────────────────────────────────────────────────────

final class DatabaseService {
  DatabaseService(this.connectionString);
  final String connectionString;
}

final class CacheService {
  CacheService(this.maxItems);
  final int maxItems;
}

abstract class Logger {
  void log(String message);
}

final class ConsoleLogger extends Logger {
  @override
  void log(String message) {}
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('DI register and retrieve', () {
    test('register and retrieve a sync value', () {
      final di = DI();
      di.register<DatabaseService>(
        DatabaseService('sqlite://test.db'),
      ).end();

      final result = di.getSyncOrNone<DatabaseService>();
      expect(result.isSome(), isTrue);
      expect(result.unwrap().connectionString, 'sqlite://test.db');
    });

    test('getSyncOrNone returns None for unregistered type', () {
      final di = DI();
      final result = di.getSyncOrNone<CacheService>();
      expect(result.isNone(), isTrue);
    });

    test('isRegistered returns true after registration', () {
      final di = DI();
      di.register<DatabaseService>(
        DatabaseService('postgres://localhost'),
      ).end();
      expect(di.isRegistered<DatabaseService>(), isTrue);
    });

    test('isRegistered returns false before registration', () {
      final di = DI();
      expect(di.isRegistered<DatabaseService>(), isFalse);
    });

    test('duplicate registration does not overwrite the first', () {
      final di = DI();
      di.register<DatabaseService>(
        DatabaseService('first'),
      ).end();

      // Second registration of the same type — the original should survive.
      di.register<DatabaseService>(
        DatabaseService('second'),
      ).end();

      // The first registered value should still be in place.
      final result = di.getSyncOrNone<DatabaseService>();
      expect(result.unwrap().connectionString, 'first');
    });

    test('call<T>() returns the registered value directly', () {
      final di = DI();
      di.register<CacheService>(CacheService(100)).end();
      final cache = di<CacheService>();
      expect(cache.maxItems, 100);
    });
  });

  group('DI unregister', () {
    test('unregister removes the dependency', () async {
      final di = DI();
      di.register<DatabaseService>(
        DatabaseService('to-be-removed'),
      ).end();
      expect(di.isRegistered<DatabaseService>(), isTrue);

      await di.unregister<DatabaseService>().unwrap();
      expect(di.isRegistered<DatabaseService>(), isFalse);
    });

    test('getSyncOrNone returns None after unregister', () async {
      final di = DI();
      di.register<CacheService>(CacheService(50)).end();
      await di.unregister<CacheService>().unwrap();

      final result = di.getSyncOrNone<CacheService>();
      expect(result.isNone(), isTrue);
    });
  });

  group('DI untilSuper — already registered', () {
    test('resolves immediately when already registered', () async {
      final di = DI();
      di.register<DatabaseService>(
        DatabaseService('immediate'),
      ).end();

      final service = await di.untilSuper<DatabaseService>().unwrap();
      expect(service.connectionString, 'immediate');
    });

    test('resolves when registered after the await starts', () async {
      final di = DI();

      // Start waiting before registration.
      final future = di.untilSuper<CacheService>().unwrap();

      // Register after a microtask delay.
      Future.microtask(() {
        di.register<CacheService>(CacheService(200)).end();
      });

      final service = await future;
      expect(service.maxItems, 200);
    });

    test('resolves subtype via untilSuper for supertype', () async {
      final di = DI();

      final future = di.untilSuper<Logger>().unwrap();

      Future.microtask(() {
        di.register<Logger>(ConsoleLogger()).end();
      });

      final logger = await future;
      expect(logger, isA<ConsoleLogger>());
    });
  });

  group('DI multiple independent containers', () {
    test('two DI instances are isolated', () {
      final diA = DI();
      final diB = DI();

      diA.register<DatabaseService>(
        DatabaseService('dbA'),
      ).end();

      expect(diA.isRegistered<DatabaseService>(), isTrue);
      expect(diB.isRegistered<DatabaseService>(), isFalse);
    });
  });
}
