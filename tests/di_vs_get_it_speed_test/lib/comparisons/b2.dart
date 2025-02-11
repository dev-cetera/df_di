import 'package:df_di/df_di.dart';
import 'package:get_it/get_it.dart';

import 'run_benchmark_comparison.dart';

Future<void> b2() async {
  await runBenchmarkComparison(
    'Comparing - register then get:',
    getIt: () {
      final container1 = GetIt.asNewInstance();
      container1.registerSingleton<Map<int, String>>({1: 'some data'});
      container1.get<Map<int, String>>();
    },
    di: () {
      final container2 = DI();
      container2.registerValue<Map<int, String>>({1: 'some data'});
      container2.get<Map<int, String>>();
    },
  );
}
