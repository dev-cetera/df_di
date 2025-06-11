import 'dart:async';

import 'dart:math';

Future<void> runBenchmarkComparison(
  String name, {
  required FutureOr<void> Function() getIt,
  required FutureOr<void> Function() di,
  int runs = 100000,
  int iterations = 10,
}) async {
  final random = Random();
  final buffer = StringBuffer();

  buffer.writeln('Comparing: $name');
  var getItTimes = <int>[];
  var DITimes = <int>[];

  for (var i = 0; i < iterations; i++) {
    // Randomize test order.
    final order = random.nextBool();

    if (order) {
      getItTimes.add(await _measureTime('get_it', getIt, runs));
      DITimes.add(await _measureTime('df_di', di, runs));
    } else {
      DITimes.add(await _measureTime('df_di', di, runs));
      getItTimes.add(await _measureTime('get_it', getIt, runs));
    }

    // Allow time for GC or other system recovery.
    await Future<dynamic>.delayed(const Duration(milliseconds: 100));
  }

  // Calculate averages.
  final avgGetIt = getItTimes.reduce((a, b) => a + b) ~/ iterations;
  final avgDI = DITimes.reduce((a, b) => a + b) ~/ iterations;

  buffer.writeln('Average Times:');
  buffer.writeln('get_it: ${avgGetIt}ms');
  buffer.writeln('df_di: ${avgDI}ms');

  // Determine winner.
  final isGetItFaster = avgGetIt < avgDI;
  final slowerTime = isGetItFaster ? avgDI : avgGetIt;
  final fasterTime = isGetItFaster ? avgGetIt : avgDI;
  final percentageImprovement =
      ((slowerTime - fasterTime) / slowerTime * 100).round();

  final winner =
      '${isGetItFaster ? 'get_it' : 'df_di'} at $percentageImprovement% faster with $runs runs';
  buffer.writeln('Winner: $winner');

  print(buffer.toString());
}

Future<int> _measureTime(
  String label,
  FutureOr<void> Function() testFunction,
  int runs,
) async {
  final ta = DateTime.now();
  for (var n = 0; n < runs; n++) {
    await testFunction();
  }
  final elapsed = DateTime.now().difference(ta).inMilliseconds;
  return elapsed;
}
