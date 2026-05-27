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

// ignore_for_file: sendable

// Tests targeted at `SupportsMixinK`: the `Entity`-keyed lookup / probe /
// registration-completer API. Covers getK / getSyncK / getSyncOrNoneK /
// isRegisteredK / unregisterK / removeDependencyK / getDependencyK /
// untilExactlyK / untilSuperK / untilK and the strict-keying contract.

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

final class Widget {
  Widget(this.label);
  final String label;
}

abstract class Animal {
  String get name;
}

final class Cat extends Animal {
  Cat(this.name);
  @override
  final String name;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('isRegisteredK', () {
    test('returns false on a fresh container', () {
      final di = DI();
      expect(di.isRegisteredK(TypeEntity(Widget)), isFalse);
    });

    test('returns true after registration', () {
      final di = DI();
      di.register<Widget>(Widget('w')).end();
      expect(di.isRegisteredK(TypeEntity(Widget)), isTrue);
    });

    test('strict keying — Lazy<W> is not matched as W', () {
      final di = DI();
      di.registerLazy<Widget>(() => Sync.okValue(Widget('lazy'))).end();
      expect(di.isRegisteredK(TypeEntity(Widget)), isFalse);
      expect(di.isRegisteredK(TypeEntity(Lazy, [Widget])), isTrue);
    });
  });

  group('getK / getSyncK / getSyncOrNoneK', () {
    test('getK returns None when unregistered', () {
      final di = DI();
      expect(di.getK<Widget>(TypeEntity(Widget)).isNone(), isTrue);
    });

    test('getK returns Some(Resolvable<T>) when registered', () {
      final di = DI();
      di.register<Widget>(Widget('a')).end();
      UNSAFE:
      final v = di
          .getK<Widget>(TypeEntity(Widget))
          .unwrap()
          .sync()
          .unwrap()
          .value
          .unwrap();
      expect(v.label, 'a');
    });

    test('getSyncOrNoneK returns None for unregistered', () {
      final di = DI();
      expect(di.getSyncOrNoneK<Widget>(TypeEntity(Widget)).isNone(), isTrue);
    });

    test('getSyncOrNoneK returns Some(T) when registered', () {
      final di = DI();
      di.register<Widget>(Widget('b')).end();
      UNSAFE:
      expect(di.getSyncOrNoneK<Widget>(TypeEntity(Widget)).unwrap().label, 'b');
    });
  });

  group('getSyncUnsafeK / getUnsafeK', () {
    test('getSyncUnsafeK returns the value directly', () {
      final di = DI();
      di.register<Widget>(Widget('u')).end();
      expect(di.getSyncUnsafeK<Widget>(TypeEntity(Widget)).label, 'u');
    });

    test('getUnsafeK returns a FutureOr<T>', () {
      final di = DI();
      di.register<Widget>(Widget('u2')).end();
      final v = di.getUnsafeK<Widget>(TypeEntity(Widget));
      expect((v as Widget).label, 'u2');
    });
  });

  group('unregisterK / removeDependencyK', () {
    test('unregisterK removes the registration', () async {
      final di = DI();
      di.register<Widget>(Widget('x')).end();
      expect(di.isRegisteredK(TypeEntity(Widget)), isTrue);

      UNSAFE:
      (await di.unregisterK(TypeEntity(Widget)).unwrap()).end();
      expect(di.isRegisteredK(TypeEntity(Widget)), isFalse);
    });

    test('removeDependencyK returns Some(Dependency) when found', () {
      final di = DI();
      di.register<Widget>(Widget('rm')).end();
      final removed = di.removeDependencyK<Widget>(TypeEntity(Widget));
      expect(removed.isSome(), isTrue);
      expect(di.isRegisteredK(TypeEntity(Widget)), isFalse);
    });

    test('removeDependencyK returns None when absent', () {
      final di = DI();
      expect(
        di.removeDependencyK<Widget>(TypeEntity(Widget)).isNone(),
        isTrue,
      );
    });
  });

  group('getDependencyK', () {
    test('returns None when unregistered', () {
      final di = DI();
      expect(di.getDependencyK<Widget>(TypeEntity(Widget)).isNone(), isTrue);
    });

    test('returns Some(Ok(Dependency<T>)) when registered', () {
      final di = DI();
      di.register<Widget>(Widget('d')).end();
      switch (di.getDependencyK<Widget>(TypeEntity(Widget))) {
        case Some(value: Ok()):
          break;
        case _:
          fail('Expected Some(Ok(Dependency<T>)).');
      }
    });
  });

  group('untilExactlyK / untilSuperK / untilK', () {
    test('resolves immediately when a matching registration exists', () async {
      final di = DI();
      di.register<Widget>(Widget('immediate'), enableUntilExactlyK: true).end();
      UNSAFE:
      final v = await di
          .untilExactlyK<Widget>(TypeEntity(Widget))
          .toAsync()
          .value
          .then((r) => r.unwrap());
      expect(v.label, 'immediate');
    });

    test('resolves when a matching registration arrives', () async {
      final di = DI();
      final f = di.untilExactlyK<Widget>(TypeEntity(Widget)).toAsync().value;
      unawaited(
        Future<void>.microtask(() {
          di
              .register<Widget>(Widget('arrived'), enableUntilExactlyK: true)
              .end();
        }),
      );

      UNSAFE:
      expect((await f).unwrap().label, 'arrived');
    });

    test('untilSuperK is functionally an alias for untilExactlyK', () async {
      final di = DI();
      final f = di.untilSuperK<Widget>(TypeEntity(Widget)).toAsync().value;
      di.register<Widget>(Widget('super'), enableUntilExactlyK: true).end();

      UNSAFE:
      expect((await f).unwrap().label, 'super');
    });

    test('untilK<TSuper, TSub> casts to TSub on resolution', () async {
      final di = DI();
      final f = di.untilK<Animal, Cat>(TypeEntity(Animal)).toAsync().value;
      di.register<Animal>(Cat('Felix'), enableUntilExactlyK: true).end();

      UNSAFE:
      final cat = (await f).unwrap();
      expect(cat, isA<Cat>());
      expect(cat.name, 'Felix');
    });
  });
}
