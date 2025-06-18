// ignore_for_file: unused_local_variable

import 'package:df_di/df_di.dart';

void register() async {
  await Future<void>.delayed(const Duration(seconds: 1));
  DI.global.register(Child()).end();
  // ignore: invalid_use_of_protected_member
  print(DI.global.registry.state);
}

void main() async {
  register();
  print(await DI.global.untilSuper<int>().unwrap());
}

class Grandparent {}

class Parent extends Grandparent {}

class Child extends Parent {}
