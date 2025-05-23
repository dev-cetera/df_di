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
    'Testing the registration of a DI instance (child), getting it and unregistering it.',
    () async {
      final di = DI();
      final child = DI();
      di.register(child);
      expect(child, di.getUnsafe<DI>());
      expect(child, di.getUnsafeT(DI));
      expect(di.isRegistered<DI>(), true);
      expect(di.isRegisteredT(DI), true);
      di.unregister<DI>();
      expect(di.isRegistered<DI>(), false);
      expect(di.isRegisteredT(DI), false);
    },
  );
  test(
    'Testing the lazy registration of a DI instance (child), getting it and unregistering it.',
    () {
      final di = DI();
      final child = DI();
      di.registerLazy<DI>(() => Sync.value(Ok(child)));
      expect(child, di.getLazySingletonUnsafe<DI>());
      expect(child, di.getLazySingletonUnsafeT(DI));
      expect(true, di.isRegistered<DI>());
      di.unregister<DI>();
      expect(false, di.isRegistered<DI>());
    },
  );
  test('Testing children of children.', () async {
    final c1 = DI();
    c1.register<int>(1);
    final c4 = c1.child().child().child().child();
    expect(1, c4.getUnsafe<int>());
    expect(true, c4.isRegistered<int>());
    c1.unregister<int>();
    expect(false, c4.isRegistered<int>());
  });
}
