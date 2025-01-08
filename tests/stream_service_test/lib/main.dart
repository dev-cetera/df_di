// ignore_for_file: invalid_use_of_protected_member

import 'package:df_di/df_di.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  late CountingService countingService;

  @override
  void initState() {
    super.initState();
    countingService = CountingService();
    countingService.init(60);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () {
                if (!countingService.disposed) {
                  countingService.dispose();
                }
                setState(() {
                  countingService = CountingService();
                });
                countingService.init(60);
              },
              child: const Text('New Service'),
            ),
            FilledButton(
              onPressed: () {
                if (!countingService.initialized) {
                  print('Cannot restart a service that has not been initialized.');
                  return;
                }

                if (countingService.disposed) {
                  print('Cannot restart a disposed service.');
                  return;
                }

                countingService.restartService(60);
              },
              child: const Text('Restart Service'),
            ),
            FilledButton(
              onPressed: () {
                if (!countingService.disposed) {
                  countingService.dispose();
                }
              },
              child: const Text('Dispose Service'),
            ),
            ValueListenableBuilder(
              valueListenable: countingService.pValue,
              builder: (context, value, child) {
                return Text('$value');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CountingService extends StreamService<int, int> {
  final pValue = ValueNotifier(0);
  @override
  ServiceListeners<int> provideInitListeners() {
    return [
      ...super.provideInitListeners(),
      (data) => print('Initialized with data: $data'),
    ];
  }

  @override
  ServiceListeners<void> provideDisposeListeners() {
    return [
      ...super.provideDisposeListeners(),
      (_) => print('Disposed!'),
    ];
  }

  @override
  Stream<int> provideInputStream(int params) async* {
    var counter = 0;
    while (counter <= params) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      yield counter++;
    }
  }

  @override
  ServiceListeners<int> provideOnPushToStreamListeners() {
    return [
      ...super.provideOnPushToStreamListeners(),
      (data) => print('[CountingService]: $data'),
      (data) => pValue.value = data,
    ];
  }
}
