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

import 'package:df_type/df_type.dart';

import '../_index.g.dart';
import '../_utils/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Shorthand for [DI.global].
DI get di => DI.global;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A simple Dependencu Injection (DI) class for managing dependencies across
/// an application.
class DI {
  /// Dependency registry.
  final registry = TypeSafeRegistry();

  /// Default global instance of the DI class.
  static final DI global = DI.newInstance();

  /// Creates a new instance of the DI class. Prefer using [global], unless
  /// there's a specific need for a separate instance.
  DI.newInstance();

  /// Registers the [dependency] under type [T] and the specified [key], or
  /// under [DIKey.defaultKey] if no key is provided.
  ///
  /// Optionally provide an [onUnregister] callback to be called on [unregister].
  ///
  /// Throws [DependencyAlreadyRegisteredException] if a dependency with the
  /// same type [T] and [key] already exists.
  ///
  /// Consider passing [FactoryInst] or [SingletonInst] as the [dependency]. These
  /// types trigger a special behavious witin this class:
  ///
  /// - [FactoryInst] Creates a new instance each time [get] is called.
  /// - [SingletonInst] Creates a single instance the first time [get] is called
  /// and returns the same instance for all subsequent calls.
  ///
  /// Consider the following example:
  ///
  /// ```dart
  /// // Example.
  ///  var i = 0;
  ///  di.register(i);
  ///  i++;
  ///  print(di.get<int>()); // prints 0
  ///  di.unregister<int>();
  ///  di.register(SingletonInst<int>(() => ++i));
  ///  print(di.get<int>()); // prints 2
  ///  print(di.get<int>()); // prints 2 again
  ///  di.unregister<int>();
  ///  di.register(Factory<int>(() => ++i));
  ///  print(di.get<int>()); // prints 3
  ///  print(di.get<int>()); // prints 4
  ///  print(di.get<int>()); // prints 5
  /// ```
  void register<T>(
    FutureOr<T> dependency, {
    DIKey key = DIKey.defaultKey,
    OnUnregisterCallback<dynamic>? onUnregister,
  }) {
    if (dependency is T) {
      _register<T>(
        dependency,
        key: key,
        onUnregister: onUnregister,
      );
    } else {
      _register<Future<T>>(
        dependency,
        key: key,
        onUnregister: onUnregister,
      );
    }
  }

  void _register<T>(
    T dependency, {
    DIKey key = DIKey.defaultKey,
    OnUnregisterCallback<dynamic>? onUnregister,
  }) {
    final existingDependencies = registry.getAllDependenciesOfType<T>();
    final depMap = {for (var dep in existingDependencies) dep.key: dep};

    // Check if the dependency is already registered.
    if (depMap.containsKey(key)) {
      throw DependencyAlreadyRegisteredException(T, key);
    }

    // Store the dependency in the type map.
    final newDependency = Dependency<T>(
      dependency,
      key: key,
      onUnregister: onUnregister,
    );
    registry.setDependency<T>(key, newDependency);
  }

  /// Gets a dependency as a [Future] or [T], registered under type [T] and the
  /// specified [key], or under [DIKey.defaultKey] if no key is provided.
  ///
  /// If the dependency was registered lazily via [registerLazy] and is not yet
  /// instantiated, it will be instantiated. Subsequent calls  of [get] will
  /// return the already instantiated instance.
  ///
  /// - Throws [DependencyNotFoundException] if the requested dependency cannot be found.
  FutureOr<T> get<T>({
    DIKey key = DIKey.defaultKey,
  }) {
    // Sync types.
    {
      final raw = registry.getDependency<T>(key);
      if (raw != null) {
        final dep = raw.dependency;
        return dep;
      }
    }
    // Async types.
    {
      final raw = registry.getDependency<Future<T>>(key);
      if (raw != null) {
        final dep = raw.dependency;
        final foc = FutureOrController<void>()
          ..addAll([
            () => unregister<Future<T>>(key),
            () => dep.then(
                  (syncDep) => register<T>(
                    syncDep,
                    key: key,
                    onUnregister: raw.onUnregister,
                  ),
                ),
          ]);
        final res = foc.completeWithResults((_) => dep);
        return res;
      }
    }
    // Singleton types.
    {
      final raw = registry.getDependency<SingletonInst<T>>(key);
      if (raw != null) {
        final dep = raw.dependency;
        final foc = FutureOrController<void>()
          ..addAll([
            () => unregister<SingletonInst<T>>(key),
            () => register<T>(
                  dep.constructor(),
                  key: key,
                  onUnregister: raw.onUnregister,
                ),
          ]);
        final res = foc.completeWithResults((_) => get<T>(key: key));
        return res;
      }
    }
    // Factory types.
    {
      final raw = registry.getDependency<FactoryInst<T>>(key);
      if (raw != null) {
        final dep = raw.dependency;
        final res = dep.constructor();
        return res;
      }
    }

    throw DependencyNotFoundException(T, key);
  }

  /// Unregisters a dependency registered under type [T] and the
  /// specified [key], or under [DIKey.defaultKey] if no key is provided.
  ///
  /// - Throws [DependencyNotFoundException] if the dependency is not found.
  FutureOr<void> unregister<T>([
    DIKey key = DIKey.defaultKey,
  ]) {
    for (final dep in [
      registry.removeDependency<T>(key),
      registry.removeDependency<Future<T>>(key),
      registry.removeDependency<SingletonInst<T>>(key),
      registry.removeDependency<FactoryInst<T> Function()>(key),
    ]) {
      if (dep == null) continue;
      final dependency = dep.dependency;
      return dep.onUnregister?.call(dependency);
    }
    throw DependencyNotFoundException(T, key);
  }

  /// Clears all registered dependencies, calling the [unregister] callback for
  /// each one before removal.
  void clear() {
    for (var depMap in registry.pRegistry.value.values) {
      for (var dependency in depMap.values) {
        dependency.onUnregister?.call(dependency.dependency);
      }
    }
    registry.clearRegistry();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Exception thrown when attempting to register a dependency that is already registered.
final class DependencyAlreadyRegisteredException extends DFDIPackageException {
  DependencyAlreadyRegisteredException(Type type, DIKey key)
      : super('Dependency of type $type with key $key is already registered.');
}

/// Exception thrown when a requested dependency is not found.
final class DependencyNotFoundException extends DFDIPackageException {
  DependencyNotFoundException(Type type, DIKey key)
      : super('Dependency of type $type with key "$key" not found.');
}
