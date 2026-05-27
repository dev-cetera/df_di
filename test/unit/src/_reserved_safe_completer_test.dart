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

// Tests for `ReservedSafeCompleter<T>` — the SafeCompleter variant whose
// `typeCheck` closure is built while `T` is lexically in scope (so dart2js
// release minification cannot strip the reified generic) and whose equality
// is identity-based by design so distinct waiter records never collide in a
// hash set.

import 'package:df_di/df_di.dart';
import 'package:df_di/src/_reserved_safe_completer.dart';
import 'package:test/test.dart';

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('ReservedSafeCompleter construction', () {
    test('stores the supplied typeEntity', () {
      final entity = TypeEntity(int);
      final completer = ReservedSafeCompleter<int>(entity);
      expect(completer.typeEntity, equals(entity));
    });

    test('is a SafeCompleter<T>', () {
      final completer = ReservedSafeCompleter<int>(TypeEntity(int));
      expect(completer, isA<SafeCompleter<int>>());
    });
  });

  group('ReservedSafeCompleter.typeCheck', () {
    test('returns true for an instance of T', () {
      final completer = ReservedSafeCompleter<int>(TypeEntity(int));
      expect(completer.typeCheck(5), isTrue);
    });

    test('returns false for a non-T value', () {
      final completer = ReservedSafeCompleter<int>(TypeEntity(int));
      expect(completer.typeCheck('hello'), isFalse);
    });

    test('respects subtype relationships (num accepts int)', () {
      final completer = ReservedSafeCompleter<num>(TypeEntity(num));
      expect(completer.typeCheck(5), isTrue);
      expect(completer.typeCheck(3.14), isTrue);
    });

    test('rejects a sibling subtype (int does NOT accept double)', () {
      final completer = ReservedSafeCompleter<int>(TypeEntity(int));
      expect(completer.typeCheck(3.14), isFalse);
    });

    test('String typeCheck rejects an int', () {
      final completer = ReservedSafeCompleter<String>(TypeEntity(String));
      expect(completer.typeCheck(5), isFalse);
      expect(completer.typeCheck('hi'), isTrue);
    });
  });

  group('ReservedSafeCompleter equality (identity-based)', () {
    test(
      'two distinct ReservedSafeCompleter<int> with the same TypeEntity are '
      'NOT equal',
      () {
        final a = ReservedSafeCompleter<int>(TypeEntity(int));
        final b = ReservedSafeCompleter<int>(TypeEntity(int));
        expect(identical(a, b), isFalse);
        expect(a == b, isFalse);
      },
    );

    test('a ReservedSafeCompleter is equal to itself', () {
      final c = ReservedSafeCompleter<int>(TypeEntity(int));
      expect(c == c, isTrue);
      expect(identical(c, c), isTrue);
    });
  });

  group('ReservedSafeCompleter hashCode', () {
    test('hashCode is stable across repeated reads on the same instance', () {
      final c = ReservedSafeCompleter<int>(TypeEntity(int));
      final h1 = c.hashCode;
      final h2 = c.hashCode;
      final h3 = c.hashCode;
      expect(h1, equals(h2));
      expect(h2, equals(h3));
    });

    test('different T produces a different hashCode', () {
      final ci = ReservedSafeCompleter<int>(TypeEntity(int));
      final cs = ReservedSafeCompleter<String>(TypeEntity(String));
      expect(ci.hashCode, isNot(equals(cs.hashCode)));
    });
  });
}
