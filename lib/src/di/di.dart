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
import '../utils/_type_safe_registry/type_safe_registry.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A flexible and extensive Dependency Injection (DI) class for managing
/// dependencies across an application.
class DI {
  /// A type-safe registry that stores all dependencies.
  @protected
  final registry = TypeSafeRegistry();

  /// Default global instance of the DI class.
  static final DI global = DI();

  /// Creates a new instance of the DI class. Prefer using [global], unless
  /// there's a specific need for a separate instance.
  DI();

  /// Registers a singleton instance of [T] with the given [constructor]. When [get]
  /// is called with [T] and [key], the same instance will be returned.
  ///
  /// ```dart
  /// di.registerSingleton(FooBarService.new);
  /// final fooBarService1 = di.get<FooBarService>();
  /// final fooBarService2 = di.get<FooBarService>();
  /// print(fooBarService1 == fooBarService2); // true
  /// ```
  void registerSingleton<T extends Object>(
    InstConstructor<T> constructor, {
    DIKey key = DEFAULT_KEY,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    // ignore: invalid_use_of_protected_member
    registerWithEventualType(
      SingletonInst<T>(constructor),
      key: key,
      onUnregister: onUnregister,
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
  void registerFactory<T extends Object>(
    InstConstructor<T> constructor, {
    DIKey key = DEFAULT_KEY,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    // ignore: invalid_use_of_protected_member
    registerWithEventualType(
      FactoryInst<T>(constructor),
      key: key,
      onUnregister: onUnregister,
    );
  }

  /// Registers the [value] under type [T] and the specified [key], or
  /// under [DEFAULT_KEY] if no key is provided.
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
  void register<T extends Object>(
    FutureOr<T> value, {
    DIKey key = DEFAULT_KEY,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    return registerWithEventualType(
      value,
      key: key,
      onUnregister: onUnregister,
    );
  }

  @protected
  void registerWithEventualType<T extends Object, E extends Object>(
    FutureOr<T> value, {
    DIKey key = DEFAULT_KEY,
    OnUnregisterCallback<E>? onUnregister,
  }) {
    if (value is T) {
      registerExactType(
        type: T,
        dependency: Dependency(
          value: value,
          registrationIndex: _registrationCount++,
          onUnregister: (e) => onUnregister?.call(e as E),
        ),
      );
    } else {
      registerExactType(
        type: FutureInst<T>,
        dependency: Dependency(
          value: FutureInst<T>(() => value),
          registrationIndex: _registrationCount++,
          onUnregister: (e) => onUnregister?.call(e as E),
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
  void registerExactType({
    required Type type,
    required Dependency<Object> dependency,
    bool suppressDependencyAlreadyRegisteredException = false,
  }) {
    final existingDependencies = registry.getAllDependenciesOfType(type);
    final depMap = {for (var dep in existingDependencies) dep.key: dep};

    // Check if the dependency is already registered.
    final key = dependency.key;
    if (!suppressDependencyAlreadyRegisteredException && depMap.containsKey(key)) {
      throw DependencyAlreadyRegisteredException(type, key);
    }

    // Store the dependency in the type map.
    registry.setDependencyOfType(type, key, dependency);
  }

  /// Gets a dependency as either a [Future] or an instance of [T] registered
  /// under the type [T] and the specified [key], or under [DEFAULT_KEY]
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
  FutureOr<T> get<T extends Object>({
    DIKey key = DEFAULT_KEY,
  }) {
    // Sync types.
    {
      final dep = registry.getDependencyOfType(T, key)?.cast<FutureOr<T>>();
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
      final res = _inst<T, FutureInst<T>>(key);
      if (res != null) {
        return res;
      }
    }
    // Singleton types.
    {
      final res = _inst<T, SingletonInst<T>>(key);
      if (res != null) {
        return res;
      }
    }

    throw DependencyNotFoundException(T, key);
  }

  //
  //
  //

  FutureOr<T>? _inst<T extends Object, TInst extends Inst<T>>(DIKey key) {
    final dep = registry.getDependencyOfType(TInst, key)?.cast<TInst>();
    if (dep is Dependency<TInst>) {
      final value = dep.value;
      return value.thenOr((value) {
        return value.constructor();
      }).thenOr((newValue) {
        return registerExactType(
          type: T,
          dependency: dep.reassign(newValue),
          suppressDependencyAlreadyRegisteredException: true,
        );
      }).thenOr((_) {
        return registry.removeDependencyOfType(TInst, key);
      }).thenOr((_) {
        return get<T>(key: key);
      });
    }
    return null;
  }

  /// Gets a dependency registered via [registerFactory] as either a
  /// [Future] or an instance of [T] under the specified [key], or under
  /// [DEFAULT_KEY] if no key is provided.
  ///
  /// This method returns a new instance of the dependency each time it is
  /// called.
  ///
  /// - Throws [DependencyNotFoundException] if no factory is found for the
  ///   requested type [T] and [key].
  FutureOr<T> getFactory<T>({
    DIKey key = DEFAULT_KEY,
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
  /// specified [key], or under [DEFAULT_KEY] if no key is provided.
  ///
  /// - Throws [DependencyNotFoundException] if the dependency is not found.
  FutureOr<void> unregister<T>({
    DIKey key = DEFAULT_KEY,
  }) {
    final dep = _removeDependency<T>(key);
    dep.onUnregister?.call(dep);
  }

  Dependency<Object> _removeDependency<T>(DIKey key) {
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
    FutureInst<T>,
    SingletonInst<T>,
    FactoryInst<T>,
  ];
}
