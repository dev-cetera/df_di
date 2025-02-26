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

// import 'dart:async';

// import 'package:df_di/df_di.dart';
import 'package:df_di/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// Iterable<int> sort(Iterable<int> values) sync* {
//   for (final e in values) {}
// }

Future<Object> main() async {
  final di = DI();
  di.registerLazy<String>(() => SyncOk('Lazy init!'));
  print(di.getLazySingleton<String>());
  print(di.getLazySingletonUnsafe<String>());
  print(di.getFactory<String>());
  print(di.getFactoryUnsafe<String>());
  print(di.get<Lazy<String>>());
  print(di.getLazy<String>());
  print(di.getLazyUnsafe<String>());
  print('---');
  print(di.getLazySingletonT<String>(String));
  print(di.getLazySingletonUnsafeT<String>(String));
  print(di.getFactoryT<String>(String));
  print(di.getFactoryUnsafeT<String>(String));
  print(di.getT<Lazy<String>>(Lazy<String>));
  print(di.getLazyT<String>(String));
  print(di.getLazyUnsafeT<String>(String));
  di.unregisterLazy<String>();

  return 1;
}
