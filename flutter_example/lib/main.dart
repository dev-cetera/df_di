import 'package:flutter/material.dart';
import 'package:df_di/df_di.dart';

// Here we test if we can successfully get a registered value using getT when
// the app is compiled with WASM and minification via "flutte run -d --wasm --release".
void main() {
  DI.global.register<List<int>>([42]);
  final answer = DI.global.getT(List<int>).unwrap().unwrap();
  // Should print 42.
  print(answer);
  runApp(MaterialApp(home: Scaffold(body: Text('$answer'))));
}
