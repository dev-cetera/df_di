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

// Tests for `UniqueEntity` — the 128-bit RFC 4122 v4 UUID-backed Entity
// whose equality always consults the UUID (so it survives id collisions in
// the 32-bit hash space) and whose [id] sits below the reserved-entity range
// while staying within dart2js's 53-bit safe-integer floor.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('UniqueEntity construction', () {
    test('two distinct UniqueEntity() instances are NOT equal', () {
      final a = UniqueEntity();
      final b = UniqueEntity();
      expect(a == b, isFalse);
    });

    test('a UniqueEntity is equal to itself (identity)', () {
      final u = UniqueEntity();
      expect(u == u, isTrue);
      expect(identical(u, u), isTrue);
    });

    test('UniqueEntity is a StrictEqualityEntity', () {
      expect(UniqueEntity(), isA<StrictEqualityEntity>());
    });

    test('UniqueEntity is also an Entity', () {
      expect(UniqueEntity(), isA<Entity>());
    });
  });

  group('UniqueEntity.uuid', () {
    test('uuid matches the RFC 4122 v4 format', () {
      final regex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      for (var i = 0; i < 20; i++) {
        final u = UniqueEntity();
        expect(
          regex.hasMatch(u.uuid),
          isTrue,
          reason: 'uuid ${u.uuid} should match RFC 4122 v4',
        );
      }
    });

    test('100 generated UniqueEntities have 100 distinct uuids', () {
      final uuids = <String>{};
      for (var i = 0; i < 100; i++) {
        uuids.add(UniqueEntity().uuid);
      }
      expect(uuids.length, equals(100));
    });
  });

  group('UniqueEntity.id', () {
    test('id is in the reserved range (<= -10001)', () {
      for (var i = 0; i < 50; i++) {
        final u = UniqueEntity();
        expect(
          u.id,
          lessThanOrEqualTo(-10001),
          reason: 'UniqueEntity.id ($u) must sit below reserved-entity range',
        );
      }
    });

    test('id is negative', () {
      expect(UniqueEntity().id, lessThan(0));
    });
  });

  group('UniqueEntity.hashCode / toString', () {
    test('hashCode equals id', () {
      final u = UniqueEntity();
      expect(u.hashCode, equals(u.id));
    });

    test('toString returns "UniqueEntity(<uuid>)"', () {
      final u = UniqueEntity();
      expect(u.toString(), equals('UniqueEntity(${u.uuid})'));
    });
  });
}
