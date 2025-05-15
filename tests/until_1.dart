// ignore_for_file: unused_local_variable, invalid_use_of_visible_for_testing_member

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

void main() {
  test('test', () async {
    final u1 = DI.global.untilT(int);
    final u2 = DI.global.untilT(double);
    final u3 = DI.global.untilT(String);
    final u4 = DI.global.untilSuper<int>();
    final u5 = DI.global.untilSuper<double>();
    final u6 = DI.global.untilSuper<String>();
    expect(
      (DI.global.finishersK[const DefaultEntity()]
              ?.map((e) => e.toString())
              .toList()
            ?..sort())
          .toString(),
      "[Instance of 'ReservedSafeFinisher<Object>', Instance of 'ReservedSafeFinisher<Object>', Instance of 'ReservedSafeFinisher<Object>']",
    );
  });
}
