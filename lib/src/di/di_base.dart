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

import 'package:meta/meta.dart';

import '/src/_index.g.dart';
import '/src/utils/_dependency.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract base class DIBase {
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
    Identifier key = Identifier.defaultId,
  });

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
    Identifier key = Identifier.defaultId,
  });

  /// Registers a singleton instance of [T] with the given [constructor]. When [get]
  /// is called with [T] and [key], the same instance will be returned.
  ///
  /// ```dart
  /// di.registerSingleton(FooBarService.new);
  /// final fooBarService1 = di.get<FooBarService>();
  /// final fooBarService2 = di.get<FooBarService>();
  /// print(fooBarService1 == fooBarService2); // true
  /// ```
  @pragma('vm:prefer-inline')
  void registerSingleton<T extends Object>(
    InstConstructor<T> constructor, {
    Identifier key = Identifier.defaultId,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    registerOr(
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
  @pragma('vm:prefer-inline')
  void registerFactory<T extends Object>(
    InstConstructor<T> constructor, {
    Identifier key = Identifier.defaultId,
    //OnUnregisterCallback<T>? onUnregister,
  }) {
    registerOr(
      FactoryInst<T>(constructor),
      key: key,
    );
  }

  /// Registers the [value] under type [T] and the specified [key], or
  /// under [Identifier.defaultId] if no key is provided.
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
    Identifier key = Identifier.defaultId,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    registerOr(
      value,
      key: key,
      onUnregister: onUnregister,
    );
  }

  /// ...
  @protected
  void registerOr<T extends Object, R extends Object>(
    FutureOr<T> value, {
    Identifier key = Identifier.defaultId,
    OnUnregisterCallback<R>? onUnregister,
  });

  /// ...
  @protected
  void registerByExactTypeOr<T extends Object, E extends Object>(
    FutureOr<T> value, {
    Identifier key = Identifier.defaultId,
    OnUnregisterCallback<E>? onUnregister,
  });

  /// ...
  @protected
  void reg<T extends Object>({
    required Dependency<T> dependency,
    bool suppressDependencyAlreadyRegisteredException = false,
  });

  /// ...
  @protected
  void regByExactType({
    required Identifier type,
    required Dependency<Object> dependency,
    bool suppressDependencyAlreadyRegisteredException = false,
  });

  /// Gets a dependency as either a [Future] or an instance of [T] registered
  /// under the type [T] and the specified [key], or under [Identifier.defaultId]
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
    Identifier key = Identifier.defaultId,
  });

  // ...
  FutureOr<Object> getByExactType({
    required Identifier type,
    Identifier key = Identifier.defaultId,
  });

  /// Gets a dependency registered via [registerFactory] as either a
  /// [Future] or an instance of [T] under the specified [key], or under
  /// [Identifier.defaultId] if no key is provided.
  ///
  /// This method returns a new instance of the dependency each time it is
  /// called.
  ///
  /// - Throws [DependencyNotFoundException] if no factory is found for the
  ///   requested type [T] and [key].
  FutureOr<T> getFactory<T extends Object>({
    Identifier key = Identifier.defaultId,
  }) {
    final result = getFactoryOrNull<T>(key: key);
    if (result == null) {
      throw DependencyNotFoundException(
        type: T,
        key: key,
      );
    }
    return result;
  }

  /// ...
  @protected
  FutureOr<T>? getFactoryOrNull<T extends Object>({
    Identifier key = Identifier.defaultId,
  });

  /// ...
  @protected
  FutureOr<Object> getFactoryByExactType(
    Identifier type,
    Identifier key,
  ) {
    final result = getFactoryByExactTypeOrNull(
      type: type,
      key: key,
    );
    if (result == null) {
      throw DependencyNotFoundException(
        type: Object,
        key: key,
      );
    }
    return result;
  }

  /// ...
  @protected
  FutureOr<Object>? getFactoryByExactTypeOrNull({
    required Identifier type,
    Identifier key = Identifier.defaultId,
  });

  /// Unregisters a dependency registered under type [T] and the
  /// specified [key], or under [Identifier.defaultId] if no key is provided.
  ///
  /// - Throws [DependencyNotFoundException] if the dependency is not found.
  @pragma('vm:prefer-inline')
  FutureOr<void> unregister<T extends Object>({
    Identifier key = Identifier.defaultId,
  }) {
    return unregisterByExactType(
      type: Identifier.typeId(T),
      key: key,
    );
  }

  /// ...
  @protected
  @pragma('vm:prefer-inline')
  FutureOr<void> unregisterByExactType({
    required Identifier type,
    Identifier key = Identifier.defaultId,
  }) {
    final dep = removeDependencyByExactType(
      type: type,
      key: key,
    );
    return dep.onUnregister?.call(dep.value);
  }

  /// Unregisters all dependencies in the reverse order of their registration,
  /// effectively resetting this instance of [DI].
  FutureOr<void> unregisterAll({
    void Function(Dependency<Object> dep)? onUnregister,
  });

  /// ...
  @protected
  Dependency<Object> removeDependency<T extends Object>({
    Identifier key = Identifier.defaultId,
  }) {
    return removeDependencyByExactType(
      type: Identifier.typeId(T),
      key: key,
    );
  }

  /// ...
  @protected
  Dependency<Object> removeDependencyByExactType({
    required Identifier type,
    Identifier<Object> key = Identifier.defaultId,
  });

  /// A shorthand for [getSync], allowing retrieval of a dependency using
  /// call syntax.
  @pragma('vm:prefer-inline')
  T call<T extends Object>({
    Identifier key = Identifier.defaultId,
  }) {
    return getSync<T>(key: key);
  }

  /// Gets via [get] using [T] and [key] or `null` upon any error,
  /// including but not limited to [DependencyNotFoundException].
  FutureOr<T?> getOrNull<T extends Object>({
    Identifier key = Identifier.defaultId,
  }) {
    if (isRegisteredByExactType(type: Identifier.typeId(T), key: key)) {
      return get<T>(key: key);
    }
    return null;
  }

  /// Gets via [getSync] using [T] and [key] or `null` upon any error,
  /// including but not limited to [TypeError] and
  /// [DependencyNotFoundException].
  T? getSyncOrNull<T extends Object>({
    Identifier<Object> key = Identifier.defaultId,
  }) {
    if (isRegisteredByExactType(type: Identifier.typeId(T), key: key)) {
      try {
        return getSync<T>(key: key);
      } catch (_) {}
    }
    return null;
  }

  /// Gets via [get] using [T] and [key], then and casts the result to [T].
  ///
  /// Throws [TypeError] if this result is a [Future].
  T getSync<T extends Object>({
    Identifier key = Identifier.defaultId,
  }) {
    final value = get<T>(key: key);
    if (value is Future<T>) {
      throw TypeError();
    }
    return value;
  }

  /// Gets via [getAsync] using [T] and [key] or `null` upon any error.
  Future<T>? getAsyncOrNull<T extends Object>({
    Identifier<Object> key = Identifier.defaultId,
  }) {
    if (isRegisteredByExactType(type: Identifier.typeId(T), key: key)) {
      try {
        return getAsync<T>(key: key);
      } catch (_) {}
    }
    return null;
  }

  /// Gets via [get] using [T] and [key], then and casts the result to [Future]
  /// of [T].
  Future<T> getAsync<T extends Object>({
    Identifier key = Identifier.defaultId,
  }) async {
    final value = await get<T>(key: key);
    return value;
  }

  /// Gets the registration [Identifier] of the current dependency that can be
  /// fetched with type [T] and [key].
  ///
  /// Useful for debugging.
  @visibleForTesting
  @pragma('vm:prefer-inline')
  Type registrationType<T extends Object>({
    Identifier key = Identifier.defaultId,
  }) {
    return getDependency<T>(
      key: key,
    ).registrationType;
  }

  /// Gets the registration index of the current dependency that can be
  /// fetched with type [T] and [key].
  ///
  /// Useful for debugging.
  @pragma('vm:prefer-inline')
  @visibleForTesting
  int registrationIndex<T extends Object>({
    Identifier key = Identifier.defaultId,
  }) {
    return getDependency<T>(
      key: key,
    ).registrationIndex;
  }

  /// Checks if a dependency is registered under [T] and [key].
  bool isRegistered<T extends Object>({
    Identifier<Object> key = Identifier.defaultId,
  }) {
    final dep = getDependencyOrNull<T>(
      key: key,
    );
    final registered = dep != null;
    return registered;
  }

  /// Checks if a dependency is registered under [type] and [key].
  @protected
  bool isRegisteredByExactType({
    required Identifier type,
    Identifier<Object> key = Identifier.defaultId,
  }) {
    final dep = getDependencyByExactTypeOrNull(
      type: type,
      key: key,
    );
    final registered = dep != null;
    return registered;
  }

  /// ...
  @protected
  Dependency<Object> getDependency<T extends Object>({
    Identifier key = Identifier.defaultId,
  }) {
    final dep = getDependencyOrNull<T>(
      key: key,
    );
    if (dep == null) {
      throw DependencyNotFoundException(
        type: T,
        key: key,
      );
    } else {
      return dep;
    }
  }

  /// ...
  @protected
  Dependency<Object> getDependencyByExactType({
    required Identifier type,
    Identifier<Object> key = Identifier.defaultId,
  }) {
    final dep = getDependencyByExactTypeOrNull(
      type: type,
      key: key,
    );
    if (dep == null) {
      throw DependencyNotFoundException(
        type: type,
        key: key,
      );
    } else {
      return dep;
    }
  }

  /// ...
  Dependency<Object>? getDependencyOrNull<T extends Object>({
    Identifier<Object> key = Identifier.defaultId,
  });

  /// ...
  @protected
  Dependency<Object>? getDependencyByExactTypeOrNull({
    required Identifier type,
    Identifier<Object> key = Identifier.defaultId,
  });
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Exception thrown when attempting to register a dependency that is already registered.
final class DependencyAlreadyRegisteredException extends DFDIPackageException {
  DependencyAlreadyRegisteredException({
    required Object type,
    required Identifier key,
  }) : super('Dependency of type $type with key $key is already registered.');
}

/// Exception thrown when a requested dependency is not found.
final class DependencyNotFoundException extends DFDIPackageException {
  DependencyNotFoundException({
    required Object type,
    required Identifier key,
  }) : super('Dependency of type $type with key "$key" not found.');
}
