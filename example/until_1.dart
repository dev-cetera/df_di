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

import 'dart:async';

import 'package:df_di/df_di.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() {
  () async {
    await Future<void>.delayed(const Duration(seconds: 2));
    DI.global.register<_T>(() async {
      await Future<void>.delayed(const Duration(seconds: 2));
      return [
        [42],
      ];
    }());
  }();

  // TODO: THIS THROWS AN ERROR IF UNCOMMENTED. Seems like we cant have
  consec(DI.global.untilT(_T).value, (e) => print(e));
  consec(DI.global.until<_T>().value, (e) => print(e));

  // print(DI.global.registry.state);
  // print(DI.global.registry.state[const DefaultEntity()]!.values.first.typeEntity == TypeEntity(List, [TypeEntity(List, [int])]));
  // // {-1001: {913528763: Instance of 'Dependency<ReservedSafeFinisher<List<List<int>>>>'}}
  // // {-1001: {787103782: Instance of 'Dependency<ReservedSafeFinisher<Object>>'}}
  // consec(DI.global.until<_T>().value, (e) => print(e.unwrap()));
  // consec(DI.global.until<_T>().value, (e) => print(e.unwrap()));
  // consec(DI.global.until<_T>().value, (e) => print(e.unwrap()));
  // consec(DI.global.untilK(TypeEntity(_T)).value, (e) => print(e.unwrap()));
  // consec(DI.global.untilK(TypeEntity(_T)).value, (e) => print(e.unwrap()));
  // consec(DI.global.untilK(TypeEntity(_T)).value, (e) => print(e.unwrap()));
  // consec(DI.global.untilT(_T).value, (e) => print(e.unwrap()));
  // consec(DI.global.untilT(_T).value, (e) => print(e.unwrap()));
  // consec(DI.global.untilT(_T).value, (e) => print(e.unwrap()));

  // print(DI.global.registry.state);
}

typedef _T = List<List<int>>;
