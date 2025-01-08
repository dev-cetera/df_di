import 'package:df_di/df_di.dart';
import 'package:get_it/get_it.dart';

import 'run_benchmark_comparison.dart';

Future<void> b3() async {
  final container1 = GetIt.asNewInstance();
  container1.registerSingleton<Map<int, String>>({1: 'some data'});
  final container2 = DI();
  container2.register<Map<int, String>>({1: 'some data'});
  await runBenchmarkComparison(
    'Comparing - isRegistered',
    getIt: () {
      container1.isRegistered<Map<int, String>>();
    },
    di: () {
      container2.isRegistered<Map<int, String>>();
    },
  );
}
