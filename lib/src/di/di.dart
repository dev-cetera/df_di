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
import 'package:meta/meta.dart';

import '/src/_index.g.dart';
import '/src/utils/_dependency.dart';
import '/src/utils/_type_safe_registry.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Shorthand for [DI.global].
DI get di => DI.global;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A flexible and extensive Dependency Injection (DI) class for managing
/// dependencies across an application.
class DI {
  /// A type-safe registry that stores all dependencies.
  final registry = TypeSafeRegistry();

  /// Default global instance of the DI class.
  static final DI global = DI.newInstance();

  /// Creates a new instance of the DI class. Prefer using [global], unless
  /// there's a specific need for a separate instance.
  DI.newInstance();

  /// Registers the [value] under type [T] and the specified [key], or
  /// under [DIKey.defaultKey] if no key is provided.
  ///
  /// Optionally provide an [onUnregister] callback to be called on [unregister].
  ///
  /// Throws [DependencyAlreadyRegisteredException] if a dependency with the
  /// same type [T] and [key] already exists.
  ///
  /// Consider passing [FactoryInst] or [SingletonInst] as the [value]. These
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
    FutureOr<T> value, {
    DIKey key = DIKey.defaultKey,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    return registerWithEventualType<T, T>(
      value,
      key: key,
      onUnregister: onUnregister,
    );
  }

  @protected
  void registerWithEventualType<T, ET>(
    FutureOr<T> value, {
    DIKey key = DIKey.defaultKey,
    OnUnregisterCallback<ET>? onUnregister,
  }) {
    if (value is T) {
      registerExactType<T>(
        dependency: Dependency(
          value: value,
          registrationIndex: _registrationCount++,
          onUnregister: (e) => onUnregister?.call(e as ET),
        ),
      );
    } else {
      registerExactType<Future<T>>(
        dependency: Dependency(
          value: value,
          registrationIndex: _registrationCount++,
          onUnregister: (e) => onUnregister?.call(e as ET),
        ),
      );
    }
  }

  /// The number of dependencies registered in this instance.
  int get length => _registrationCount;

  /// Tracks the registration count, assigning a unique index number to each
  /// registration.
  var _registrationCount = 0;

  @protected
  void registerExactType<T>({
    required Dependency<T> dependency,
    bool suppressDependencyAlreadyRegisteredException = false,
  }) {
    final existingDependencies = registry.getAllDependencies<T>();
    final depMap = {for (var dep in existingDependencies) dep.key: dep};

    // Check if the dependency is already registered.
    final key = dependency.key;
    if (!suppressDependencyAlreadyRegisteredException && depMap.containsKey(key)) {
      throw DependencyAlreadyRegisteredException(T, key);
    }

    // Store the dependency in the type map.
    registry.setDependency<T>(key, dependency);
  }

  /// Gets a dependency as either a [Future] or an instance of [T] registered
  /// under the type [T] and the specified [key], or under [DIKey.defaultKey]
  /// if no key is provided.
  ///
  /// If the dependency was registered as a lazy singleton via [registerSingleton]
  /// and hasn't been instantiated yet, it will be instantiated on the first call.
  /// Subsequent calls to [get] will return the already instantiated instance.
  ///
  /// If the dependency was registered via [registerFactory], a new instance
  /// will be created and returned with each call to [get].
  ///
  /// - Throws [DependencyNotFoundException] if the requested dependency cannot
  /// be found.
  FutureOr<T> get<T>({
    DIKey key = DIKey.defaultKey,
  }) {
    // Sync types.
    {
      final dep = registry.getDependency<T>(key);
      if (dep != null) {
        final res = dep.value;
        return res;
      }
    }
    // Factory types.
    {
      final res = _getFactoryOrNull<T>(key);
      if (res != null) {
        return res;
      }
    }
    // Async types.
    {
      final dep = registry.getDependency<Future<T>>(key);
      if (dep != null) {
        final value = dep.value;
        return value.thenOr((newValue) {
          registerExactType<T>(
            dependency: dep.reassignValue(newValue),
            suppressDependencyAlreadyRegisteredException: true,
          );
          return newValue;
        }).thenOr((_) {
          registry.removeDependency<Future<T>>(key);
        }).thenOr((_) {
          return get<T>(key: key);
        });
      }
    }
    // Singleton types.
    {
      final dep = registry.getDependency<SingletonInst<T>>(key);
      if (dep != null) {
        final value = dep.value;
        return value.thenOr((value) {
          return value.constructor();
        }).thenOr((newValue) {
          return registerExactType<T>(
            dependency: dep.reassignValue(newValue),
            suppressDependencyAlreadyRegisteredException: true,
          );
        }).thenOr((_) {
          return registry.removeDependency<SingletonInst<T>>(key);
        }).thenOr((_) {
          return get<T>(key: key);
        });
      }
    }

    throw DependencyNotFoundException(T, key);
  }

  /// Gets a dependency registered via [registerFactory] as either a
  /// [Future] or an instance of [T] under the specified [key], or under
  /// [DIKey.defaultKey] if no key is provided.
  ///
  /// This method returns a new instance of the dependency each time it is
  /// called.
  ///
  /// - Throws [DependencyNotFoundException] if no factory is found for the
  ///   requested type [T] and [key].
  FutureOr<T> getFactory<T>({
    DIKey key = DIKey.defaultKey,
  }) {
    final result = _getFactoryOrNull<T>(key);
    if (result == null) {
      throw DependencyNotFoundException(T, key);
    }
    return result;
  }

  FutureOr<T>? _getFactoryOrNull<T>(DIKey key) {
    final dep = registry.getDependency<FactoryInst<T>>(key);
    final result = dep?.value.constructor();
    return result;
  }

  /// Unregisters a dependency registered under type [T] and the
  /// specified [key], or under [DIKey.defaultKey] if no key is provided.
  ///
  /// - Throws [DependencyNotFoundException] if the dependency is not found.
  FutureOr<void> unregister<T>({
    DIKey key = DIKey.defaultKey,
  }) {
    final dep = _removeDependency<T>(key);
    dep.onUnregister?.call(dep);
  }

  Dependency<dynamic> _removeDependency<T>(DIKey key) {
    final dependencies = registry.removeDependenciesOfTypes(
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

List<Type> supportedAssociatedTypes<T>() {
  return [
    T,
    Future<T>,
    SingletonInst<T>,
    FactoryInst<T>,
  ];
}
