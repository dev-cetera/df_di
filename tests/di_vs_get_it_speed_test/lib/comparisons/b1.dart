import 'package:df_di/df_di.dart';
import 'package:get_it/get_it.dart';

import 'run_benchmark_comparison.dart';

Future<void> b1() async {
  GetIt.instance.registerSingleton<Map<int, String>>({1: 'some data'});
  DI.root.register<Map<int, String>>({1: 'some data'});
  var lengthA = 0;
  var lengthB = 0;
  await runBenchmarkComparison(
    'Comparing: Getting a registered value.',
    getIt: () {
      final a = GetIt.instance.get<Map<int, String>>();
      final b = a.length;
      lengthA += b;
    },
    di: () {
      final a = DI.root.getSyncUnsafe<Map<int, String>>();
      final b = a.length;
      lengthB += b;
    },
  );
  print(lengthA);
  print(lengthB);
}
