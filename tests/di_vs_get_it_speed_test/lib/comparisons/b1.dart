import 'package:df_di/df_di.dart';
import 'package:get_it/get_it.dart';

import 'run_benchmark_comparison.dart';

Future<void> b1() async {
  final container1 = GetIt.asNewInstance();
  container1.registerSingleton<Map<int, String>>({1: 'some data'});
  final container2 = DI();
  container2.register<Map<int, String>>({1: 'some data'});
  await runBenchmarkComparison(
    'Comparing - get:',
    getIt: () {
      container1.get<Map<int, String>>();
    },
    di: () {
      container2.get<Map<int, String>>().unwrap();
    },
  );
}
