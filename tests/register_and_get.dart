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

import 'dart:collection';

import 'package:df_di/df_di.dart';

import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------

  group(
    'Testing basics',
    () {
      test(
        '- The value returned by "register" is the same as the value registered',
        () {
          final di = DIContainer();
          final a = <int>[1, 2, 3];
          final b = di.register(a);
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
          final di = DIContainer();
          final a = Future<int>.delayed(const Duration(milliseconds: 100), () => 1);
          final b = di.register(a);
          expect(
            1,
            await b,
          );
        },
      );
    },
  );

  // ---------------------------------------------------------------------------

  group(
    'Testing "register" and "get"',
    () {
      test(
        '- Get with "dynamic" or "Object" should return the first registered value',
        () {
          final di = DIContainer();
          di.register(1);
          di.register('2');
          di.register(false);
          expect(
            di.getOrNull(),
            1,
          );
          expect(
            di.getOrNull<Object>(),
            1,
          );
        },
      );

      test(
        '- Register "String", get "String"',
        () {
          final di = DIContainer();
          expect(
            di.register('Hello World!'),
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
          final di = DIContainer();
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
          final di = DIContainer();
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

  // ---------------------------------------------------------------------------

  group(
    'Testing Future registrations',
    () {
      test(
        '- Do not unregister Futures',
        () async {
          final di = DIContainer();
          final value = Future.value(1);
          di.register(value);
          expect(
            1,
            di.registry.getGroup(groupKey: di.focusGroup)?.length,
          );
          final valueGot = await di.getOrNull<int>();
          expect(
            1,
            valueGot,
          );
          expect(
            2,
            di.registry.getGroup(groupKey: di.focusGroup)?.length,
          );
        },
      );

      test(
        '- Do unregister Futures',
        () async {
          final di = DIContainer();
          final value = Future.value(1);
          di.register(value);
          expect(
            1,
            di.registry.getGroup(groupKey: di.focusGroup)?.length,
          );
          final valueGot = await di.getOrNull<int>(unregisterRedundantFutures: true);
          expect(
            1,
            valueGot,
          );
          expect(
            1,
            di.registry.getGroup(groupKey: di.focusGroup)?.length,
          );
        },
      );
    },
  );

  // ---------------------------------------------------------------------------

  group(
    'Testing unregistering',
    () {
      test(
        '- 1',
        () async {
          final di = DIContainer();
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
            di.registry.state[di.focusGroup]?.length,
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
            di.registry.state[di.focusGroup]?.length,
          );
          di.unregister<int>();
          di.unregister<double>();
          expect(
            null,
            di.registry.state[di.focusGroup]?.length,
          );
        },
      );

      // test(
      //   '- 2',
      //   () async {
      //     final di = DIContainer();
      //     final a = Future<int>.delayed(const Duration(milliseconds: 100), () => 1);
      //     final b = di.register(a);
      //     expect(
      //       await b,
      //       1,
      //     );
      //   },
      // );
    },
  );
}
