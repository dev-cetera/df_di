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

// Tests for `SupportsChildrenMixin`: the child() singleton path, the
// isChildRegistered probe (regression test for the strict-keying fix —
// before the fix this falsely returned false and the next child() call
// silently failed-to-register, masked only by checkExisting), and
// unregisterChild.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Tests ───────────────────────────────────────────────────────────────────

final _groupA = TypeEntity('groupA');
final _groupB = TypeEntity('groupB');

void main() {
  group('child() / isChildRegistered', () {
    test('isChildRegistered is false on a fresh container', () {
      final parent = DI();
      expect(parent.isChildRegistered(groupEntity: _groupA), isFalse);
    });

    test('isChildRegistered is true after child() in that group', () {
      final parent = DI();
      parent.child(groupEntity: _groupA);
      expect(parent.isChildRegistered(groupEntity: _groupA), isTrue);
      // A different group is still empty.
      expect(parent.isChildRegistered(groupEntity: _groupB), isFalse);
    });

    test('child() is idempotent — repeated calls return the same instance',
        () {
      final parent = DI();
      final c1 = parent.child(groupEntity: _groupA);
      final c2 = parent.child(groupEntity: _groupA);
      expect(identical(c1, c2), isTrue);
    });
  });

  group('getChildOrNone', () {
    test('returns None when no child is registered', () {
      final parent = DI();
      expect(parent.getChildOrNone(groupEntity: _groupA).isNone(), isTrue);
    });

    test('returns Some(DI) after child() registers one', () {
      final parent = DI();
      final c = parent.child(groupEntity: _groupA);
      final option = parent.getChildOrNone(groupEntity: _groupA);
      expect(option.isSome(), isTrue);
      UNSAFE:
      expect(identical(option.unwrap(), c), isTrue);
    });
  });

  group('unregisterChild', () {
    test('removes the child container so child() rebuilds a fresh one', () {
      final parent = DI();
      final c1 = parent.child(groupEntity: _groupA);
      final result = parent.unregisterChild(groupEntity: _groupA);
      expect(result.isOk(), isTrue);

      // After unregister, isChildRegistered is false again.
      expect(parent.isChildRegistered(groupEntity: _groupA), isFalse);

      // A fresh child() rebuilds — the new instance is not the old one.
      final c2 = parent.child(groupEntity: _groupA);
      expect(identical(c1, c2), isFalse);
    });

    test('unregisterChild on an empty container returns Err', () {
      final parent = DI();
      final result = parent.unregisterChild(groupEntity: _groupA);
      expect(result.isErr(), isTrue);
    });
  });
}
