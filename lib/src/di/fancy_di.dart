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

import 'package:df_type/df_type.dart'
    show FutureOrController, ThenOrOnFutureOrX;
import 'package:meta/meta.dart';

import '/src/_index.g.dart';
import '/src/utils/_dependency.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension FancyDI on DI {
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
      onUnregister: (e) =>
          e.thenOr((e) => e.initialized.thenOr((_) => e.dispose())),
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
      onUnregister: (e) =>
          e.thenOr((e) => e.initialized.thenOr((_) => e.dispose())),
    );
  }

  /// A shorthand for [getAsync], allowing retrieval of a dependency using
  /// call syntax.
  T call<T>({
    DIKey key = DIKey.defaultKey,
  }) {
    return getSync<T>(key: key);
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

  /// Checks if a dependency is registered under [T] and [key].
  bool isRegistered<T>({
    DIKey key = DIKey.defaultKey,
  }) {
    final registered = getAsyncOrNull<T>() != null;
    return registered;
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

  /// Gets the registration [Type] of the current dependency that can be
  /// fetched with type [T] and [key].
  ///
  /// Useful for debugging.
  @visibleForTesting
  Type registrationType<T>({
    DIKey key = DIKey.defaultKey,
  }) {
    final dep = _getDependency<T>(key);
    return dep.registrationType;
  }

  /// Gets the registration index of the current dependency that can be
  /// fetched with type [T] and [key].
  ///
  /// Useful for debugging.
  @visibleForTesting
  int registrationIndex<T>({
    DIKey key = DIKey.defaultKey,
  }) {
    final dep = _getDependency<T>(key);
    return dep.registrationIndex;
  }

  Dependency<dynamic> _getDependency<T>(DIKey key) {
    // ignore: invalid_use_of_protected_member
    final dependencies = registry.getDependenciesOfTypes(
      supportedAssociatedTypes<T>(),
      key,
    );
    if (dependencies.isEmpty) {
      throw DependencyNotFoundException(T, key);
    } else {
      final dep = dependencies.first;
      return dep;
    }
  }

  /// Unregisters all dependencies in the reverse order of their registration,
  /// effectively resetting this instance of [DI].
  FutureOr<void> unregisterAll(
      [void Function(Dependency<dynamic> dep)? callback,]) {
    final foc = FutureOrController<void>();
    // ignore: invalid_use_of_protected_member
    final dependencies = registry.pRegistry.value.values
        .fold(<Dependency<dynamic>>[], (buffer, e) => buffer..addAll(e.values));
    dependencies
        .sort((a, b) => b.registrationIndex.compareTo(a.registrationIndex));
    for (final dep in dependencies) {
      final a = dep.onUnregister;
      final b = callback;
      foc.addAll([
        if (a != null) (_) => a(dep.value),
        if (b != null) (_) => b(dep),
      ]);
    }
    // ignore: invalid_use_of_protected_member
    foc.add((_) => registry.clearRegistry());
    return foc.complete();
  }
}
