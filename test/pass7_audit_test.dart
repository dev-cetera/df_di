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
//
// Audit pass 7: traversal-depth asymmetry between `isRegistered` and
// `unregister` (and similar API consistency checks).

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

final class _A {
  const _A([this.tag = '']);
  final String tag;
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // 1. Three-level hierarchy A ← B ← C. _A registered only in A.
  //    C.isRegistered<_A>(traverse: true) returns true (deep).
  //    C.unregister<_A>(traverse: true, removeAll: true) — what happens?
  // ─────────────────────────────────────────────────────────────────────────
  group('hierarchy: deep unregister consistency', () {
    test(
      'isRegistered(deep) and unregister(deep) must agree on whether a '
      'grandparent registration is visible',
      () async {
        final grand = DI();
        final parent = DI();
        final child = DI();
        parent.parents.add(grand);
        child.parents.add(parent);

        grand.register<_A>(const _A('from-grand')).end();

        expect(
          child.isRegistered<_A>(),
          isTrue,
          reason: 'isRegistered with default traverse=true sees grandparent',
        );

        // Now unregister from child with default options.
        (await child.unregister<_A>().toAsync().value).end();

        // After unregister, isRegistered should be false — otherwise the
        // contract is broken.
        expect(
          child.isRegistered<_A>(),
          isFalse,
          reason: 'unregister(traverse: true, removeAll: true) must drop the '
              'dep from every ancestor isRegistered would have seen — '
              'otherwise the two are inconsistent.',
        );
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Same as above but the dep is only at direct parent.
  // ─────────────────────────────────────────────────────────────────────────
  group('hierarchy: direct-parent unregister', () {
    test(
      'child.unregister(traverse: true) removes a direct-parent dep',
      () async {
        final parent = DI();
        final child = DI();
        child.parents.add(parent);

        parent.register<_A>(const _A('from-parent')).end();
        expect(child.isRegistered<_A>(), isTrue);

        (await child.unregister<_A>().toAsync().value).end();
        expect(child.isRegistered<_A>(), isFalse);
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 3. The same asymmetry on the K side.
  // ─────────────────────────────────────────────────────────────────────────
  group('hierarchy K: deep unregister consistency', () {
    test(
      'isRegisteredK(deep) and unregisterK(deep) must agree',
      () async {
        final grand = DI();
        final parent = DI();
        final child = DI();
        parent.parents.add(grand);
        child.parents.add(parent);

        grand.register<_A>(const _A('from-grand')).end();
        expect(
          child.isRegisteredK(TypeEntity(_A)),
          isTrue,
        );
        (await child.unregisterK(TypeEntity(_A)).toAsync().value).end();
        expect(
          child.isRegisteredK(TypeEntity(_A)),
          isFalse,
          reason: 'unregisterK(traverse: true) must walk every ancestor '
              'isRegisteredK would have seen.',
        );
      },
    );
  });
}
