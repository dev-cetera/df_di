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

class Test1 {}

class Test2 {}

class Parent3 {}

class Test3 extends Parent3 {}

class Test4 {}

final di = DI();

void setup() async {
  // di.register(Future<Test1>.value(Test1()));
  // await Future<void>.delayed(const Duration(seconds: 1));
  // di.register(Future<Test2>.value(Test2()));
  // await Future<void>.delayed(const Duration(seconds: 1));
  di.register(Future<int>.delayed(const Duration(seconds: 2), () => 1)).end();
}

void main() async {
  // final e = ReservedSafeFinisher<int>(TypeEntity(int));
  // print(e is ReservedSafeFinisher<num>);
  // // print((ReservedSafeFinisher<int>(TypeEntity(int)) is ReservedSafeFinisher<num>));

  //setup();
  Future.delayed(const Duration(seconds: 1), () {
    di.register<num>(Future.delayed(const Duration(seconds: 2), () => 1)).end();
  });

  print(await di.untilSuper<int>().value);

  // final a = ReservedSafeFinisher<int>(TypeEntity(int));
  // print(a is ReservedSafeFinisher<num>);

  // setup();
  // final u2 = di.until<Parent3>();
  // print(await u2.unwrap());
  // print('DONE!!!');
}
