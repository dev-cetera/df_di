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

// Regression tests for the `typeEntity`-without-metadata bug at
// `_dependency.dart:67`. Internal `Dependency` is `@internal`, so we exercise
// the path through the public DI surface, which constructs dependencies
// internally under both metadata-present and metadata-absent paths.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Test fixtures ───────────────────────────────────────────────────────────

final class Thing {
  Thing(this.label);
  final String label;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('register/get without metadata crash regression', () {
    test('register/get round-trip does not throw on typeEntity access', () {
      final di = DI();

      // The internal `Dependency.typeEntity` is consulted during
      // setDependency. If the getter ever calls metadata.unwrap() without
      // checking, this will throw — captured here as a contract test.
      expect(
        () => di.register<Thing>(Thing('present')).end(),
        returnsNormally,
      );
      expect(di.isRegistered<Thing>(), isTrue);
    });

    test('repeated register/unregister cycles do not corrupt state', () async {
      final di = DI();
      for (var n = 0; n < 5; n++) {
        di.register<Thing>(Thing('round-$n')).end();
        expect(di.isRegistered<Thing>(), isTrue);
        UNSAFE:
        (await di.unregister<Thing>().unwrap()).end();
        expect(di.isRegistered<Thing>(), isFalse);
      }
    });
  });
}
