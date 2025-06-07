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

// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:df_di/df_di.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() async {
  () async {
    await Future<void>.delayed(const Duration(seconds: 1));
    DI.global.register<_T>(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return [
        [42],
      ];
    }());
  }();

  consec(DI.global.untilExactlyT<_T>(_T).value, (e) => print(e));
  consec(DI.global.untilSuper<List<Object>>().value, (e) => print(e));
  consec(DI.global.untilSuper<List<Object>>().value, (e) => print(e));
  consec(DI.global.untilExactlyT<_T>(_T).value, (e) => print(e));
  consec(DI.global.untilExactlyT(_T).value, (e) => print(e));
  consec(DI.global.untilSuper<_T>().value, (e) => print(e));
  consec(DI.global.untilSuper<_T>().value, (e) => print(e));
}

typedef _T = List<List<int>>;
