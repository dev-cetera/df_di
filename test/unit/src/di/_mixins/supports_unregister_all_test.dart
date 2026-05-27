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

// Tests targeted at `SupportsUnregisterAll`: `unregisterAll` evicts every
// dependency, honours an optional condition predicate, fires onBeforeUnregister
// / onAfterUnregister at the right time, and fires the per-dependency
// onUnregister hooks.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

final class Alpha {
  Alpha(this.tag);
  final String tag;
}

final class Beta {
  Beta(this.tag);
  final String tag;
}

final class Gamma {
  Gamma(this.tag);
  final String tag;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('unregisterAll', () {
    test('evicts every registered dependency', () async {
      final di = DI();
      di.register<Alpha>(Alpha('a')).end();
      di.register<Beta>(Beta('b')).end();
      di.register<Gamma>(Gamma('g')).end();

      expect(di.isRegistered<Alpha>(), isTrue);
      expect(di.isRegistered<Beta>(), isTrue);
      expect(di.isRegistered<Gamma>(), isTrue);

      (await di.unregisterAll().toAsync().value).end();

      expect(di.isRegistered<Alpha>(), isFalse);
      expect(di.isRegistered<Beta>(), isFalse);
      expect(di.isRegistered<Gamma>(), isFalse);
    });

    test('returns a Resolvable<Unit>', () {
      final di = DI();
      final r = di.unregisterAll();
      expect(r, isA<Resolvable<Unit>>());
    });

    test('on an empty container returns Ok(Unit)', () async {
      final di = DI();
      final r = await di.unregisterAll().toAsync().value;
      expect(r.isOk(), isTrue);
    });
  });

  group('unregisterAll — condition predicate', () {
    test('honours the condition predicate', () async {
      final di = DI();
      di.register<Alpha>(Alpha('keep')).end();
      di.register<Beta>(Beta('drop')).end();

      // Only drop Beta.
      (await di
              .unregisterAll(
                condition: Some((d) => d.value is Resolvable<Beta>),
              )
              .toAsync()
              .value)
          .end();

      expect(di.isRegistered<Alpha>(), isTrue);
      expect(di.isRegistered<Beta>(), isFalse);
    });

    test('a never-true predicate keeps everything', () async {
      final di = DI();
      di.register<Alpha>(Alpha('a')).end();
      di.register<Beta>(Beta('b')).end();

      (await di.unregisterAll(condition: Some((_) => false)).toAsync().value)
          .end();

      expect(di.isRegistered<Alpha>(), isTrue);
      expect(di.isRegistered<Beta>(), isTrue);
    });
  });

  group('unregisterAll — per-dep onUnregister', () {
    test('triggers per-dependency onUnregister callbacks', () async {
      final di = DI();
      var disposeCount = 0;
      di
          .register<Alpha>(
            Alpha('a'),
            onUnregister: Some((_) => disposeCount++),
          )
          .end();
      di
          .register<Beta>(
            Beta('b'),
            onUnregister: Some((_) => disposeCount++),
          )
          .end();

      (await di.unregisterAll().toAsync().value).end();
      expect(disposeCount, 2);
    });
  });

  group('unregisterAll — onBeforeUnregister / onAfterUnregister', () {
    test('onBeforeUnregister fires for each dependency', () async {
      final di = DI();
      di.register<Alpha>(Alpha('a')).end();
      di.register<Beta>(Beta('b')).end();

      var beforeCount = 0;
      (await di
              .unregisterAll(
                onBeforeUnregister: Some((_) {
                  beforeCount++;
                  return null;
                }),
              )
              .toAsync()
              .value)
          .end();
      expect(beforeCount, 2);
    });

    test('onAfterUnregister fires for each dependency', () async {
      final di = DI();
      di.register<Alpha>(Alpha('a')).end();
      di.register<Beta>(Beta('b')).end();

      var afterCount = 0;
      (await di
              .unregisterAll(
                onAfterUnregister: Some((_) {
                  afterCount++;
                  return null;
                }),
              )
              .toAsync()
              .value)
          .end();
      expect(afterCount, 2);
    });

    test(
      'onBeforeUnregister fires BEFORE the dependency onUnregister',
      () async {
        final di = DI();
        final order = <String>[];

        di.register<Alpha>(
          Alpha('a'),
          onUnregister: Some((_) {
            order.add('dep.alpha');
            return null;
          }),
        ).end();

        (await di
                .unregisterAll(
                  onBeforeUnregister: Some((_) {
                    order.add('before');
                    return null;
                  }),
                  onAfterUnregister: Some((_) {
                    order.add('after');
                    return null;
                  }),
                )
                .toAsync()
                .value)
            .end();

        expect(order, ['before', 'dep.alpha', 'after']);
      },
    );
  });
}
