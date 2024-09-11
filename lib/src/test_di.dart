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

class DIContainer {
  //
  //
  //

  DIContainer({
    this.unregisterRedundantFutures = true,
    this.registerFutureResults = true,
  });

  /// Whether to register the results of Futures once they have completed.
  final bool registerFutureResults;

  /// Whether Futures should be removed from [registry] when no longer needed.
  final bool unregisterRedundantFutures;

  /// Internal registry that stores dependencies.
  @protected
  final registry = DIRegistry();

  /// Parent containers.
  final _parents = <DIContainer>{};

  /// Child containers.
  List<DIContainer> get children =>
      List.unmodifiable(registry.dependencies.where((e) => e.value is DIContainer));

  /// A key that identifies the current group in focus for dependency management.
  DIKey focusGroup = DIKey.defaultGroup;

  /// The container for handling pending Future completions.
  late DIContainer? _completers = this;

  /// Returns the total number of registered dependencies.
  int get registrationCount => _registrationCount;
  int _registrationCount = 0;

  /// Register a dependency [value] of type [T] under the specified [groupKey]
  /// in the [registry].
  ///
  /// If the [value] is an instance of [DIContainer], it will be registered as
  /// a child of this container. This action sets the child’s parent to this
  /// [DIContainer] and ensures that the child's [registry] is cleared upon
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
      index: _registrationCount++,
      groupKey: groupKey1,
      validator: validator != null ? (e) => validator(e as FutureOr<T>) : null,
      onUnregister: onUnregister != null ? (e) => onUnregister(e as FutureOr<T>) : null,
    );
    _completers?.registry.getDependencyOrNull<CompleterOr<FutureOr<T>>>()?.value.complete(value);
    final registeredDep = _registerDependency(
      dependency: Dependency(
        value,
        metadata: metadata,
      ),
      checkExisting: true,
    );
    return registeredDep.thenOr((e) => e.value);
  }

  /// Register a [dependency] of type [T] in the [registry].
  ///
  /// If the value of [dependency] is an instance of [DIContainer], it will be
  /// registered as a child of this container. This action sets the child’s
  /// parent to this [DIContainer] and ensures that the child's registry is
  /// cleared upon unregistration.
  ///
  /// Throws a [DependencyAlreadyRegisteredException] if a dependency of the
  /// same type and group is already registered and [checkExisting] is set
  /// to `true`. If [checkExisting] is set to `false`, any existing dependency
  /// of the same type and group is replaced.
  ///
  /// Returns the registered [Dependency] object as a [FutureOr] that
  /// completes with the [dependency] object once it is registered.
  FutureOr<Dependency<T>> _registerDependency<T extends FutureOr<Object>>({
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

    // // If [dependency] is another [DIContainer], register it as a child via
    // // [_setChildDependency].
    // if (dependency is Dependency<FutureOr<DIContainer>>) {
    //   return _setChildDependency(dependency as Dependency<FutureOr<DIContainer>>).thenOr((_) {
    //     return dependency;
    //   });
    // }

    // If [dependency] is not a [DIContainer], register it as a normal
    // dependency.
    registry.setDependency<T>(dependency);
    return dependency;
  }

  /// Waits for the value of [childDependency] to resolve, updates its
  /// [DependencyMetadata.onUnregister] callback to clear the child's
  /// registry upon unregistration, and then uses [DIRegistry.setDependency]
  /// to complete the registration.
  ///
  /// Returns a [FutureOr] that completes when [childDependency] is fully
  /// registered in [registry].
  // FutureOr<void> _setChildDependency(
  //   Dependency<FutureOr<DIContainer>> childDependency,
  // ) {
  //   final value = childDependency.value;
  //   return value.thenOr(
  //     (child) {
  //       child._parents.add(this);
  //       final dependency = childDependency.copyWith(
  //         metadata: (childDependency.metadata ?? DependencyMetadata()).copyWith(
  //           onUnregister: (_) {
  //             return (childDependency.metadata?.onUnregister?.call(child)).thenOr((_) {
  //               print('[_setChildDependency] Clearing child registry');
  //               child.registry.clear();
  //             });
  //           },
  //         ),
  //       );
  //       registry.setDependency<FutureOr<DIContainer>>(dependency);
  //     },
  //   );
  // }

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
      registry.removeDependency<T>(groupKey: groupKey1),
      registry.removeDependency<Future<T>>(groupKey: groupKey1),
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
    return (removed.metadata?.onUnregister?.call(value)).thenOr((_) => value);
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
            return FutureOrController<dynamic>([
              if (registerFutureResults) ...[
                (_) {
                  return _registerDependency<T>(
                    dependency: Dependency<T>(
                      value,
                      metadata: existingDep!.metadata,
                    ),
                    checkExisting: false,
                  );
                },
                if (unregisterRedundantFutures)
                  (_) {
                    return registry.removeDependency<Future<T>>(groupKey: groupKey1);
                  },
              ],
            ]).completeWith((_) => value);
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
    final key = groupKey ?? focusGroup;
    final dependency = registry.getDependencyOrNull<T>(
          groupKey: key,
        ) ??
        registry.getDependencyOrNull<Future<T>>(
          groupKey: key,
        );
    if (dependency != null) {
      final valid = dependency.metadata?.validator?.call(dependency) ?? true;
      if (valid) {
        return dependency.cast();
      } else {
        throw DependencyInvalidException(
          groupKey: key,
          type: T,
        );
      }
    }
    if (traverse) {
      for (final parent in _parents) {
        final parentDep = parent._getDependencyOrNull<T>(
          groupKey: key,
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
  FutureOr<T> untilOrNull<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final key = groupKey ?? focusGroup;

    // Check if the dependency is already registered.
    final test = getOrNull<T>(groupKey: key);
    if (test != null) {
      // Return the dependency if it is already registered.
      return test;
    }

    CompleterOr<FutureOr<T>>? completer;
    completer = _completers?.registry.getDependencyOrNull<CompleterOr<FutureOr<T>>>()?.value;
    if (completer != null) {
      return completer.futureOr.thenOr((value) => value);
    }
    _completers ??= DIContainer();

    // If it's not already registered, register a Completer for the type
    // inside the untilsContainer.
    completer = CompleterOr<FutureOr<T>>();

    _completers!.registry.setDependency(Dependency(completer));

    // Wait for the register function to complete the Completer, then unregister
    // the completer before returning the value...
    return completer.futureOr.thenOr((value) {
      _completers!.registry.removeDependency<CompleterOr<FutureOr<T>>>();
      return value;
    });
  }

  FutureOr<Constructor<T>> registerConstructor<T>(
    FutureOr<T> Function() constructor, {
    DIKey<Object>? groupKey,
    bool Function(FutureOr<T>)? validator,
    FutureOr<void> Function(FutureOr<T>)? onUnregister,
  }) {
    return register<Constructor<T>>(
      Constructor<T>(constructor),
      groupKey: groupKey,
      validator: validator != null ? (e) => validator(e.thenOr((e) => e.singleton)) : null,
      onUnregister: onUnregister != null ? (e) => onUnregister(e.thenOr((e) => e.singleton)) : null,
    );
  }

  FutureOr<T?> unregisterConstructor<T>({
    DIKey<Object>? groupKey,
    bool skipOnUnregisterCallback = false,
  }) {
    return unregister<Constructor<T>>(
      groupKey: groupKey,
      skipOnUnregisterCallback: skipOnUnregisterCallback,
    ).thenOr((e) => e).thenOr((e) => e._instance);
  }

  //
  //
  //

  FutureOr<T>? getSingletonOrNull<T>({
    DIKey<Object>? groupKey,
    bool traverse = true,
  }) {
    return getOrNull<Constructor<T>>(groupKey: groupKey)?.asValue.singleton;
  }

  DIContainer child({
    DIKey<Object>? groupKey,
    bool Function(FutureOr<DIContainer>)? validator,
    FutureOr<void> Function(FutureOr<DIContainer>)? onUnregister,
  }) {
    final constructor = registerConstructor<DIContainer>(
      () => DIContainer().._parents.add(this),
      groupKey: groupKey,
      validator: validator,
      onUnregister: (e) => (onUnregister?.call(e)).thenOr(
        (_) => e.thenOr((e) => e.unregisterAll()),
      ),
    );
    final child = (constructor as Constructor<DIContainer>).singleton.asValue;
    return child;
  }

  FutureOr<List<Dependency>> unregisterAll() {
    final executionQueue = ExecutionQueue();
    final results = <Dependency>[];
    for (final dependency in registry.dependencies) {
      results.add(dependency);
      executionQueue.add((_) {
        registry.removeDependencyWithKey(
          dependency.typeKey,
          groupKey: dependency.metadata?.groupKey,
        );
        if (dependency.value is! Future) {
          return dependency.metadata?.onUnregister?.call(dependency.value);
        }
      });
    }
    return executionQueue.last().thenOr((_) => results);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class Constructor<T> {
  FutureOr<T>? _instance;
  final FutureOr<T> Function() _constructor;

  Constructor(this._constructor);

  /// Returns the singleton instance, creating it if necessary.
  FutureOr<T> get singleton {
    _instance ??= _constructor();
    return _instance!;
  }

  /// Returns a new instance each time, acting as a factory.
  FutureOr<T> get factory {
    return _constructor();
  }

  /// Resets the singleton instance, allowing it to be re-created on the next call.
  void resetSingleton() {
    _instance = null;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class DependencyAlreadyRegisteredException extends DFDIPackageException {
  DependencyAlreadyRegisteredException({
    required Object type,
    required DIKey groupKey,
  }) : super(
          condition: 'Dependency of type "$type" in group "$groupKey" has already been registered.',
          reason:
              'Thrown to prevent accidental overriding of dependencies of the same type and group.',
          options: [
            'Prevent calling [register] on a dependency of the same type and group.',
            'Use a different group in [register] to register the dependency under a new "group".',
            'Unregister the existing dependency using [unregister] before registering it again.',
            'Set "overrideExisting" to "true" when calling [register] to replace the existing dependency.',
          ],
        );
}

final class DependencyNotFoundException extends DFDIPackageException {
  DependencyNotFoundException({
    required Object type,
    required DIKey groupKey,
  }) : super(
          condition: 'No dependency of type "$type" found in group "$groupKey".',
          reason:
              'Thrown when attempting to unregister or access a dependency that does not exist.',
          options: [
            'Verify the type and groupKey.',
            'Ensure that the dependency has been registered before accessing or unregistering it.',
            "If accessing from a parent container, check the parent container's dependencies.",
          ],
        );
}

final class DependencyInvalidException extends DFDIPackageException {
  DependencyInvalidException({
    required Object type,
    required DIKey groupKey,
  }) : super(
          condition: 'Dependency of type "$type" in group "$groupKey" is invalid.',
          reason:
              'Thrown to prevent access to a dependency that is deemed invalid by its specified validator function.',
          options: [
            'Modify the "validator" function when registering this dependency via [register].',
          ],
        );
}
