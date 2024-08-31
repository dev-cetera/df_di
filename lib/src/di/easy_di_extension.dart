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

import '../_index.g.dart';
import '../_utils/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension EasyDIExtension on DI {
  /// Registers a [DisposableService] as a singleton. When [get] is first called
  /// with [T] and [key], [DI] creates, initializes, and returns a new instance
  /// of [T]. All subsequent calls to [get] return the same instance.
  ///
  /// ```dart
  /// // Example:
  /// di.initSingletonService(FooBarService.new);
  /// final fooBarService1 = di.get<FooBarService>();
  /// final fooBarService2 = di.get<FooBarService>();
  /// print(fooBarService1 == fooBarService2); // true
  /// ```
  void registerSingletonService<T extends DisposableService>(
    Constructor<T> constructor, {
    DIKey key = DIKey.defaultKey,
  }) {
    registerSingleton(
      initService(constructor),
      key: key,
      onUnregister: _onUnregisterService,
    );
  }

  /// Registers a singleton instance of [T] with the given [constructor]. When [get]
  /// is called with [T] and [key], the same instance will be returned.
  ///
  /// ```dart
  /// di.registerSingleton(FooBarService.new);
  /// final fooBarService1 = di.get<FooBarService>();
  /// final fooBarService2 = di.get<FooBarService>();
  /// print(fooBarService1 == fooBarService2); // true
  /// ```
  void registerSingleton<T>(
    InstConstructor<T> constructor, {
    DIKey key = DIKey.defaultKey,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    register(
      SingletonInst<T>(constructor),
      key: key,
      onUnregister: _dynamicOnUnregister<T>(onUnregister),
    );
  }

  /// Registers a [DisposableService] as a factory. Each time [get] is called
  /// with T] and [key], [DI] creates, initializes, and returns a new instance
  /// of [T].
  ///
  /// ```dart
  /// // Example:
  /// di.registerFactoryService(FooBarService.new);
  /// final fooBarService1 = di.get<FooBarService>();
  /// final fooBarService2 = di.get<FooBarService>();
  /// print(fooBarService1 == fooBarService2); // false
  /// ```
  void registerFactoryService<T extends DisposableService>(
    Constructor<T> constructor, {
    DIKey key = DIKey.defaultKey,
  }) {
    registerFactory(
      initService(constructor),
      key: key,
      onUnregister: _onUnregisterService,
    );
  }

  /// Registers a factory that creates a new instance of [T] each time [get] is
  /// called with [T] and [key].
  ///
  /// ```dart
  /// di.registerFactory(FooBarService.new);
  /// final fooBarService1 = di.get<FooBarService>();
  /// final fooBarService2 = di.get<FooBarService>();
  /// print(fooBarService1 == fooBarService2); // false
  /// ```
  void registerFactory<T>(
    InstConstructor<T> constructor, {
    DIKey key = DIKey.defaultKey,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    register(
      FactoryInst<T>(constructor),
      key: key,
      onUnregister: _dynamicOnUnregister<T>(onUnregister),
    );
  }

  /// A shorthand for [getAsync], allowing retrieval of a dependency using
  /// call syntax.
  T call<T>({
    DIKey key = DIKey.defaultKey,
  }) {
    return getSync<T>(key: key);
  }

  /// Gets via [getSync] using [T] and [key].
  ///
  /// Returns the dependency as [T] or `null` upon any error, including but not
  /// limited to [TypeError] and [DependencyNotFoundException].
  T? getSyncOrNull<T>({
    DIKey key = DIKey.defaultKey,
  }) {
    try {
      return getSync<T>(key: key);
    } catch (_) {
      return null;
    }
  }

  /// Gets via [get] using [T] and [key], then and casts the result to [T].
  ///
  /// Throws [TypeError] if this result is a [Future].
  T getSync<T>({
    DIKey key = DIKey.defaultKey,
  }) {
    final value = get<T>(key: key);
    if (value is Future<T>) {
      throw TypeError();
    }
    return value;
  }

  /// Gets via [get] using [T] and [key], then and casts the result to [Future]
  /// of [T].
  ///
  /// Throws [TypeError] if this result is not a [Future].
  Future<T> getAsync<T>({
    DIKey key = DIKey.defaultKey,
  }) async {
    final value = await get<T>(key: key);
    if (value is! Future<T>) {
      throw TypeError();
    }
    return value;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

OnUnregisterCallback<dynamic>? _dynamicOnUnregister<T>(
  OnUnregisterCallback<T>? onUnregister,
) {
  return onUnregister != null
      ? (dynamic e) {
          if (e is T) {
            return onUnregister(e);
          }
        }
      : null;
}

FutureOr<void> _onUnregisterService<T extends DisposableService>(FutureOr<T> service) {
  FutureOr<void> internal(T service) {
    final initialized = service.initialized;
    if (initialized is Future<void>) {
      // ignore: invalid_use_of_protected_member
      return initialized.then((_) => service.dispose());
    } else {
      // ignore: invalid_use_of_protected_member
      return service.dispose();
    }
  }

  if (service is T) {
    return internal(service);
  } else {
    return service.then(internal);
  }
}
