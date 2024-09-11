//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// ignore_for_file: invalid_use_of_protected_member

import 'package:df_di/df_di.dart';

import 'package:test/test.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() {
  group(
    'Testing unregister',
    () {
      test(
        '- Unregistering completed futures',
        () async {
          final di = DIContainer(
            unregisterRedundantFutures: false,
          );
          final a = await di.register<int>(
            Future.value(1),
            onUnregister: (e) {
              print('Unregistering $e');
            },
          );
          final b = await di.register<double>(
            Future.value(2.0),
            onUnregister: (e) {
              print('Unregistering $e');
            },
          );
          expect(
            1,
            a,
          );
          expect(
            2.0,
            b,
          );
          expect(
            2,
            di.registry.getGroup(groupKey: di.focusGroup).length,
          );
          expect(
            1,
            await di.getOrNull<int>(),
          );
          expect(
            2.0,
            await di.getOrNull<double>(),
          );
          expect(
            4,
            di.registry.getGroup(groupKey: di.focusGroup).length,
          );
          di.unregister<int>();
          di.unregister<double>();
          expect(
            0,
            di.registry.getGroup(groupKey: di.focusGroup).length,
          );
        },
      );
      test(
        '- Unregistering uncompleted futures',
        () async {
          final di = DIContainer(
            unregisterRedundantFutures: false,
          );
          di.register<int>(
            Future.value(1),
            onUnregister: (e) {
              print('Unregistering $e');
            },
          );
          di.getOrNull<int>();

          di.unregister<int>();
        },
      );
    },
  );
}
