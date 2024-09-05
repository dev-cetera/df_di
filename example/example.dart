//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// ignore_for_file: invalid_use_of_protected_member, strict_raw_type

import 'dart:async';
import 'dart:math';

import 'package:df_di/df_di.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() async {
  // print('\n# Get access to the global DI container:\n');
  // final di = DI.global;
  // print(DI.global);
  // print('DI.global == di: ${DI.global == di}');

  // print('\n# Get the state of the global DI container (prints an empty map):\n');
  // print(di.registry.state);

  // print('\n# Create a new DI container:\n');
  // print(DI());

  // print('\n# Use any of the pre-defined containers for your app:\n');
  // print(DI.app); // You can store app settings in here.
  // print(DI.app); // You can contain the global state in here.
  // print(DI.global); // You can contain stuff for the active session in here.
  // print(DI.dev); // A container you can use for or development-only.
  // print(DI.test); // A container you can use for or test-only.
  // print(DI.prod); // A container you can use for or production-only.
  // // Or create your own custom containers:
  // final di1 = DI();
  // print(di1);
  // final di2 = DI();
  // print(di2);

  // print('\n# Register the universe and everything:\n');
  // di.register<int>(42);
  // print(di.get<int>());
  // print(di.getUsingRuntimeType(int));
  // di.registerUsingRuntimeType('42 :)');
  // print(di.getUsingRuntimeType(String));
  // print(di.get<String>());

  DI.app.register(Future<double>.value(pi));
  // DI.app.register<double>(pi);

  print(DI.app.get<double>());
  print('------------');
  DI.app.get<double>();

  // print('\n# Register Futures:\n');
  // DI.prod.register<double>(Future<double>.value(pi));
  // //di.register<double>(Future.delayed(const Duration(milliseconds: 10), () => pi));
  // print('PI is ${await DI.prod.get<double>()}');
  // DI.prod.register<double>(Future<double>.value(e));
  // print('E is ${await DI.prod.get<double>()}');
  // print(DI.prod.registry.state);

  // print('Get access to the global DI container:\n\n');
  // di.register(Future.value('Hello, DI!'));
  // print(di.get<String>()); // print

  // // Register FooBarService as a lazy singleton.
  // di.registerSingletonService(FooBarService.new);

  // // Now we have a SingletonInst<FooBarService> registered.
  // //print(di.registry.state);

  // final fooBarService1 = await di.get<FooBarService>();

  // // SingletonInst<FooBarService> is gone, now we have a FooBarService registered.
  // //print(di.registry.state);

  // final fooBarService2 = di<FooBarService>();
  // final fooBarService3 = di<FooBarService>();

  // // Same instances, prints true.
  // // print(fooBarService1 == fooBarService2);
  // // print(fooBarService2 == fooBarService3);

  // di.registerSingletonService(SyncServiceExmple.new);
  // //print(await di.get<SyncServiceExmple>() is Future); // false
  // //print(di.get<SyncServiceExmple>());

  // di.registerSingletonService(AsyncServiceExample.new);
  // //print(di.registry.state);

  // // Use getAsync/getAsyncOrNull if you expect an async.
  // //print(di.get<AsyncServiceExample>());
  // //print(di.registry.state);

  // di.register((bool params) => CountingService().initService(params));

  // di.registerFactoryService<CountingService, bool>(CountingService.new);
  // //print(di.registry.state);
  // final coutingService = di.getFactory<CountingService, bool>(true);
  // //print(coutingService);
  // //print(di.registry.state);

  // Future.delayed(
  //   const Duration(seconds: 10),
  //   () {
  //     di.unregisterAll(
  //       onUnregister: (dep) {
  //         print(dep);
  //       },
  //     ).thenOr((_) {
  //       // Completes when all dependencies are unregistered and removed
  //       // from di.
  //       print('Disposed all!');
  //     });
  //   },
  // );
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A new service class that extends [Service].
///
/// - Register via `di.initSingletonService(FooBarService.new);`
/// - Get via `di.get<FooBarService>();`
/// - Unregister via `di.unregister<FooBarService>();`
final class FooBarService extends Service<Object> {
  @override
  void onInitService(_) async {}

  @override
  FutureOr<void> onDispose() {
    print('Disposed $FooBarService');
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class CountingService extends StreamingService<int, bool> {
  @override
  Stream<int> provideInputStream() async* {
    for (var n = 0; n < 100; n++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      yield n;
    }
  }

  @override
  void onPushToStream(int data) {
    print('[CountingService]: $data');
  }

  @override
  FutureOr<void> onDispose() {
    print('Disposed $CountingService');
    return super.onDispose();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// An example of a service that DI will treat as sync.
final class SyncServiceExmple extends Service<Object> {
  @override
  void onInitService(_) {}

  @override
  Future<void> onDispose() async {}
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// An example of a service that DI will treat as async.
final class AsyncServiceExample extends Service<Object> {
  @override
  Future<void> onInitService(_) async {
    await Future<void>.delayed(
      const Duration(seconds: 3),
    );
  }

  @override
  void onDispose() {}
}
