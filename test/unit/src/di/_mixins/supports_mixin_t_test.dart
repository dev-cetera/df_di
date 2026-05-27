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

// Tests targeted at `SupportsMixinT`: the `Type`-keyed lookup/register/probe
// API. These methods are thin wrappers around the K-keyed core; this file
// pins down the wire-up so a regression in the T → K dispatch is caught
// here rather than masquerading as a "key-not-found" elsewhere.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

final class Widget {
  Widget(this.label);
  final String label;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('isRegisteredT', () {
    test('returns false on a fresh container', () {
      final di = DI();
      expect(di.isRegisteredT(Widget), isFalse);
    });

    test('returns true after registration', () {
      final di = DI();
      di.register<Widget>(Widget('w')).end();
      expect(di.isRegisteredT(Widget), isTrue);
    });
  });

  group('getT / getSyncT / getSyncOrNoneT', () {
    test('getT returns None when unregistered', () {
      final di = DI();
      expect(di.getT<Widget>(Widget).isNone(), isTrue);
    });

    test('getT returns Some(Resolvable<T>) when registered', () {
      final di = DI();
      di.register<Widget>(Widget('w1')).end();
      final out = di.getT<Widget>(Widget);
      expect(out.isSome(), isTrue);
      UNSAFE:
      final v = out.unwrap().sync().unwrap().value.unwrap();
      expect(v.label, 'w1');
    });

    test('getSyncT returns the Sync wrapper directly', () {
      final di = DI();
      di.register<Widget>(Widget('w2')).end();
      final out = di.getSyncT<Widget>(Widget);
      expect(out.isSome(), isTrue);
      UNSAFE:
      expect(out.unwrap().value.unwrap().label, 'w2');
    });

    test('getSyncOrNoneT returns None when unregistered', () {
      final di = DI();
      expect(di.getSyncOrNoneT<Widget>(Widget).isNone(), isTrue);
    });

    test('getSyncOrNoneT returns Some(T) when registered', () {
      final di = DI();
      di.register<Widget>(Widget('w3')).end();
      UNSAFE:
      expect(di.getSyncOrNoneT<Widget>(Widget).unwrap().label, 'w3');
    });
  });

  group('getSyncUnsafeT / getUnsafeT', () {
    test('getSyncUnsafeT returns the value directly', () {
      final di = DI();
      di.register<Widget>(Widget('unsafe')).end();
      expect(di.getSyncUnsafeT<Widget>(Widget).label, 'unsafe');
    });

    test('getUnsafeT returns a FutureOr<T>', () {
      final di = DI();
      di.register<Widget>(Widget('unsafe2')).end();
      final got = di.getUnsafeT<Widget>(Widget);
      expect(got, isA<Widget>());
      expect((got as Widget).label, 'unsafe2');
    });
  });

  group('unregisterT / removeDependencyT', () {
    test('unregisterT removes the dependency', () async {
      final di = DI();
      di.register<Widget>(Widget('to-remove')).end();
      expect(di.isRegisteredT(Widget), isTrue);

      UNSAFE:
      (await di.unregisterT(Widget).unwrap()).end();
      expect(di.isRegisteredT(Widget), isFalse);
    });

    test('removeDependencyT returns Some(Dependency) when found', () {
      final di = DI();
      di.register<Widget>(Widget('removable')).end();
      final removed = di.removeDependencyT<Widget>(Widget);
      expect(removed.isSome(), isTrue);
      expect(di.isRegisteredT(Widget), isFalse);
    });

    test('removeDependencyT returns None when absent', () {
      final di = DI();
      expect(di.removeDependencyT<Widget>(Widget).isNone(), isTrue);
    });
  });

  group('getDependencyT', () {
    test('returns None when unregistered', () {
      final di = DI();
      expect(di.getDependencyT<Widget>(Widget).isNone(), isTrue);
    });

    test('returns Some(Ok(Dependency<T>)) when registered', () {
      final di = DI();
      di.register<Widget>(Widget('dep')).end();
      switch (di.getDependencyT<Widget>(Widget)) {
        case Some(value: Ok()):
          // good
          break;
        case _:
          fail('Expected Some(Ok(Dependency<T>)).');
      }
    });
  });

  group('untilExactlyT / untilSuperT / untilT', () {
    test('untilExactlyT resolves once a matching type is registered', () async {
      final di = DI();
      final f = di.untilExactlyT<Widget>(Widget).toAsync().value;
      di.register<Widget>(Widget('arrived'), enableUntilExactlyK: true).end();

      UNSAFE:
      expect((await f).unwrap().label, 'arrived');
    });

    test('untilSuperT is an alias of untilExactlyT', () async {
      final di = DI();
      final f = di.untilSuperT<Widget>(Widget).toAsync().value;
      di.register<Widget>(Widget('super'), enableUntilExactlyK: true).end();

      UNSAFE:
      expect((await f).unwrap().label, 'super');
    });
  });
}
