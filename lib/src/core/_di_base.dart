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

// ignore_for_file: invalid_use_of_protected_member

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base class DIBase {
  //
  //
  //

  /// Internal registry that stores dependencies.
  @protected
  final registry = DIRegistry();

  /// Parent containers.
  @protected
  final parents = <DIBase>{};

  /// A key that identifies the current group in focus for dependency management.
  DIKey? focusGroup = DIKey.defaultGroup;

  /// A container storing Future completions.
  @protected
  DIBase? completers;

  /// Returns the total number of registered dependencies.
  @protected
  int dependencyCount = 0;

  /// Register a dependency [value] of type [T] under the specified [groupKey]
  /// in the [registry].
  ///
  /// If the [value] is an instance of [DI], it will be registered as
  /// a child of this container. This action sets the child’s parent to this
  /// [DI] and ensures that the child's [registry] is cleared upon
  /// unregistration.
  ///
  /// You can provide a [validator] function to validate the dependency before
  /// it is returned by [getOrNull] or [untilOrNull]. If the validation fails,
  /// these methods will throw a [DependencyInvalidException].
  ///
  /// Additionally, an [onUnregister] callback can be specified to execute when
  /// the dependency is unregistered via [unregister].
  ///
  /// Throws a [DependencyAlreadyRegisteredException] if a dependency of the
  /// same type and group is already registered.
  FutureOr<T> register<T extends Object>(
    FutureOr<T> value, {
    DIKey? groupKey,
    DependencyValidator<FutureOr<T>>? validator,
    OnUnregisterCallback<FutureOr<T>>? onUnregister,
  }) {
    final groupKey1 = groupKey ?? focusGroup;
    final metadata = DependencyMetadata(
      index: dependencyCount++,
      groupKey: groupKey1,
      validator: validator != null ? (e) => validator(e as FutureOr<T>) : null,
      onUnregister: onUnregister != null ? (e) => onUnregister(e as FutureOr<T>) : null,
    );
    completeRegistration(value, groupKey1);
    final registeredDep = _registerDependency(
      dependency: Dependency(
        value,
        metadata: metadata,
      ),
      checkExisting: true,
    );
    return registeredDep.value;
  }

  @protected
  void completeRegistration<T extends Object>(
    T value,
    DIKey? groupKey,
  ) {
    final completer = (completers?.registry
            .getDependencyOrNull<CompleterOr<FutureOr<T>>>(groupKey: groupKey)
            ?.value ??
        completers?.registry
            .getDependencyOrNullK(
              DIKey.type(CompleterOr<Object>, [value.runtimeType]),
              groupKey: groupKey,
            )
            ?.value ??
        completers?.registry
            .getDependencyOrNullK(
              DIKey.type(CompleterOr<Future<Object>>, [value.runtimeType]),
              groupKey: groupKey,
            )
            ?.value) as CompleterOr?;
    completer?.complete(value);
  }

  /// Register a [dependency] of type [T] in the [registry].
  ///
  /// If the value of [dependency] is an instance of [DI], it will be
  /// registered as a child of this container. This action sets the child’s
  /// parent to this [DI] and ensures that the child's registry is
  /// cleared upon unregistration.
  ///
  /// Throws a [DependencyAlreadyRegisteredException] if a dependency of the
  /// same type and group is already registered and [checkExisting] is set
  /// to `true`. If [checkExisting] is set to `false`, any existing dependency
  /// of the same type and group is replaced.
  ///
  /// Returns the registered [Dependency] object as a [FutureOr] that
  /// completes with the [dependency] object once it is registered.
  Dependency<T> _registerDependency<T extends FutureOr<Object>>({
    required Dependency<T> dependency,
    bool checkExisting = false,
  }) {
    // If [checkExisting] is true, throw an exception if the dependency is
    // already registered.
    final groupKey1 = dependency.metadata?.groupKey ?? focusGroup;
    if (checkExisting) {
      final existingDep = _getDependencyOrNull<T>(
        groupKey: groupKey1,
        traverse: false,
      );
      if (existingDep != null) {
        throw DependencyAlreadyRegisteredException(
          groupKey: groupKey1,
          type: T,
        );
      }
    }

    // If [dependency] is not a [DIContainer], register it as a normal
    // dependency.
    registry.setDependency(dependency);
    return dependency;
  }

  /// Unregisters the dependency of type [T] associated with the specified
  /// [groupKey] from the [registry], if it exists.
  ///
  /// If [skipOnUnregisterCallback] is true, the
  /// [DependencyMetadata.onUnregister] callback will be skipped.
  ///
  /// Throws a [DependencyNotFoundException] if the dependency is not found.
  FutureOr<Object> unregister<T extends Object>({
    DIKey? groupKey,
    bool skipOnUnregisterCallback = false,
  }) {
    final groupKey1 = groupKey ?? focusGroup;
    final removed = [
      registry.removeDependency<T>(
        groupKey: groupKey1,
      ),
      registry.removeDependency<Future<T>>(
        groupKey: groupKey1,
      ),
      registry.removeDependency<Lazy<T>>(
        groupKey: groupKey1,
      ),
    ].nonNulls.firstOrNull;
    if (removed == null) {
      throw DependencyNotFoundException(
        groupKey: groupKey1,
        type: T,
      );
    }
    final value = removed.value;
    if (skipOnUnregisterCallback) {
      return value;
    }
    return consec(
      removed.metadata?.onUnregister?.call(value),
      (_) => value,
    );
  }

  /// Checks whether dependency of type [T] or subtype of [T] is registered.
  ///
  /// If [traverse] is true, it will also search recursively in parent
  /// containers.
  bool isRegistered<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final groupKey1 = groupKey ?? focusGroup;
    return [
      () =>
          registry.getDependencyOrNull<T>(
            groupKey: groupKey1,
          ) !=
          null,
      () =>
          registry.getDependencyOrNull<Future<T>>(
            groupKey: groupKey1,
          ) !=
          null,
      () =>
          registry.getDependencyOrNull<Lazy<T>>(
            groupKey: groupKey1,
          ) !=
          null,
      if (traverse)
        () => parents.any(
              (e) => e.isRegistered(
                groupKey: groupKey1,
                traverse: true,
              ),
            ),
    ].any((e) => e());
  }

  /// Retrieves a dependency of type [T] or subtypes of [T] registered under
  /// the specified [groupKey].
  ///
  /// If the dependency exists, it is returned; otherwise, a
  /// [DependencyNotFoundException] is thrown.
  ///
  /// Only use this method if you're certain that the registered dependency
  /// isn't a [Future]. If it is, a [DependencyIsFutureException] is trown.
  T call<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final value = get<T>(
      groupKey: groupKey,
      traverse: traverse,
    );
    if (value is! T) {
      throw DependencyIsFutureException(
        type: T,
        groupKey: groupKey,
      );
    }
    return value;
  }

  Future<T> getAsync<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) async {
    return get<T>(
      groupKey: groupKey,
      traverse: traverse,
    );
  }

  T getSync<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final value = get<T>(
      groupKey: groupKey,
      traverse: traverse,
    );
    if (value is Future) {
      throw DependencyIsFutureException(
        type: T,
        groupKey: groupKey,
      );
    } else {
      return value;
    }
  }

  T? getSyncOrNull<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getOrNull<T>(
      groupKey: groupKey,
      traverse: traverse,
    );
    if (throwIfAsync && value is Future) {
      throw DependencyIsFutureException(
        type: T,
        groupKey: groupKey,
      );
    }
    return value?.asSyncOrNull;
  }

  /// Retrieves a dependency of type [T] or subtypes of [T] registered under
  /// the specified [groupKey].
  ///
  /// If the dependency exists, it is returned; otherwise, a
  /// [DependencyNotFoundException] is thrown.
  ///
  /// The return type is a [FutureOr], which means it can either be a
  /// [Future] or a resolved value.
  ///
  /// If the dependency is registered as a non-future, the returned value will
  /// always be non-future. If it is registered as a future, the returned value
  /// will initially be a future. Once that future completes, its resolved value
  /// is re-registered as a non-future, allowing future calls to this method
  /// to return the resolved value directly.
  FutureOr<T> get<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final groupKey1 = groupKey ?? focusGroup;
    final value = getOrNull<T>(
      groupKey: groupKey1,
      traverse: traverse,
    );

    if (value == null) {
      throw DependencyNotFoundException(
        type: T,
        groupKey: groupKey1,
      );
    }
    return value;
  }

  /// Retrieves a dependency of type [T] or subtypes of [T] registered under
  /// the specified [groupKey].
  ///
  /// If the dependency exists, it is returned; otherwise, `null` is returned.
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  ///
  /// The return type is a [FutureOr], which means it can either be a
  /// [Future] or a resolved value.
  ///
  /// If the dependency is registered as a non-future, the returned value will
  /// always be non-future. If it is registered as a future, the returned value
  /// will initially be a future. Once that future completes, its resolved value
  /// is re-registered as a non-future, allowing future calls to this method
  /// to return the resolved value directly.
  FutureOr<T>? getOrNull<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final groupKey1 = groupKey ?? focusGroup;
    final existingDep = _getDependencyOrNull<T>(
      groupKey: groupKey1,
      traverse: traverse,
    );
    final value = existingDep?.value;
    switch (value) {
      case Future<T> futureValue:
        return futureValue.then(
          (value) {
            _registerDependency<T>(
              dependency: Dependency<T>(
                value,
                metadata: existingDep!.metadata,
              ),
              checkExisting: false,
            );
            registry.removeDependency<Future<T>>(
              groupKey: groupKey1,
            );
            return value;
          },
        );
      case T _:
        return value;
      default:
        return null;
    }
  }

  Dependency<FutureOr<T>>? _getDependencyOrNull<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final groupKey1 = groupKey ?? focusGroup;
    var dependency = registry.getDependencyOrNull<T>(
          groupKey: groupKey1,
        ) ??
        registry.getDependencyOrNull<Future<T>>(
          groupKey: groupKey1,
        );

    if (dependency == null && traverse) {
      for (final parent in parents) {
        dependency = parent._getDependencyOrNull<T>(
          groupKey: groupKey1,
        );
        if (dependency != null) {
          break;
        }
      }
    }

    if (dependency != null) {
      final valid = dependency.metadata?.validator?.call(dependency) ?? true;
      if (valid) {
        return dependency.cast();
      } else {
        throw DependencyInvalidException(
          groupKey: groupKey1,
          type: T,
        );
      }
    }

    return null;
  }

  /// Retrieves a dependency of type [T] or subtypes of [T] registered under
  /// the specified [groupKey.
  /// 
  /// If the dependency is found, it is returned; otherwise, this method waits
  /// until the dependency is registered before returning it.
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  FutureOr<T> until<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final groupKey1 = groupKey ?? focusGroup;

    // Check if the dependency is already registered.
    final test = getOrNull<T>(groupKey: groupKey1);
    if (test != null) {
      // Return the dependency if it is already registered.
      return test;
    }

    CompleterOr<FutureOr<T>>? completer;
    completer = completers?.registry
        .getDependencyOrNull<CompleterOr<FutureOr<T>>>(
          groupKey: groupKey1,
        )
        ?.value;
    if (completer != null) {
      return completer.futureOr.thenOr((value) => value);
    }

    completers ??= DIBase();

    // If it's not already registered, register a Completer for the type
    // inside the untilsContainer.
    completer = CompleterOr<FutureOr<T>>();

    completers!.registry.setDependency(
      Dependency<CompleterOr<FutureOr<T>>>(
        completer,
        metadata: DependencyMetadata(
          groupKey: groupKey1,
        ),
      ),
    );

    // Wait for the register function to complete the Completer, then unregister
    // the completer before returning the value.
    return completer.futureOr.thenOr((value) {
      completers!.registry.removeDependency<CompleterOr<FutureOr<T>>>(
        groupKey: groupKey1,
      );
      return value;
    });
  }

  /// Unregisters all dependencies in the reverse order they were registered.
  ///
  /// If [onBeforeUnregister] is provided, it will be called before each
  /// dependency is unregistered. If [onAfterUnregister] is provided, it will
  /// be called after each dependency is unregistered. These methods are
  /// particularly useful for debugging, logging and additional cleanup logic.
  FutureOr<List<Dependency>> unregisterAll({
    OnUnregisterCallback<Dependency>? onBeforeUnregister,
    OnUnregisterCallback<Dependency>? onAfterUnregister,
  }) {
    final results = List.of(registry.dependencies);
    final sequential = Sequential();
    for (final dependency in results) {
      sequential.addAll([
        (_) => onBeforeUnregister?.call(dependency),
        (_) => registry.removeDependencyK(
              dependency.typeKey,
              groupKey: dependency.metadata?.groupKey,
            ),
        (_) => dependency.metadata?.onUnregister?.call(dependency.value),
        (_) => onAfterUnregister?.call(dependency),
      ]);
    }
    return sequential.add((_) => results);
  }
}
