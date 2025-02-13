//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:df_di/df_di.dart';
import 'package:df_di/src/_common.dart';

import 'package:test/test.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() {
  test(
    'Testing the registration ofa DI instance, getting it and unregistering it.',
    () async {
      final di = DI();
      final child = DI();
      di.register(child);
      expect(
        child,
        di.getUnsafe<DI>(),
      );
      di.unregister<DI>();
      expect(
        di.get<DI>().isNone(),
        true,
      );
    },
  );
  test(
    'Testing the lazy registration of a DI() instance, getting it and unregistering it.',
    () {
      final di = DI();
      final child = DI();
      di.registerLazy<DI>(() => Sync(Ok(child)));
      expect(
        child,
        di.getSingleton<DI>().unwrap().unwrap(),
      );
      expect(
        true,
        di.isRegistered<DI>(),
      );
      di.unregister<DI>();
      expect(
        false,
        di.isRegistered<DI>(),
      );
    },
  );
  test(
    'Testing children of children.',
    () async {
      final c1 = DI();
      c1.register<int>(1);
      final c4 = c1.child().child().child().child();
      expect(
        1,
        c4.getUnsafe<int>(),
      );
      c1.unregister<int>();
      expect(
        true,
        c4.getSyncOrNone<int>().isNone(),
      );
    },
  );
}
