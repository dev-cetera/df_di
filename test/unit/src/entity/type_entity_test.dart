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

// Tests for `TypeEntity` and `GenericEntity<T>` — the entity factory that
// produces a canonical type-string Entity from a base type and optional
// subtype substitutions (`Object` / `Object?` / `dynamic` placeholders), and
// the generics-aware convenience wrapper that captures `T` at the call site.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('TypeEntity basic factory', () {
    test('TypeEntity(int) equals TypeEntity("int")', () {
      expect(TypeEntity(int), equals(TypeEntity('int')));
    });

    test('TypeEntity(int) is an Entity', () {
      expect(TypeEntity(int), isA<Entity>());
    });

    test('two TypeEntities built from the same input are equal', () {
      expect(TypeEntity(int), equals(TypeEntity(int)));
    });

    test('TypeEntity(int) is NOT equal to TypeEntity(String)', () {
      expect(TypeEntity(int), isNot(equals(TypeEntity(String))));
    });
  });

  group('TypeEntity simple-identifier subType substitution', () {
    test(
      'TypeEntity(Object, [int]) appends generics to a simple base identifier',
      () {
        // `Object` is a simple identifier (no `<>` `,` `?`), so the factory
        // appends `<int>` directly.
        final expected = TypeEntity('Object<int>');
        expect(TypeEntity(Object, [int]), equals(expected));
      },
    );
  });

  group('TypeEntity placeholder substitution in generic base strings', () {
    test(
      'TypeEntity(Map<Object, Object>, [String, int]) replaces Object '
      'placeholders sequentially',
      () {
        final entity = TypeEntity(Map<Object, Object>, [String, int]);
        expect(entity, equals(TypeEntity('Map<String,int>')));
      },
    );

    test(
      'TypeEntity from a literal "List<dynamic>" string substitutes dynamic',
      () {
        final entity = TypeEntity('List<dynamic>', [int]);
        expect(entity, equals(TypeEntity('List<int>')));
      },
    );

    test(
      'TypeEntity("Map<dynamic, List<Object>>", [String, int]) substitutes '
      'both placeholders in left-to-right order',
      () {
        final entity = TypeEntity(
          'Map<dynamic, List<Object>>',
          [String, int],
        );
        expect(entity, equals(TypeEntity('Map<String,List<int>>')));
      },
    );

    test(
      'TypeEntity("Object?", [String]) replaces the nullable Object '
      'placeholder',
      () {
        final entity = TypeEntity('Object?', [String]);
        expect(entity, equals(TypeEntity('String')));
      },
    );

    test(
      'TypeEntity supports nested TypeEntity as a subType — its inner type '
      'string is extracted',
      () {
        final entity = TypeEntity('List<dynamic>', [TypeEntity(int)]);
        expect(entity, equals(TypeEntity('List<int>')));
      },
    );
  });

  group('GenericEntity', () {
    test('GenericEntity<int>() equals TypeEntity(int)', () {
      expect(GenericEntity<int>(), equals(TypeEntity(int)));
    });

    test('GenericEntity<List<int>>() equals TypeEntity(List<int>)', () {
      expect(GenericEntity<List<int>>(), equals(TypeEntity(List<int>)));
    });

    test('GenericEntity<int> is a TypeEntity', () {
      expect(GenericEntity<int>(), isA<TypeEntity>());
    });

    test('GenericEntity<int> is an Entity', () {
      expect(GenericEntity<int>(), isA<Entity>());
    });
  });
}
