import 'dart:collection';

import 'package:df_di/src/test_di.dart';
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
            await b,
            1,
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
            1,
            di.getOrNull(),
          );
          expect(
            1,
            di.getOrNull<Object>(),
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
            'Hello World!',
            di.getOrNull<String>(),
          );
        },
      );

      test(
        '- Register "Set<int>", get "Iterable"',
        () {
          final di = DIContainer();
          final a = di.register<Set<int>>({1, 2, 3});
          expect(
            a,
            di.getOrNull<Iterable<dynamic>>(),
          );
          expect(
            a,
            di.getOrNull<Iterable<Object>>(),
          );
          expect(
            a,
            di.getOrNull<LinkedHashSet<Object>>(),
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
            a,
            di.getOrNull<Map<dynamic, dynamic>>(),
          );
          expect(
            a,
            di.getOrNull<Map<Object, Object>>(),
          );
          expect(
            a,
            di.getOrNull<LinkedHashMap<Object, Object>>(),
          );
        },
      );
    },
  );
}
