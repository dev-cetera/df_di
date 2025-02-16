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

// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:df_di/src/core/di/_di_base.dart';

import 'package:test/test.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() {
  //  final di = DI();
  // di.register<int>(Future.value(1));
  // print(di.register<int>(Future.value(2)).isErr());
  // print(await di.until<int>().unwrap());
  // print(di.until<num>().unwrap());

  test('Testing the until function with a single registaration.', () async {
    final di = DI();
    Future.delayed(const Duration(seconds: 1), () {
      di.register<int>(1);
    });

    print(await di.untilT(String).unwrap());

    // Future.delayed(const Duration(seconds: 3), () {
    //   di.register(1000);
    // });

    // print(await di.until<String>().unwrap());
    // print(di.until<num>().unwrap());
    // print(di.until<int>().unwrap());
    // print(await di.until<num>().unwrap());
    // print(di.registry.state);
    // print('111');

    // //print(di<SafeFinisher<int>>().unwrap());

    // final a = di.registry
    //     .getDependencies<ReservedSafeFinisher>()
    //     .map((e) => e.value.unwrap())
    //     .cast<ReservedSafeFinisher>();

    // print(a.where((e) {
    //   print(e.resolvable().value as FutureOr<Result<num>>);
    //   print(e.type == int);
    //   return [e] is List<ReservedSafeFinisher<int>>;
    // }));
    // print(a.where((e) => e.type == int));

    // print(await di.until<num>().unwrap());
  });

  // test('Testing the until function.', () async {
  //   final di = DI();
  //   Future.delayed(const Duration(seconds: 1), () => di.register<int>(1));
  //   Future.delayed(
  //     const Duration(seconds: 1),
  //     () => di.register<String>('Hello!'),
  //   );
  //   await di.until<int>().unwrap();
  //   final value = di.until<int>().unwrap();
  //   expect(1, await value);
  //   expect('Hello!', await di.until<String>().unwrap());
  // });
  // test('Testing the untilT function.', () async {
  //   final di = DI();
  //   Future.delayed(const Duration(seconds: 1), () => di.register<int>(1));
  //   Future.delayed(
  //     const Duration(seconds: 1),
  //     () => di.register<String>('Hello!'),
  //   );
  //   await di.untilT(int).unwrap();
  //   final value = di.untilT(int).unwrap();
  //   expect(1, await value);
  //   expect('Hello!', await di.untilT(String).unwrap());
  // });
  // test('Testing the until function with a service.', () async {
  //   final di = DI();
  //   final service = Future<TestService>.delayed(
  //     const Duration(seconds: 1),
  //     () => TestService(),
  //   );
  //   Future.delayed(
  //     const Duration(seconds: 4),
  //     () => di.registerAndInitService<TestService>(service),
  //   );
  //   final value = await di.until<TestService>().unwrap();
  //   expect(await service, value);
  //});
}

base class TestService extends Service {}
