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

// Tests targeted at `SupportsChildrenMixin`: registerChild / getChild /
// getChildOrNone / unregisterChild / isChildRegistered / child() and their
// `T`-keyed variants. The mixin layers a children-container on top of the
// normal DI store, so every test goes through a fresh `DI()`.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

final _groupA = TypeEntity('childGroupA');
final _groupB = TypeEntity('childGroupB');

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('registerChild / child()', () {
    test('child() lazily registers and returns a fresh DI under a group', () {
      final di = DI();
      final c = di.child(groupEntity: _groupA);
      expect(c, isA<DI>());
      expect(identical(c, di), isFalse);
    });

    test('child() is idempotent — repeated calls return the same instance', () {
      final di = DI();
      final c1 = di.child(groupEntity: _groupA);
      final c2 = di.child(groupEntity: _groupA);
      expect(identical(c1, c2), isTrue);
    });

    test('child container has the parent in its parents set', () {
      final di = DI();
      final c = di.child(groupEntity: _groupA);
      expect(c.parents.contains(di), isTrue);
    });

    test('registerChild returns a Resolvable<Lazy<DI>>', () {
      final di = DI();
      final r = di.registerChild(groupEntity: _groupA);
      expect(r, isA<Resolvable<Lazy<DI>>>());
    });

    test('different groups yield different child instances', () {
      final di = DI();
      final a = di.child(groupEntity: _groupA);
      final b = di.child(groupEntity: _groupB);
      expect(identical(a, b), isFalse);
    });
  });

  group('isChildRegistered / isChildRegisteredT', () {
    test('returns false on a fresh container', () {
      final di = DI();
      expect(di.isChildRegistered(groupEntity: _groupA), isFalse);
      expect(di.isChildRegisteredT(groupEntity: _groupA), isFalse);
    });

    test('returns true after child() registers the child', () {
      final di = DI();
      di.child(groupEntity: _groupA);
      expect(di.isChildRegistered(groupEntity: _groupA), isTrue);
      expect(di.isChildRegisteredT(groupEntity: _groupA), isTrue);
    });

    test('other groups remain unregistered', () {
      final di = DI();
      di.child(groupEntity: _groupA);
      expect(di.isChildRegistered(groupEntity: _groupB), isFalse);
    });
  });

  group('getChild / getChildOrNone / getChildT', () {
    test('all three return None when no child is registered', () {
      final di = DI();
      expect(di.getChild(groupEntity: _groupA).isNone(), isTrue);
      expect(di.getChildOrNone(groupEntity: _groupA).isNone(), isTrue);
      expect(di.getChildT(groupEntity: _groupA).isNone(), isTrue);
    });

    test('getChild returns Some(Ok(DI)) after a child is registered', () {
      final di = DI();
      final c = di.child(groupEntity: _groupA);
      switch (di.getChild(groupEntity: _groupA)) {
        case Some(value: Ok(value: final got)):
          expect(identical(got, c), isTrue);
        case _:
          fail('Expected Some(Ok(DI)).');
      }
    });

    test('getChildOrNone returns Some(DI) after a child is registered', () {
      final di = DI();
      final c = di.child(groupEntity: _groupA);
      final option = di.getChildOrNone(groupEntity: _groupA);
      expect(option.isSome(), isTrue);
      UNSAFE:
      expect(identical(option.unwrap(), c), isTrue);
    });

    test('getChildT returns Some(Ok(DI)) after a child is registered', () {
      final di = DI();
      final c = di.child(groupEntity: _groupA);
      switch (di.getChildT(groupEntity: _groupA)) {
        case Some(value: Ok(value: final got)):
          expect(identical(got, c), isTrue);
        case _:
          fail('Expected Some(Ok(DI)).');
      }
    });
  });

  group('unregisterChild / unregisterChildT', () {
    test('unregisterChild on an empty container returns Err', () {
      final di = DI();
      final r = di.unregisterChild(groupEntity: _groupA);
      expect(r.isErr(), isTrue);
    });

    test('unregisterChild removes the registration', () {
      final di = DI();
      final c1 = di.child(groupEntity: _groupA);
      final r = di.unregisterChild(groupEntity: _groupA);
      expect(r.isOk(), isTrue);
      expect(di.isChildRegistered(groupEntity: _groupA), isFalse);
      // A fresh child() rebuilds.
      final c2 = di.child(groupEntity: _groupA);
      expect(identical(c1, c2), isFalse);
    });

    test('unregisterChildT removes the registration', () {
      final di = DI();
      di.child(groupEntity: _groupA);
      final r = di.unregisterChildT(DI, groupEntity: _groupA);
      expect(r.isOk(), isTrue);
      expect(di.isChildRegisteredT(groupEntity: _groupA), isFalse);
    });
  });

  group('child fallthrough', () {
    test('child can read from parent registrations via traverse', () {
      final di = DI();
      di.register<String>('parent-value').end();
      final c = di.child(groupEntity: _groupA);
      // Child should traverse up to parent.
      UNSAFE:
      expect(c.getSyncOrNone<String>().unwrap(), 'parent-value');
    });
  });
}
