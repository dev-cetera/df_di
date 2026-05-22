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

// Tests for `unregisterAll` — covers the regression where it passed
// `dependency.typeEntity` (the raw `Sync<Foo>` key) back into
// `removeDependencyK`, which would wrap it AGAIN as `Sync<Sync<Foo>>` and
// silently fail to evict anything.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Test fixtures ───────────────────────────────────────────────────────────

final class Alpha {
  Alpha(this.tag);
  final String tag;
}

final class Beta {
  Beta(this.tag);
  final String tag;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('unregisterAll', () {
    test('evicts every registered dependency', () async {
      final di = DI();
      di.register<Alpha>(Alpha('a')).end();
      di.register<Beta>(Beta('b')).end();

      expect(di.isRegistered<Alpha>(), isTrue);
      expect(di.isRegistered<Beta>(), isTrue);

      (await di.unregisterAll().toAsync().value).end();

      expect(di.isRegistered<Alpha>(), isFalse);
      expect(di.isRegistered<Beta>(), isFalse);
    });

    test('honours the condition predicate', () async {
      final di = DI();
      di.register<Alpha>(Alpha('keep')).end();
      di.register<Beta>(Beta('drop')).end();

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

    test('triggers onUnregister callbacks', () async {
      final di = DI();
      var disposeCount = 0;
      di.register<Alpha>(
        Alpha('a'),
        onUnregister: Some((_) => disposeCount++),
      ).end();
      di.register<Beta>(
        Beta('b'),
        onUnregister: Some((_) => disposeCount++),
      ).end();

      (await di.unregisterAll().toAsync().value).end();
      expect(disposeCount, 2);
    });
  });
}
