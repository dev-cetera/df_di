// ignore_for_file: unused_local_variable

import 'package:df_di/df_di.dart';

void main() {
  final u1 = DI.global.untilT(int);
  final u2 = DI.global.untilT(double);
  final u3 = DI.global.untilT(String);
  print(DI.global.finishers);
}

// THIS IS THE EXPECTED OUTPUT:
void main2() {
  final u1 = DI.global.until<int>();
  final u2 = DI.global.until<double>();
  final u3 = DI.global.until<String>();
  print(DI.global.finishers);
}
