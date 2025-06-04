// ignore_for_file: unused_local_variable

import 'package:df_di/df_di.dart';

void main() {
  // Prints true true
  {
    final a = TypeEntity(Map<String, dynamic>);
    final b = TypeEntity(Map, [String, dynamic]);
    print(a == b);
    final c = TypeEntity(TypeEntity(Map), [String, dynamic]);
    print(a == c);
  }
  // Prints true true
  {
    print(dynamic);
    final a = TypeEntity('${Map<String, dynamic>}');
    final b = TypeEntity('$Map', ['$String', '$dynamic']);
    print(a == b);
    final c = TypeEntity(TypeEntity(Map), ['$String', 'dynamic']);
    print(a == c);
  }
  // // Prints true true - wont work with minification
  // {
  //   final a = TypeEntity('${Map<String, dynamic>}');
  //   final b = TypeEntity('$Map', ['$String', '$dynamic']);
  //   print(a == b);
  //   final c = TypeEntity(TypeEntity('Map'), ['String', 'dynamic']);
  //   print(a == c);
  // }
}
