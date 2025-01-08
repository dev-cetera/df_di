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

import 'dart:collection';

import 'package:df_di/df_di.dart';

import 'package:test/test.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() {
  group(
    'Testing basics',
    () {
      test(
        '- The value returned by "register" is the same as the value registered',
        () {
          final di = DI();
          final a = <int>[1, 2, 3];
          final b = di.register<List<int>>(a);
          expect(
            a,
            b,
          );
          expect(
            a.hashCode,
            b.hashCode,
          );
        },
      );

      test(
        '- The exact registered value is returned by "register"',
        () async {
          final di = DI();
          final a = Future<int>.delayed(const Duration(milliseconds: 100), () => 1);
          final b = di.register<int>(a);
          expect(
            1,
            await b,
          );
        },
      );
    },
  );

  group(
    'Testing "register" and "get"',
    () {
      test(
        '- Get with "dynamic" or "Object" should return the first registered value',
        () {
          final di = DI();
          di.register<int>(1);
          di.register<String>('2');
          di.register<bool>(false);
          expect(
            di.getOrNull<int>(),
            1,
          );
        },
      );

      test(
        '- Register "String", get "String"',
        () {
          final di = DI();
          expect(
            di.register<String>('Hello World!'),
            di.getOrNull<String>(),
          );
          expect(
            di.getOrNull<String>(),
            'Hello World!',
          );
        },
      );

      test(
        '- Register "Set<int>", get "Iterable"',
        () {
          final di = DI();
          final a = di.register<Set<int>>({1, 2, 3});
          expect(
            di.getOrNull<Iterable<dynamic>>(),
            a,
          );
          expect(
            di.getOrNull<Iterable<Object>>(),
            a,
          );
          expect(
            di.getOrNull<LinkedHashSet<Object>>(),
            a,
          );
        },
      );

      test(
        '- Register "Map<String, Map<String, int>>, get "Map"',
        () {
          final di = DI();
          final a = <String, Map<String, int>>{
            'a': {
              'b': 3,
            },
          };
          expect(
            di.register<Map<String, Map<String, int>>>(a),
            di.getOrNull<Map<String, Map<String, int>>>(),
          );
          expect(
            di.getOrNull<Map<dynamic, dynamic>>(),
            a,
          );
          expect(
            di.getOrNull<Map<Object, Object>>(),
            a,
          );
          expect(
            di.getOrNull<LinkedHashMap<Object, Object>>(),
            a,
          );
        },
      );
    },
  );

  group(
    'Testing Future registrations',
    () {
      test(
        '- Unregister Futures',
        () async {
          final di = DI();
          final value = Future.value(1);
          di.register(value);
          expect(
            1,
            di.registry.getGroup(groupEntity: di.focusGroup).length,
          );
          final valueGot = await di.getOrNull<int>();
          expect(
            1,
            valueGot,
          );
          expect(
            1,
            di.registry.getGroup(groupEntity: di.focusGroup).length,
          );
        },
      );
    },
  );

  group(
    'Testing unregistering',
    () {
      test(
        '- 1',
        () async {
          final di = DI();
          final a = await di.register<int>(Future.value(1));
          final b = await di.register<double>(Future.value(2.0));
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
            di.registry.getGroup(groupEntity: di.focusGroup).length,
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
            2,
            di.registry.getGroup(groupEntity: di.focusGroup).length,
          );
          di.unregister<int>();
          di.unregister<double>();
          expect(
            0,
            di.registry.getGroup(groupEntity: di.focusGroup).length,
          );
        },
      );
    },
  );
}
