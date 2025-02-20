import 'package:df_di/df_di.dart';
import 'package:get_it/get_it.dart';

import 'run_benchmark_comparison.dart';

Future<void> b4() async {
  final container1 = GetIt.asNewInstance();
  container1.registerLazySingleton<Map<int, String>>(() => {1: 'some data'});
  final container2 = DI();
  container2.registerLazy<Map<int, String>>(() => SyncOk({1: 'some data'}));
  await runBenchmarkComparison(
    'Comparing - get lazy singletons',
    getIt: () {
      container1.get<Map<int, String>>();
    },
    di: () {
      container2.getLazySingleton<Map<int, String>>();
    },
  );
}
