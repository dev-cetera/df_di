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
  //
  //
  //

  Identifier _focusGroup;

  void setFocusGroup(Identifier group) {
    _focusGroup = group;
  }

  Identifier getFocusGroup() => _focusGroup;

  @protected
  Identifier preferFocusGroup(Identifier? group) {
    return group ?? _focusGroup;
  }

  DIBase({Identifier focusGroup = const Identifier('default')}) : _focusGroup = focusGroup;

  /// Registers a [Service] as a singleton. When [get] is first called
  /// with [T] and [group], [DI] creates, initializes, and returns a new instance
  /// of [T]. All subsequent calls to [get] return the same instance.
  ///
  /// ```dart
  /// // Example:
  /// di.initSingletonService(FooBarService.new);
  /// final fooBarService1 = di.get<FooBarService>();
  /// final fooBarService2 = di.get<FooBarService>();
  /// print(fooBarService1 == fooBarService2); // true
  /// ```
  void registerLazySingletonService<T extends Service>(
    Constructor<T> constructor, {
    Identifier? group,
  });

  /// Registers a [Service] as a factory. Each time [get] is called
  /// with T] and [group], [DI] creates, initializes, and returns a new instance
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
    Identifier? group,
  });

  /// Registers a singleton instance of [T] with the given [constructor]. When
  /// [get] is called with [T] and [group], the same instance will be returned.
  ///
  /// ```dart
  /// di.registerSingleton(FooBarService.new);
  /// final fooBarService1 = di.get<FooBarService>();
  /// final fooBarService2 = di.get<FooBarService>();
  /// print(fooBarService1 == fooBarService2); // true
  /// ```
  @pragma('vm:prefer-inline')
  void registerLazySingleton<T extends Object>(
    InstConstructor<T> constructor, {
    Identifier? group,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    registerOr(
      SingletonInst<T>(constructor),
      group: group,
      onUnregister: onUnregister,
    );
  }

  /// Registers a factory that creates a new instance of [T] each time [get] is
  /// called with [T] and [group].
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
    Identifier? group,
  }) {
    registerOr(
      FactoryInst<T>(constructor),
      group: group,
    );
  }

  /// Registers the [value] under type [T] and the specified [group], or
  /// under [Identifier.defaultId] if no group is provided.
  ///
  /// Optionally provide an [onUnregister] callback to be called on [unregister].
  ///
  /// Throws [DependencyAlreadyRegisteredException] if a dependency with the
  /// same type [T] and [group] already exists.
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
    Identifier? group,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    registerOr(
      value,
      group: group,
      onUnregister: onUnregister,
    );
  }

  /// ...
  @protected
  void registerOr<T extends Object, R extends Object>(
    FutureOr<T> value, {
    Identifier? group,
    OnUnregisterCallback<R>? onUnregister,
  });

  /// ...
  @protected
  void registerOfExactTypeOr<T extends Object, E extends Object>(
    FutureOr<T> value, {
    Identifier? group,
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
  void regOfExactType({
    required Identifier type,
    required Dependency<Object> dependency,
    bool suppressDependencyAlreadyRegisteredException = false,
  });

  /// Gets a dependency as either a [Future] or an instance of [T] registered
  /// under the type [T] and the specified [group], or under [Identifier.defaultId]
  /// if no group is provided.
  ///
  /// If the dependency was registered as a lazy singleton via [registerLazySingleton]
  /// and hasn't been instantiated yet, it will be instantiated on the first call.
  /// Subsequent calls to [get] will return the already instantiated instance.
  ///
  /// If the dependency was registered via [registerFactory], a new instance
  /// will be created and returned with each call to [get].
  ///
  /// - Throws [DependencyNotFoundException] if the requested dependency cannot
  /// be found.
  FutureOr<T> get<T extends Object>({
    Identifier? group,
  });

  // TODO:
  FutureOr<Object> getByRuntimeType(
    Type runtimeType, {
    Identifier? group,
  }) {
    return getOfExactType(
      type: Identifier.typeId(runtimeType),
    );
  }

  // ...
  @protected
  FutureOr<Object> getOfExactType({
    required Identifier type,
    Identifier? group,
  });

  /// Gets a dependency registered via [registerFactory] as either a
  /// [Future] or an instance of [T] under the specified [group], or under
  /// [Identifier.defaultId] if no group is provided.
  ///
  /// This method returns a new instance of the dependency each time it is
  /// called.
  ///
  /// - Throws [DependencyNotFoundException] if no factory is found for the
  ///   requested type [T] and [group].
  FutureOr<T> getFactory<T extends Object>({
    Identifier? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final result = getFactoryOrNull<T>(group: focusGroup);
    if (result == null) {
      throw DependencyNotFoundException(
        type: T,
        group: focusGroup,
      );
    }
    return result;
  }

  /// ...
  @protected
  FutureOr<T>? getFactoryOrNull<T extends Object>({
    Identifier? group,
  });

  /// ...
  @protected
  FutureOr<Object> getFactoryOfExactType(
    Identifier type,
    Identifier? group,
  ) {
    final focusGroup = preferFocusGroup(group);
    final result = getFactoryOfExactTypeOrNull(
      type: type,
      group: focusGroup,
    );
    if (result == null) {
      throw DependencyNotFoundException(
        type: Object,
        group: focusGroup,
      );
    }
    return result;
  }

  /// ...
  @protected
  FutureOr<Object>? getFactoryOfExactTypeOrNull({
    required Identifier type,
    Identifier? group,
  });

  /// Unregisters a dependency registered under type [T] and the
  /// specified [group], or under [Identifier.defaultId] if no group is provided.
  ///
  /// - Throws [DependencyNotFoundException] if the dependency is not found.
  @pragma('vm:prefer-inline')
  FutureOr<void> unregister<T extends Object>({
    Identifier? group,
  }) {
    return unregisterOfExactType(
      type: Identifier.typeId(T),
      group: group,
    );
  }

  /// ...
  @protected
  @pragma('vm:prefer-inline')
  FutureOr<void> unregisterOfExactType({
    required Identifier type,
    Identifier? group,
  }) {
    final dep = removeDependencyOfExactType(
      type: type,
      group: group,
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
    Identifier? group,
  }) {
    return removeDependencyOfExactType(
      type: Identifier.typeId(T),
      group: group,
    );
  }

  /// ...
  @protected
  Dependency<Object> removeDependencyOfExactType({
    required Identifier type,
    Identifier? group,
  });

  /// A shorthand for [getSync], allowing retrieval of a dependency using
  /// call syntax.
  @pragma('vm:prefer-inline')
  T call<T extends Object>({
    Identifier? group,
  }) {
    return getSync<T>(group: group);
  }

  /// Gets via [get] using [T] and [group] or `null` upon any error,
  /// including but not limited to [DependencyNotFoundException].
  FutureOr<T?> getOrNull<T extends Object>({
    Identifier? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final registered = isRegisteredOfExactType(
      type: Identifier.typeId(T),
      group: focusGroup,
    );
    if (registered) {
      return get<T>(group: focusGroup);
    }
    return null;
  }

  /// Gets via [getSync] using [T] and [group] or `null` upon any error,
  /// including but not limited to [TypeError] and
  /// [DependencyNotFoundException].
  T? getSyncOrNull<T extends Object>({
    Identifier? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final registered = isRegisteredOfExactType(
      type: Identifier.typeId(T),
      group: focusGroup,
    );
    if (registered) {
      try {
        return getSync<T>(group: focusGroup);
      } catch (_) {}
    }
    return null;
  }

  /// Gets via [get] using [T] and [group], then and casts the result to [T].
  ///
  /// Throws [TypeError] if this result is a [Future].
  T getSync<T extends Object>({
    Identifier? group,
  }) {
    final value = get<T>(group: group);
    if (value is Future<T>) {
      throw TypeError();
    }
    return value;
  }

  /// Gets via [getAsync] using [T] and [group] or `null` upon any error.
  Future<T>? getAsyncOrNull<T extends Object>({
    Identifier? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final registered = isRegisteredOfExactType(
      type: Identifier.typeId(T),
      group: focusGroup,
    );
    if (registered) {
      try {
        return getAsync<T>(group: focusGroup);
      } catch (_) {}
    }
    return null;
  }

  /// Gets via [get] using [T] and [group], then and casts the result to [Future]
  /// of [T].
  Future<T> getAsync<T extends Object>({
    Identifier? group,
  }) async {
    final value = await get<T>(group: group);
    return value;
  }

  /// Gets the registration [Identifier] of the current dependency that can be
  /// fetched with type [T] and [group].
  ///
  /// Useful for debugging.
  @visibleForTesting
  @pragma('vm:prefer-inline')
  Type registrationType<T extends Object>({
    Identifier? group,
  }) {
    return getDependency<T>(
      group: group,
    ).registrationType;
  }

  /// Gets the registration index of the current dependency that can be
  /// fetched with type [T] and [group].
  ///
  /// Useful for debugging.
  @pragma('vm:prefer-inline')
  @visibleForTesting
  int registrationIndex<T extends Object>({
    Identifier? group,
  }) {
    return getDependency<T>(
      group: group,
    ).registrationIndex;
  }

  /// Checks if a dependency is registered under [T] and [group].
  bool isRegistered<T extends Object>({
    Identifier? group,
  }) {
    final dep = getDependencyOrNull<T>(
      group: group,
    );
    final registered = dep != null;
    return registered;
  }

  /// Checks if a dependency is registered under [type] and [group].
  @protected
  bool isRegisteredOfExactType({
    required Identifier type,
    required Identifier group,
  }) {
    final dep = getDependencyOfExactTypeOrNull(
      type: type,
      group: group,
    );
    final registered = dep != null;
    return registered;
  }

  /// ...
  @protected
  Dependency<Object> getDependency<T extends Object>({
    Identifier? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final dep = getDependencyOrNull<T>(
      group: group,
    );
    if (dep == null) {
      throw DependencyNotFoundException(
        type: T,
        group: focusGroup,
      );
    } else {
      return dep;
    }
  }

  /// ...
  @protected
  Dependency<Object> getDependencyOfExactType({
    required Identifier type,
    required Identifier group,
  }) {
    final dep = getDependencyOfExactTypeOrNull(
      type: type,
      group: group,
    );
    if (dep == null) {
      throw DependencyNotFoundException(
        type: type,
        group: group,
      );
    } else {
      return dep;
    }
  }

  /// ...
  Dependency<Object>? getDependencyOrNull<T extends Object>({
    Identifier? group,
  });

  /// ...
  @protected
  Dependency<Object>? getDependencyOfExactTypeOrNull({
    required Identifier type,
    Identifier? group,
  });
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Exception thrown when attempting to register a dependency that is already registered.
final class DependencyAlreadyRegisteredException extends DFDIPackageException {
  DependencyAlreadyRegisteredException({
    required Object type,
    required Identifier group,
  }) : super('Dependency of type $type in group $group is already registered.');
}

/// Exception thrown when a requested dependency is not found.
final class DependencyNotFoundException extends DFDIPackageException {
  DependencyNotFoundException({
    required Object type,
    required Identifier group,
  }) : super('Dependency of type $type in group "$group" not found.');
}
