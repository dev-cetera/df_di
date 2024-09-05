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

import 'package:df_di/df_di.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() async {
  print('\n# Get access to the global DI container:\n');
  print(DI.session);

  print('\n# Get the state of the global DI container (prints an empty map):\n');
  print(DI.global.registry.state);

  print('\n# Create a new DI container:\n');
  print(DI());

  print('\n# Register and print the answer to life, the universe and everything:\n');
  final test = DI.test;
  test.register<int>(42);
  print(test.get<int>());
  test.registerUsingRuntimeType('42');
  print('dsd');
  print(test.getUsingRuntimeType(String));
  

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
