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

// Tests for `Entity` — the integer-id value type underpinning DI keys.
// Covers the constructor contract, `objId` conversion, equality (including
// the StrictEqualityEntity asymmetric-rejection rule), and the default-aware
// helpers `isDefault` / `isNotDefault` / `preferOverDefault`.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('Entity constructor', () {
    test('Entity(0) is allowed', () {
      const e = Entity(0);
      expect(e.id, equals(0));
    });

    test('Entity(id) for a positive id keeps the id', () {
      const e = Entity(42);
      expect(e.id, equals(42));
    });

    test('Entity(id) asserts on a negative id', () {
      expect(() => Entity(-1), throwsA(isA<AssertionError>()));
    });
  });

  group('Entity.obj / objId', () {
    test('Entity.obj(int) keeps the int unchanged as id', () {
      final e = Entity.obj(7);
      expect(e.id, equals(7));
    });

    test('Entity.obj(String) hashes the string with spaces removed', () {
      final e = Entity.obj('hello world');
      expect(e.id, equals('helloworld'.hashCode));
    });

    test(
      'Entity.obj(String) is space-insensitive for the same underlying token',
      () {
        expect(Entity.obj('a b c'), equals(Entity.obj('abc')));
      },
    );

    test('Entity.obj for arbitrary objects uses toString hashCode', () {
      final obj = _Boxed('payload');
      final e = Entity.obj(obj);
      expect(
        e.id,
        equals(obj.toString().replaceAll(' ', '').hashCode),
      );
    });
  });

  group('Entity.hashCode / toString', () {
    test('hashCode equals id', () {
      const e = Entity(123);
      expect(e.hashCode, equals(e.id));
    });

    test('toString returns id.toString()', () {
      const e = Entity(99);
      expect(e.toString(), equals('99'));
    });
  });

  group('isDefault / isNotDefault / preferOverDefault', () {
    test('Entity(0) is NOT default (DefaultEntity has reserved id -1001)', () {
      expect(const Entity(0).isDefault(), isFalse);
      expect(const Entity(0).isNotDefault(), isTrue);
    });

    test('DefaultEntity reports isDefault true', () {
      expect(const DefaultEntity().isDefault(), isTrue);
      expect(const DefaultEntity().isNotDefault(), isFalse);
    });

    test('preferOverDefault returns this when not default', () {
      const self = Entity(5);
      const fallback = Entity(6);
      expect(self.preferOverDefault(fallback), equals(self));
    });

    test('preferOverDefault returns other when this is default', () {
      const fallback = Entity(6);
      expect(
        const DefaultEntity().preferOverDefault(fallback),
        equals(fallback),
      );
    });
  });

  group('Entity equality', () {
    test('identical instances are equal', () {
      const e = Entity(5);
      expect(identical(e, e), isTrue);
      expect(e == e, isTrue);
    });

    test('two Entity(5) are equal and share a hashCode', () {
      const a = Entity(5);
      const b = Entity(5);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Entity(5) is NOT equal to Entity(6)', () {
      expect(const Entity(5), isNot(equals(const Entity(6))));
    });

    test('Entity(5) == 5 via objId (int short-circuits)', () {
      // ignore: unrelated_type_equality_checks
      expect(const Entity(5) == 5, isTrue);
    });

    test('Entity == arbitrary object compares via objId', () {
      const e = Entity(42);
      // ignore: unrelated_type_equality_checks
      expect(e == 42, isTrue);
      // ignore: unrelated_type_equality_checks
      expect(e == 43, isFalse);
    });

    test('loose Entity rejects equality against StrictEqualityEntity', () {
      // UniqueEntity implements StrictEqualityEntity. A plain Entity whose
      // id happens to match a UniqueEntity's id must still report not-equal,
      // so == stays symmetric (UniqueEntity itself only matches by uuid).
      final unique = UniqueEntity();
      final loose = _LooseReservedEntity(unique.id);
      expect(loose == unique, isFalse);
    });
  });
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _Boxed {
  final String label;
  _Boxed(this.label);

  @override
  String toString() => 'Boxed($label)';
}

/// A subclass that exposes `Entity.reserved` (which is `@protected`) for the
/// asymmetric-equality test above. The instance is a plain `Entity` — it
/// does NOT implement `StrictEqualityEntity`.
class _LooseReservedEntity extends Entity {
  const _LooseReservedEntity(super.id) : super.reserved();
}
