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
  group(
    'Testing until',
    () {
      // test(
      //   '- 1',
      //   () async {
      //     final di = DI();
      //     di.register<int>(Future.value(1));
      //     final value = await di.until<int>();
      //     expect(1, value);
      //   },
      // );
      test(
        '- 2',
        () async {
          final di = DI();
          final value1 = Future.value(1);
          Future.delayed(
            const Duration(seconds: 1),
            () => di.register<int>(value1),
          );

          final value = di.until<int>();
          print(di.completers?.registry.state);
          expect(1, await value);
        },
      );
      // test(
      //   '- 2',
      //   () async {
      //     final di = DI();
      //     final service =
      //         Future<TestService>.delayed(const Duration(seconds: 1), () => TestService());
      //     Future.delayed(
      //       const Duration(seconds: 4),
      //       () => di.registerService<TestService>(service),
      //     );
      //     final value = await di.until<TestService>();
      //     expect(await service, value);
      //   },
      // );
    },
  );
}

base class TestService extends Service {}
