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

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:flutter/foundation.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() async {
  if (kDebugMode) {
    // Print the current state of di to understand what's registered.
    print(di.registry.state); // We have nothing registered at this point.

    // Register FooBarService as a lazy singleton.
    di.registerSingletonService(FooBarService.new);
    print(di.registry.state); // Now we have a SingletonInst<FooBarService> registered.

    final fooBarService1 = await di.get<FooBarService>();
    print(di.registry
        .state); // SingletonInst<FooBarService> is gone, now we have a FooBarService registered.

    final fooBarService2 = di<FooBarService>();
    final fooBarService3 = di<FooBarService>();
    print(fooBarService1 == fooBarService2); // same instance, prints true
    print(fooBarService2 == fooBarService3); // same instance, prints true

    // Sync vs. Async.

    di.registerSingletonService(SyncServiceExmple.new);
    print(di.get<SyncServiceExmple>() is Future); // false
    print(di.getSync<SyncServiceExmple>());  // use getSync/getSyncOrNull if you expect a sync

    di.registerSingletonService(AsyncServiceExample.new);
    print(di.get<AsyncServiceExample>() is Future); // true
    print(di.getAsync<SyncServiceExmple>()); // use getAsync/getAsyncOrNull if you expect an async
  }
}

/// A new service class that extends [DisposableService].
///
/// - Register via `di.initSingletonService(FooBarService.new);`
/// - Get via `di.get<FooBarService>();`
/// - Unregister via `di.unregister<FooBarService>();`
class FooBarService extends DisposableService {
  /// Gets [_vFooBar] as a [ValueListenable] to discourage tampering with [ValueNotifier].
  ValueListenable<String?> get vFooBar => _vFooBar;
  final _vFooBar = ValueNotifier<String?>(null);

  @override
  FutureOr<void> onInitService() async {
    _vFooBar.value = 'FooBar';
  }

  @override
  FutureOr<void> onDispose() {
    _vFooBar.dispose();
  }
}

// An example of a service that DI will treat as sync.
class SyncServiceExmple extends DisposableService {
  @override
  void onInitService() {}

  @override
  void onDispose() {}
}

// An example of a service that DI will treat as async.
class AsyncServiceExample extends DisposableService {
  @override
  Future<void> onInitService() async {
    await Future<void>.delayed(
      const Duration(seconds: 3),
    );
  }

  @override
  Future<void> onDispose() async {}
}
