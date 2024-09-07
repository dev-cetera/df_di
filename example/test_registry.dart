// ignore_for_file: invalid_use_of_protected_member

import 'package:df_di/src/_internal.dart';
import 'package:df_di/src/test_di.dart';

void main() async {
  final di = TestDI();

  Future.delayed(const Duration(seconds: 3), () {
    di.register<int>(Future.value(123));
  });

  print(await di.untilOrNull<int>());
}
