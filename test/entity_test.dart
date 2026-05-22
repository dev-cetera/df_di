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

// Tests for Entity / TypeEntity / DefaultEntity behaviour. The substitution
// rules for TypeEntity are non-trivial (Object / dynamic / Object? are all
// placeholders), and the equality / preferOverDefault semantics underpin
// every keyed access in the DI registry.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('TypeEntity construction', () {
    // `TypeEntity` is identified by a normalized type string; equality is on
    // that string's hash. We test the substitution rules by comparing the
    // computed-entity against an equivalent literal-string entity.

    test('TypeEntity(Object, [int]) renders as Object<int> (appended)', () {
      // For a simple-identifier baseType (no <>, , or ?), subTypes are
      // appended as generic arguments rather than substituted.
      expect(
        TypeEntity(Object, [int]),
        equals(TypeEntity('Object<int>')),
      );
    });

    test('Object placeholders are substituted left-to-right', () {
      expect(
        TypeEntity(Map<Object, Object>, [String, int]),
        equals(TypeEntity('Map<String,int>')),
      );
    });

    test('string baseType + dynamic placeholder is substituted', () {
      expect(
        TypeEntity('List<dynamic>', [int]),
        equals(TypeEntity('List<int>')),
      );
    });

    test('two TypeEntities built the same way are equal', () {
      expect(TypeEntity(int), equals(TypeEntity(int)));
      expect(
        TypeEntity(Map<Object, Object>, [String, int]),
        equals(TypeEntity(Map<Object, Object>, [String, int])),
      );
    });

    test('different types produce different entities', () {
      expect(TypeEntity(int), isNot(equals(TypeEntity(String))));
    });
  });

  group('DefaultEntity / preferOverDefault', () {
    test('DefaultEntity.isDefault() is true', () {
      expect(const DefaultEntity().isDefault(), isTrue);
      expect(const DefaultEntity().isNotDefault(), isFalse);
    });

    test('non-default entity isDefault is false', () {
      expect(TypeEntity(int).isDefault(), isFalse);
      expect(TypeEntity(int).isNotDefault(), isTrue);
    });

    test('preferOverDefault keeps the receiver when receiver is non-default',
        () {
      final e = TypeEntity('a');
      final fallback = TypeEntity('b');
      expect(e.preferOverDefault(fallback), equals(e));
    });

    test('preferOverDefault yields the fallback when receiver is default', () {
      final fallback = TypeEntity('b');
      expect(const DefaultEntity().preferOverDefault(fallback), equals(fallback));
    });
  });

  group('UniqueEntity', () {
    test('two UniqueEntity() instances are not equal', () {
      expect(UniqueEntity(), isNot(equals(UniqueEntity())));
    });
  });
}
