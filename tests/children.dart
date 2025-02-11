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
  group(
    'Testing children',
    () {
      test(
        '- Testing if a child gets created and unregistered',
        () async {
          final di = DI();
          final child = DI();
          di.registerValue(child);
          expect(
            child,
            di.getUnsafe<DI>(),
          );
          di.unregister<DI>();
          print(di.get<DI>());
          expect(
            di.get<DI>().isNone(),
            true,
          );
        },
      );
      test(
        '- Testing singletons',
        () async {
          final di = DI();
          di.registerLazy<int>(() => const Sync(Ok(1)));
          expect(
            1,
            di.getSingleton<int>().sync().unwrap().value.unwrap().unwrap(),
          );
        },
      );
      test(
        '- Testing singletons',
        () async {
          final c1 = DI();
          c1.registerValue<int>(1);
          final c4 = c1.child().child().child().child();
          expect(
            1,
            c4.getUnsafe<int>(),
          );
          c1.unregister<int>();
          expect(
            true,
            c4.getOrNone<int>().isNone(),
          );
        },
      );
    },
  );
}
