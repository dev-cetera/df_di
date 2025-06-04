import 'package:flutter/material.dart';
import 'package:df_di/df_di.dart';

// Here we test if we can successfully get a registered value using getT when
// the app is compiled with WASM and minification via "flutte run -d --wasm --release".
void main() {
  DI.global.register<List<int>>([42]);
  final answer = DI.global.getT(List<int>).unwrap().unwrap();
  final output = '${List<int>}: $answer';

  print(output);
  // Running with WASM, release, and optimization level 4:
  // flutter build web --wasm --release --optimization-level 4
  // dart pub global activate dhttpd
  // dhttpd --path build/web --port 8080
  // KILLING:
  // lsof -i :8080
  // kill -9 <PID>
  final isObfuscated = 'List<int>' != '${List<int>}';
  print('Is obfuscated: $isObfuscated');
  testObfuscationIssue();
  runApp(MaterialApp(home: Scaffold(body: Text(output))));
}

void testObfuscationIssue() {
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
}
