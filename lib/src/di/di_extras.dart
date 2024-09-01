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

import 'package:df_type/df_type.dart' show ThenOrOnFutureOrX;

import '/src/_index.g.dart';
import '/src/utils/_dependency.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension DIExtras on DI {
  /// Registers a [Service] as a singleton. When [get] is first called
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
  void registerSingletonService<T extends Service>(
    Constructor<T> constructor, {
    DIKey key = DIKey.defaultKey,
  }) {
    registerSingleton(
      () => constructor().thenOr((e) => e.initService().thenOr((_) => e)),
      key: key,
      // ignore: invalid_use_of_protected_member
      onUnregister: (e) => e.thenOr((e) => e.initialized.thenOr((_) => e.dispose())),
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
    register2(
      SingletonInst<T>(constructor),
      key: key,
      onUnregister: onUnregister,
    );
  }

  /// Registers a [Service] as a factory. Each time [get] is called
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
  void registerFactoryService<T extends Service>(
    Constructor<T> constructor, {
    DIKey key = DIKey.defaultKey,
  }) {
    registerFactory(
      () => constructor().thenOr((e) => e.initService().thenOr((_) => e)),
      key: key,
      // ignore: invalid_use_of_protected_member
      onUnregister: (e) => e.thenOr((e) => e.initialized.thenOr((_) => e.dispose())),
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
    register2(
      FactoryInst<T>(constructor),
      key: key,
      onUnregister: onUnregister,
    );
  }

  /// A shorthand for [getAsync], allowing retrieval of a dependency using
  /// call syntax.
  T call<T>({
    DIKey key = DIKey.defaultKey,
  }) {
    return getSync<T>(key: key);
  }

  /// Checks if a dependency is registered under [T] and [key].
  bool isRegistered<T>({
    DIKey key = DIKey.defaultKey,
  }) {
    final registered = getAsyncOrNull<T>() != null;
    return registered;
  }

  /// Gets via [get] using [T] and [key] or `null` upon any error,
  /// including but not limited to [DependencyNotFoundException].
  FutureOr<T>? getOrNull<T>({
    DIKey key = DIKey.defaultKey,
  }) {
    try {
      return get<T>(key: key);
    } catch (_) {
      return null;
    }
  }

  /// Gets via [getSync] using [T] and [key] or `null` upon any error,
  /// including but not limited to [TypeError] and
  /// [DependencyNotFoundException].
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

  /// Gets via [getAsync] using [T] and [key] or `null` upon any error.
  Future<T>? getAsyncOrNull<T>({
    DIKey key = DIKey.defaultKey,
  }) {
    try {
      return getAsync<T>(key: key);
    } catch (_) {
      return null;
    }
  }

  /// Gets via [get] using [T] and [key], then and casts the result to [Future]
  /// of [T].
  Future<T> getAsync<T>({
    DIKey key = DIKey.defaultKey,
  }) async {
    final value = await get<T>(key: key);
    return value;
  }
}
