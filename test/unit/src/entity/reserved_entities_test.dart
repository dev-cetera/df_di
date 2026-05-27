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

// Tests for the reserved group entities — the const-constructible singletons
// (`DefaultEntity`, `GlobalEntity`, `SessionEntity`, `UserEntity`,
// `ThemeEntity`, `ProdEntity`, `DevEntity`, `TestEntity`) whose ids form
// the -1001..-1008 reserved block. Only `DefaultEntity` is "the" default —
// every other reserved entity must report `isDefault() == false`.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('Reserved entity ids', () {
    test('DefaultEntity has id -1001', () {
      expect(const DefaultEntity().id, equals(-1001));
    });

    test('GlobalEntity has id -1002', () {
      expect(const GlobalEntity().id, equals(-1002));
    });

    test('SessionEntity has id -1003', () {
      expect(const SessionEntity().id, equals(-1003));
    });

    test('UserEntity has id -1004', () {
      expect(const UserEntity().id, equals(-1004));
    });

    test('ThemeEntity has id -1005', () {
      expect(const ThemeEntity().id, equals(-1005));
    });

    test('ProdEntity has id -1006', () {
      expect(const ProdEntity().id, equals(-1006));
    });

    test('DevEntity has id -1007', () {
      expect(const DevEntity().id, equals(-1007));
    });

    test('TestEntity has id -1008', () {
      expect(const TestEntity().id, equals(-1008));
    });
  });

  group('Reserved entities are const-constructible and self-equal', () {
    test('const DefaultEntity() == const DefaultEntity()', () {
      expect(const DefaultEntity(), equals(const DefaultEntity()));
    });

    test('const GlobalEntity() == const GlobalEntity()', () {
      expect(const GlobalEntity(), equals(const GlobalEntity()));
    });

    test('const SessionEntity() == const SessionEntity()', () {
      expect(const SessionEntity(), equals(const SessionEntity()));
    });

    test('const UserEntity() == const UserEntity()', () {
      expect(const UserEntity(), equals(const UserEntity()));
    });

    test('const ThemeEntity() == const ThemeEntity()', () {
      expect(const ThemeEntity(), equals(const ThemeEntity()));
    });

    test('const ProdEntity() == const ProdEntity()', () {
      expect(const ProdEntity(), equals(const ProdEntity()));
    });

    test('const DevEntity() == const DevEntity()', () {
      expect(const DevEntity(), equals(const DevEntity()));
    });

    test('const TestEntity() == const TestEntity()', () {
      expect(const TestEntity(), equals(const TestEntity()));
    });
  });

  group('Reserved entities are pairwise distinct', () {
    test('every reserved entity has a unique id distinct from the others', () {
      final entities = <Entity>[
        const DefaultEntity(),
        const GlobalEntity(),
        const SessionEntity(),
        const UserEntity(),
        const ThemeEntity(),
        const ProdEntity(),
        const DevEntity(),
        const TestEntity(),
      ];
      final ids = entities.map((e) => e.id).toSet();
      expect(ids.length, equals(entities.length));
    });

    test('DefaultEntity is NOT equal to GlobalEntity', () {
      expect(const DefaultEntity(), isNot(equals(const GlobalEntity())));
    });

    test('SessionEntity is NOT equal to UserEntity', () {
      expect(const SessionEntity(), isNot(equals(const UserEntity())));
    });

    test('ProdEntity is NOT equal to DevEntity', () {
      expect(const ProdEntity(), isNot(equals(const DevEntity())));
    });

    test('DevEntity is NOT equal to TestEntity', () {
      expect(const DevEntity(), isNot(equals(const TestEntity())));
    });
  });

  group('isDefault() — only DefaultEntity returns true', () {
    test('DefaultEntity.isDefault() is true', () {
      expect(const DefaultEntity().isDefault(), isTrue);
    });

    test('GlobalEntity.isDefault() is false', () {
      expect(const GlobalEntity().isDefault(), isFalse);
    });

    test('SessionEntity.isDefault() is false', () {
      expect(const SessionEntity().isDefault(), isFalse);
    });

    test('UserEntity.isDefault() is false', () {
      expect(const UserEntity().isDefault(), isFalse);
    });

    test('ThemeEntity.isDefault() is false', () {
      expect(const ThemeEntity().isDefault(), isFalse);
    });

    test('ProdEntity.isDefault() is false', () {
      expect(const ProdEntity().isDefault(), isFalse);
    });

    test('DevEntity.isDefault() is false', () {
      expect(const DevEntity().isDefault(), isFalse);
    });

    test('TestEntity.isDefault() is false', () {
      expect(const TestEntity().isDefault(), isFalse);
    });
  });
}
