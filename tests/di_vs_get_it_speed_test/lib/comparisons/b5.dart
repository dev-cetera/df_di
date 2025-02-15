import 'package:df_di/df_di.dart';
import 'package:get_it/get_it.dart';

import 'run_benchmark_comparison.dart';

Future<void> b5() async {
  await runBenchmarkComparison(
    'Comparing - register then get lazy singletons',
    getIt: () {
      final container1 = GetIt.asNewInstance();
      container1.registerLazySingleton<Map<int, String>>(() => {1: 'some data'});
      container1.get<Map<int, String>>();
    },
    di: () {
      final container2 = DI();
      container2.registerLazy<Map<int, String>>(() => SyncOk({1: 'some data'}));
      container2.getSingleton<Map<int, String>>();
    },
  );
}
