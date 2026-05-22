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

// Tests for the T (Type) and K (Entity) variant accessors — these are thin
// wrappers around the generic-<T> primitives. We exercise the wrappers
// directly so a regression in the K/T → core path is caught here rather than
// silently routing the wrong key.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

final class Widget {
  Widget(this.label);
  final String label;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('T-variant accessors', () {
    test('getT / getSyncOrNoneT / isRegisteredT round-trip', () {
      final di = DI();
      di.register<Widget>(Widget('w1')).end();

      expect(di.isRegisteredT(Widget), isTrue);
      UNSAFE:
      expect(di.getSyncOrNoneT<Widget>(Widget).unwrap().label, 'w1');
      expect(di.getT<Widget>(Widget).isSome(), isTrue);
    });

    test('unregisterT removes the dependency', () async {
      final di = DI();
      di.register<Widget>(Widget('w2')).end();
      expect(di.isRegisteredT(Widget), isTrue);

      UNSAFE:
      (await di.unregisterT(Widget).unwrap()).end();
      expect(di.isRegisteredT(Widget), isFalse);
    });
  });

  group('K-variant accessors', () {
    test('getK / getSyncOrNoneK / isRegisteredK round-trip', () {
      final di = DI();
      final entity = TypeEntity(Widget);
      di.register<Widget>(Widget('k1')).end();

      expect(di.isRegisteredK(entity), isTrue);
      UNSAFE:
      expect(di.getSyncOrNoneK<Widget>(entity).unwrap().label, 'k1');
      expect(di.getK<Widget>(entity).isSome(), isTrue);
    });

    test('unregisterK with explicit TypeEntity removes the dependency',
        () async {
      final di = DI();
      final entity = TypeEntity(Widget);
      di.register<Widget>(Widget('k2')).end();

      UNSAFE:
      (await di.unregisterK(entity).unwrap()).end();
      expect(di.isRegisteredK(entity), isFalse);
    });

    test('isRegisteredK is strict — Lazy<W> NOT matched as W', () {
      final di = DI();
      di.registerLazy<Widget>(() => Sync.okValue(Widget('lazy'))).end();

      // Strict keying: <Widget> alone doesn't match a Lazy<Widget> entry.
      expect(di.isRegisteredK(TypeEntity(Widget)), isFalse);
      // The Lazy<Widget> compound entity DOES match.
      expect(di.isRegisteredK(TypeEntity(Lazy, [Widget])), isTrue);
    });
  });

  group('untilSuper via T/K-variant entry points', () {
    test('untilExactlyT resolves on registration matching the inner type',
        () async {
      final di = DI();
      final future = di.untilExactlyT<Widget>(Widget).toAsync().value;
      di.register<Widget>(Widget('matched'), enableUntilExactlyK: true).end();
      UNSAFE:
      final result = (await future).unwrap();
      expect(result.label, 'matched');
    });
  });
}
