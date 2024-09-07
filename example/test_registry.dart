// ignore_for_file: invalid_use_of_protected_member

import 'package:df_di/src/_internal.dart';
import 'package:df_di/src/test_di.dart';

void main() async {
  final di = TestDI();

  di.parent = TestDI();
  di.parent!.register<Future<int>>(Future.value(123));

  // di.register<int>(123);
  print(await di.getOrNull<int>());
  print(di.getOrNull<int>());
}
