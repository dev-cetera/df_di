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

import 'package:test/test.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() {
  test(
    'Testing the until function.',
    () async {
      final di = DI();
      Future.delayed(
        const Duration(seconds: 1),
        () => di.register<int>(1),
      );
      Future.delayed(
        const Duration(seconds: 1),
        () => di.register<String>('Hello!'),
      );
      await di.until<int>().unwrap();
      final value = di.until<int>().unwrap();
      expect(1, await value);
      expect('Hello!', await di.until<String>().unwrap());
    },
  );

  test(
    'Testing the untilT function.',
    () async {
      final di = DI();
      Future.delayed(
        const Duration(seconds: 1),
        () => di.register<int>(1),
      );
      Future.delayed(
        const Duration(seconds: 1),
        () => di.register<String>('Hello!'),
      );
      await di.untilT(int).unwrap();
      final value = di.untilT(int).unwrap();
      expect(1, await value);
      expect('Hello!', await di.untilT(String).unwrap());
    },
  );
  test(
    'Testing the until function with a service.',
    () async {
      final di = DI();
      final service = Future<TestService>.delayed(const Duration(seconds: 1), () => TestService());
      Future.delayed(
        const Duration(seconds: 4),
        () => di.registerAndInitService<TestService>(service),
      );
      final value = await di.until<TestService>().unwrap();
      expect(await service, value);
    },
  );
}

base class TestService extends Service {}
