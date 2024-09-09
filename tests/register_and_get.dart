import 'dart:collection';

import 'package:df_di/src/test_di.dart';
import 'package:test/test.dart';

void main() {
  // 1.
  group('Testing the return value of "register"', () {
    final di = DIContainer();
    test('- The exact registered value is returned by "register"', () {
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
    });

    test('- The exact registered value is returned by "register"', () async {
      final a = Future<int>.delayed(const Duration(milliseconds: 100), () => 1);
      final b = di.register(a);
      expect(
        await b,
        1,
      );
    });
  });

  // 2.
  group('Testing "register" and "get"', () {
    final di = DIContainer();
    test('- Register and get a String', () {
      expect(di.register('Hello World!'), di.getOrNull<String>());
      expect('Hello World!', di.getOrNull<String>());
    });
    test('- Register "Set<int>", get "Iterable"', () {
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
    });

    test('- Register "Map<String, Map<String, int>>, get "Map"', () {
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
    });
  });
}
