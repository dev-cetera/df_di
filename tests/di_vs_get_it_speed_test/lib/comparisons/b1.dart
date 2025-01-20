import 'package:df_di/df_di.dart';
import 'package:get_it/get_it.dart';

import 'run_benchmark_comparison.dart';

Future<void> b1() async {
  final container1 = GetIt.asNewInstance();
  container1.registerSingleton<Map<int, String>>({1: 'some data'});
  final container2 = DI();
  container2.register<Map<int, String>>(unsafe: () => {1: 'some data'});
  await runBenchmarkComparison(
    'Comparing - get:',
    getIt: () {
      final a = container1.get<Map<int, String>>();
    },
    di: () {
      final a = container2.getSync<Map<int, String>>().unwrap().value;
    },
  );
}
