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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract base class DIBase {
  //
  //
  //

  final DIBase? parent;

  Descriptor _focusGroup;

  void setFocusGroup(Descriptor group) {
    _focusGroup = group;
  }

  Descriptor getFocusGroup() => _focusGroup;

  @protected
  Descriptor preferFocusGroup(Descriptor? group) {
    return group ?? _focusGroup;
  }

  DIBase({Descriptor? focusGroup = Descriptor.defaultGroup, this.parent})
      : _focusGroup = focusGroup ?? Descriptor.defaultGroup;

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
    Descriptor? group,
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
  void registerFactoryService<T extends Service, P extends Object>(
    Constructor<T> constructor, {
    Descriptor? group,
  });

  @pragma('vm:prefer-inline')
  void registerChild({
    Descriptor? group,
    Descriptor? childGroup,
  }) {
    registerLazySingleton<DI, Object>(
      (_) => DI(focusGroup: childGroup, parent: this),
      group: group,
      onUnregister: (e) => e.unregisterAll(),
    );
  }

  @pragma('vm:prefer-inline')
  DI getChild({Descriptor? group}) => getSync<DI>(group: group);

  @pragma('vm:prefer-inline')
  void unregisterChild({Descriptor? group}) => unregister<DI>(group: group);

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
  void registerLazySingleton<T extends Object, P extends Object>(
    InstConstructor<T, P> constructor, {
    Descriptor? group,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    registerOr(
      SingletonInst<T, P>(constructor),
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
  void registerFactory<T extends Object, P extends Object>(
    InstConstructor<T, P> constructor, {
    Descriptor? group,
  }) {
    registerOr(
      FactoryInst<T, P>(constructor),
      group: group,
    );
  }

  /// Registers the [value] under type [T] and the specified [group], or
  /// under [Descriptor.defaultId] if no group is provided.
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
    Descriptor? group,
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
    Descriptor? group,
    OnUnregisterCallback<R>? onUnregister,
  });

  /// ...
  @protected
  void registerOfExactTypeOr<T extends Object, E extends Object>(
    FutureOr<T> value, {
    Descriptor? group,
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
    required Descriptor type,
    required Dependency<Object> dependency,
    bool suppressDependencyAlreadyRegisteredException = false,
  });

  /// Gets a dependency as either a [Future] or an instance of [T] registered
  /// under the type [T] and the specified [group], or under [Descriptor.defaultId]
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
    Descriptor? group,
  }) {
    final dep = getInternal<T>(group: group);
    return dep.thenOr((dep) {
      if (dep.condition?.call(this) ?? true) {
        return dep.value;
      } else {
        // TODO: Need a specific error.
        throw Error();
      }
    });
  }

  FutureOr<Dependency<T>> getInternal<T extends Object>({
    Descriptor? group,
  });

  // TODO:
  FutureOr<Object> getByRuntimeType(
    Type runtimeType, {
    Descriptor? group,
  }) {
    return getOfExactType(
      type: Descriptor.type(runtimeType),
    );
  }

  // ...
  @protected
  FutureOr<Object> getOfExactType({
    required Descriptor type,
    Descriptor? group,
  }) {
    final dep = getOfExactTypeInternal(type: type, group: group);
    return dep.thenOr((dep) {
      if (dep.condition?.call(this) ?? true) {
        return dep.value;
      } else {
        // TODO: Need a specific error.
        throw Error();
      }
    });
  }

  FutureOr<Dependency<Object>> getOfExactTypeInternal({
    required Descriptor type,
    Descriptor? group,
  });

  /// Gets a dependency registered via [registerFactory] as either a
  /// [Future] or an instance of [T] under the specified [group], or under
  /// [Descriptor.defaultId] if no group is provided.
  ///
  /// This method returns a new instance of the dependency each time it is
  /// called.
  ///
  /// - Throws [DependencyNotFoundException] if no factory is found for the
  ///   requested type [T] and [group].
  FutureOr<T> getFactory<T extends Object, P extends Object>(
    P params, {
    Descriptor? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final result = getFactoryOrNull<T, P>(params, group: focusGroup);
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
  FutureOr<T>? getFactoryOrNull<T extends Object, P extends Object>(
    P params, {
    Descriptor? group,
  });

  /// ...
  @protected
  FutureOr<Object> getFactoryOfExactType({
    required Descriptor type,
    required Object params,
    Descriptor? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final result = getFactoryOfExactTypeOrNull(
      type: type,
      params: params,
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
    required Descriptor type,
    required Object params,
    Descriptor? group,
  });

  /// Unregisters a dependency registered under type [T] and the
  /// specified [group], or under [Descriptor.defaultId] if no group is provided.
  ///
  /// - Throws [DependencyNotFoundException] if the dependency is not found.
  @pragma('vm:prefer-inline')
  FutureOr<void> unregister<T extends Object>({
    Descriptor? group,
  }) {
    return unregisterOfExactType(
      type: Descriptor.type(T),
      paramsType: Descriptor.type(Object),
      group: group,
    );
  }

  /// ...
  @protected
  @pragma('vm:prefer-inline')
  FutureOr<void> unregisterOfExactType({
    required Descriptor type,
    required Descriptor paramsType,
    Descriptor? group,
  }) {
    final dep = removeDependencyOfExactType(
      type: type,
      paramsType: paramsType,
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
    Descriptor? group,
  }) {
    return removeDependencyOfExactType(
      type: Descriptor.type(T),
      paramsType: Descriptor.type(Object),
      group: group,
    );
  }

  /// ...
  @protected
  Dependency<Object> removeDependencyOfExactType({
    required Descriptor type,
    required Descriptor paramsType,
    Descriptor? group,
  });

  /// A shorthand for [getSync], allowing retrieval of a dependency using
  /// call syntax.
  @pragma('vm:prefer-inline')
  T call<T extends Object>({
    Descriptor? group,
  }) {
    return getSync<T>(group: group);
  }

  /// Gets via [get] using [T] and [group] or `null` upon any error,
  /// including but not limited to [DependencyNotFoundException].
  FutureOr<T?> getOrNull<T extends Object>({
    Descriptor? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final registered = isRegisteredOfExactType(
      type: Descriptor.type(T),
      paramsType: Descriptor.type(Object),
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
    Descriptor? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final registered = isRegisteredOfExactType(
      type: Descriptor.type(T),
      paramsType: Descriptor.type(Object),
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
    Descriptor? group,
  }) {
    final value = get<T>(group: group);
    if (value is Future<T>) {
      throw TypeError();
    }
    return value;
  }

  /// Gets via [getAsync] using [T] and [group] or `null` upon any error.
  Future<T>? getAsyncOrNull<T extends Object>({
    Descriptor? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final registered = isRegisteredOfExactType(
      type: Descriptor.type(T),
      paramsType: Descriptor.type(Object),
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
    Descriptor? group,
  }) async {
    final value = await get<T>(group: group);
    return value;
  }

  /// Gets the registration [Descriptor] of the current dependency that can be
  /// fetched with type [T] and [group].
  ///
  /// Useful for debugging.
  @visibleForTesting
  @pragma('vm:prefer-inline')
  Type registrationType<T extends Object>({
    Descriptor? group,
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
    Descriptor? group,
  }) {
    return getDependency<T>(
      group: group,
    ).registrationIndex;
  }

  /// Checks if a dependency is registered under [T] and [group].
  bool isRegistered<T extends Object>({
    Descriptor? group,
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
    required Descriptor type,
    required Descriptor paramsType,
    required Descriptor group,
  }) {
    final dep = getDependencyOfExactTypeOrNull(
      type: type,
      paramsType: paramsType,
      group: group,
    );
    final registered = dep != null;
    return registered;
  }

  /// ...
  @protected
  Dependency<Object> getDependency<T extends Object>({
    Descriptor? group,
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
    required Descriptor type,
    required Descriptor paramsType,
    required Descriptor group,
  }) {
    final dep = getDependencyOfExactTypeOrNull(
      type: type,
      paramsType: paramsType,
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
    Descriptor? group,
  });

  /// ...
  @protected
  Dependency<Object>? getDependencyOfExactTypeOrNull({
    required Descriptor type,
    required Descriptor paramsType,
    Descriptor? group,
  });
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Exception thrown when attempting to register a dependency that is already registered.
final class DependencyAlreadyRegisteredException extends DFDIPackageException {
  DependencyAlreadyRegisteredException({
    required Object type,
    required Descriptor group,
  }) : super('Dependency of type $type in group $group is already registered.');
}

/// Exception thrown when a requested dependency is not found.
final class DependencyNotFoundException extends DFDIPackageException {
  DependencyNotFoundException({
    required Object type,
    required Descriptor group,
  }) : super('Dependency of type $type in group "$group" not found.');
}
