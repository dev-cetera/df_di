import 'package:df_di/df_di.dart';
import 'package:get_it/get_it.dart';

import 'run_benchmark_comparison.dart';

Future<void> b2() async {
  await runBenchmarkComparison(
    'Comparing: Registering value.',
    getIt: () {
      final container1 = GetIt.asNewInstance();
      container1.registerSingleton<Map<int, String>>({1: 'some data'});
    },
    di: () {
      final container2 = DI();
      container2.register<Map<int, String>>({1: 'some data'}).end();
    },
  );
}
