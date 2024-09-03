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

// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:df_di/df_di.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() async {
  final di = DI.global;

  // Register FooBarService as a lazy singleton.
  di.registerLazySingletonService(FooBarService.new);
  // Now we have a SingletonInst<FooBarService> registered.
  print(di.registry.state);

  final fooBarService1 = await di.get<FooBarService>();

  // SingletonInst<FooBarService> is gone, now we have a FooBarService registered.
  print(di.registry.state);

  final fooBarService2 = di<FooBarService>();
  final fooBarService3 = di<FooBarService>();

  // Same instances, prints true.
  print(fooBarService1 == fooBarService2);
  print(fooBarService2 == fooBarService3);

  di.registerLazySingletonService(SyncServiceExmple.new);
  print(await di.get<SyncServiceExmple>() is Future); // false
  // Use getSync/getSyncOrNull if you expect a sync.
  print(di.getSync<SyncServiceExmple>());

  di.registerLazySingletonService(AsyncServiceExample.new);
  print(di.registry.state);

  // Use getAsync/getAsyncOrNull if you expect an async.
  print(di.getAsync<AsyncServiceExample>());
  print(di.registry.state);

  di.registerLazySingletonService(CountingService.new);
  print(di.registry.state);
  final coutingService = di.getUsingExactType(type: Descriptor.type(CountingService));
  print(di.registry.state);
  print(coutingService);

  Future.delayed(
    const Duration(seconds: 5),
    () {
      di.unregisterAll(
        onUnregister: (dep) {
          print(dep);
        },
      ).thenOr((_) {
        // Completes when all dependencies are unregistered and removed
        // from di.
        print('Disposed all!');
      });
    },
  );
}

typedef Params = ({String name, int age});

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A new service class that extends [Service].
///
/// - Register via `di.initSingletonService(FooBarService.new);`
/// - Get via `di.get<FooBarService>();`
/// - Unregister via `di.unregister<FooBarService>();`
final class FooBarService extends NoParamsService {
  @override
  void onInitService(_) async {}

  @override
  FutureOr<void> onDispose() {
    print('Disposed $FooBarService');
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class CountingService extends NoParamsStreamingService<int> {
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
