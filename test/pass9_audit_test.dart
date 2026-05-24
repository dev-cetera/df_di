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
// Audit pass 9: directional asymmetry between `.parents` (bottom-up) and
// `_maybeFinish`'s child-walk (top-down via childrenContainer).

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

final class _A {
  const _A([this.tag = '']);
  final String tag;
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // 1. child.parents.add(parent) (bottom-up wire only). child.untilSuper<X>
  //    sets up its completer in CHILD's registry. parent.register<X>(value)
  //    only walks parent + parent.childrenContainer's MATERIALISED children
  //    — which does NOT include `child` because parent.childrenContainer
  //    doesn't know about it.
  //
  //    Expected contract: child.untilSuper<X> resolves when ANY ancestor
  //    registers X. Otherwise the hierarchy traversal for `getDependency`
  //    (which DOES walk `.parents` transitively) is inconsistent with the
  //    completer wake-up walk.
  // ─────────────────────────────────────────────────────────────────────────
  group('hierarchy: child.untilSuper sees parent register', () {
    test(
      'child.parents.add(parent) wires the parent for child.getDependency '
      '— and child.untilSuper must also wake up on parent.register',
      () async {
        final parent = DI();
        final child = DI();
        child.parents.add(parent);
        // Start a waiter from child BEFORE the parent registers.
        final waiter = child.untilSuper<_A>().toAsync().value;
        // Parent registers. The child's completer should fire.
        parent.register<_A>(const _A('from-parent')).end();
        final result = await waiter.timeout(
          const Duration(milliseconds: 200),
          onTimeout: () => Err<_A>('child.untilSuper timed out'),
        );
        UNSAFE:
        expect(
          result.isOk(),
          isTrue,
          reason: 'child.untilSuper must resolve when an ANCESTOR registers — '
              'otherwise the package has a directional asymmetry: '
              'getDependency walks parents transitively but _maybeFinish '
              'only walks materialised childrenContainer children.',
        );
      },
    );
  });
}
