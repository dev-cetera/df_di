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

import '/src/_internal.dart';

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
    completeRegistration(value);
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
  void completeRegistration(Object value) {
    (completers?.registry
            .getDependencyOrNullT(
              Object,
              groupKey: DIKey(value.runtimeType),
            )
            ?.value as CompleterOr<FutureOr<Object>>?)
        ?.complete(value);
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
  FutureOr<T> unregister<T extends Object>({
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
      registry.removeDependency<Constructor<T>>(
        groupKey: groupKey1,
      ),
    ].nonNulls.firstOrNull;
    if (removed == null) {
      throw DependencyNotFoundException(
        groupKey: groupKey1,
        type: T,
      );
    }
    final value = removed.value as FutureOr<T>;
    if (skipOnUnregisterCallback) {
      return value;
    }
    return mapFutureOr(
      removed.metadata?.onUnregister?.call(value),
      (_) => value,
    );
  }

  /// Returns any dependency of type [T] or subtype of [T] that is associated
  /// with the specified [groupKey].
  ///
  /// If [traverse] is true, it will also search recursively in parent
  /// containers.
  ///
  /// Throws a [DependencyNotFoundException] if the dependency is not found.
  /// Throws a [DependencyIsFutureException] if the dependency is a [Future].
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

  /// Returns any dependency of type [T] or subtype of [T] that is associated
  /// with the specified [groupKey].
  ///
  /// If [traverse] is true, it will also search recursively in parent
  /// containers.
  ///
  /// Throws a [DependencyNotFoundException] if the dependency is not found.
  FutureOr<T> get<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final value = getOrNull<T>(
      groupKey: groupKey,
      traverse: traverse,
    );

    if (value == null) {
      throw DependencyNotFoundException(
        type: T,
        groupKey: groupKey,
      );
    }
    return value;
  }

  /// Returns any dependency of type [T] or subtype of [T] that is associated
  /// with the specified [groupKey] if it exists, or `null`.
  ///
  /// If [traverse] is true, it will also search recursively in parent
  /// containers.
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
    final dependency = registry.getDependencyOrNull<T>(
          groupKey: groupKey1,
        ) ??
        registry.getDependencyOrNull<Future<T>>(
          groupKey: groupKey1,
        );
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
    if (traverse) {
      for (final parent in parents) {
        final parentDep = parent._getDependencyOrNull<T>(
          groupKey: groupKey1,
        );
        if (parentDep != null) {
          return parentDep;
        }
      }
    }
    return null;
  }

  /// Returns any dependency of type [T] or subtype of [T] that is associated
  /// with the specified [groupKey] if it exists, or waits until it is
  /// registered before returning it.
  ///
  /// If [traverse] is true, it will also search recursively in parent
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
    completer = (completers?.registry
        .getDependencyOrNullT(
          Object,
          groupKey: DIKey(T),
        )
        ?.value as CompleterOr<FutureOr<T>>?);
    if (completer != null) {
      return completer.futureOr.thenOr((value) => value);
    }

    completers ??= DIBase();

    // If it's not already registered, register a Completer for the type
    // inside the untilsContainer.
    completer = CompleterOr<FutureOr<T>>();

    completers!.registry.setDependency(
      Dependency<Object>(
        completer,
        metadata: DependencyMetadata(
          groupKey: DIKey(T),
        ),
      ),
    );

    // Wait for the register function to complete the Completer, then unregister
    // the completer before returning the value.
    return completer.futureOr.thenOr((value) {
      completers!.registry.removeDependencyT(
        Object,
        groupKey: DIKey(T),
      );
      return value;
    });
  }

  /// Unregisters all dependencies in the [registry] in the reverse
  /// order of their registration.
  ///
  /// If an [onUnregister] callback is provided, it will be called for each
  /// dependency after it is unregistered.
  FutureOr<List<Dependency>> unregisterAll({
    OnUnregisterCallback<Dependency>? onUnregister,
  }) {
    final executionQueue = ExecutionQueue();
    final results = <Dependency>[];
    for (final dependency in registry.dependencies) {
      results.add(dependency);
      executionQueue.add((_) {
        registry.removeDependencyK(
          dependency.typeKey,
          groupKey: dependency.metadata?.groupKey,
        );
        return mapFutureOr(
          dependency.metadata?.onUnregister?.call(dependency.value),
          (_) => onUnregister?.call(dependency),
        );
      });
    }
    return mapFutureOr(executionQueue.last(), (_) => results);
  }
}
