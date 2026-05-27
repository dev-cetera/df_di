// ignore_for_file: sendable, invalid_use_of_protected_member

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

// Tests targeted at `SupportsConstructorsMixinK`: the `Entity`-keyed variants
// of the lazy/factory/singleton API. Most methods are `@protected` so we
// exercise the few that are public (getLazySingletonSyncOrNoneK,
// untilFactoryExactlyK) plus the public-by-inheritance lookups via DI.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

final class Widget {
  Widget(this.label);
  final String label;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('getLazyK / getLazySyncOrNoneK', () {
    test('returns None when unregistered', () {
      final di = DI();
      expect(di.getLazyK<Widget>(TypeEntity(Widget)).isNone(), isTrue);
    });

    test('returns Some(Resolvable<Lazy<T>>) when registered', () {
      final di = DI();
      di.registerLazy<Widget>(() => Sync.okValue(Widget('w'))).end();
      expect(di.getLazyK<Widget>(TypeEntity(Widget)).isSome(), isTrue);
    });

    test('getLazySyncOrNoneK returns None when unregistered', () {
      final di = DI();
      expect(di.getLazySyncOrNoneK<Widget>(TypeEntity(Widget)).isNone(), isTrue);
    });

    test('getLazySyncOrNoneK returns Some(Lazy<T>) when registered', () {
      final di = DI();
      di.registerLazy<Widget>(() => Sync.okValue(Widget('w'))).end();
      expect(di.getLazySyncOrNoneK<Widget>(TypeEntity(Widget)).isSome(), isTrue);
    });
  });

  group('getLazySingletonK / getLazySingletonSyncOrNoneK', () {
    test('returns None when unregistered', () {
      final di = DI();
      expect(di.getLazySingletonK<Widget>(TypeEntity(Widget)).isNone(), isTrue);
    });

    test('resolves the singleton when registered', () {
      final di = DI();
      di.registerLazy<Widget>(() => Sync.okValue(Widget('s'))).end();
      UNSAFE:
      final v = di
          .getLazySingletonK<Widget>(TypeEntity(Widget))
          .unwrap()
          .sync()
          .unwrap()
          .value
          .unwrap();
      expect(v.label, 's');
    });

    test('getLazySingletonSyncOrNoneK returns None when unregistered', () {
      final di = DI();
      expect(
        di.getLazySingletonSyncOrNoneK<Widget>(TypeEntity(Widget)).isNone(),
        isTrue,
      );
    });
  });

  group('getFactoryK / getLazyFactorySyncOrNoneK', () {
    test('factory yields fresh instances on each call', () {
      final di = DI();
      var n = 0;
      di.registerConstructor<Widget>(() => Widget('w${++n}')).end();

      UNSAFE:
      final f1 = di
          .getFactoryK<Widget>(TypeEntity(Widget))
          .unwrap()
          .sync()
          .unwrap()
          .unwrap();
      UNSAFE:
      final f2 = di
          .getFactoryK<Widget>(TypeEntity(Widget))
          .unwrap()
          .sync()
          .unwrap()
          .unwrap();
      expect(identical(f1, f2), isFalse);
      expect(f1.label, 'w1');
      expect(f2.label, 'w2');
    });

    test('getLazyFactorySyncOrNoneK returns None when unregistered', () {
      final di = DI();
      expect(
        di.getLazyFactorySyncOrNoneK<Widget>(TypeEntity(Widget)).isNone(),
        isTrue,
      );
    });
  });

  group('unregisterLazyK', () {
    test('removes a Lazy<T> registration keyed by Entity', () async {
      final di = DI();
      di.registerLazy<Widget>(() => Sync.okValue(Widget('w'))).end();
      expect(di.isRegistered<Lazy<Widget>>(), isTrue);

      (await di.unregisterLazyK(TypeEntity(Widget)).toAsync().value).end();
      expect(di.isRegistered<Lazy<Widget>>(), isFalse);
    });
  });

  group('untilLazyExactlyK / untilFactoryExactlyK', () {
    test(
      'untilFactoryExactlyK resolves on an enableUntilExactlyK Lazy<T> '
      'registration',
      () async {
        final di = DI();
        // The K-flag must be set; registerLazy doesn't expose that argument,
        // so we go through register<Lazy<T>> directly. The until*K helpers
        // wrap the passed typeEntity internally as Lazy<T>.
        final waiter =
            di.untilFactoryExactlyK<Widget>(TypeEntity(Widget)).toAsync().value;
        di
            .register<Lazy<Widget>>(
              Lazy<Widget>(() => Sync.okValue(Widget('exact'))),
              enableUntilExactlyK: true,
            )
            .end();

        UNSAFE:
        final v = (await waiter).unwrap();
        expect(v.label, 'exact');
      },
    );

    test('untilLazySingletonExactlyK resolves to the singleton', () async {
      final di = DI();
      final waiter = di
          .untilLazySingletonExactlyK<Widget>(TypeEntity(Widget))
          .toAsync()
          .value;
      di
          .register<Lazy<Widget>>(
            Lazy<Widget>(() => Sync.okValue(Widget('singleton'))),
            enableUntilExactlyK: true,
          )
          .end();

      UNSAFE:
      final v = (await waiter).unwrap();
      expect(v.label, 'singleton');
    });
  });
}
