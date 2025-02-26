import 'package:flutter/material.dart';
import 'package:df_di/df_di.dart';

void main() {
  DI.global.register<int>(42);
  final answer = DI.global<int>().unwrap();
  runApp(MaterialApp(home: Scaffold(body: Text('$answer'))));
}
