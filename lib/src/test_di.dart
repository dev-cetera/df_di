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

  DIContainer();

  //
  //
  //

  /// forEachParent, forEachChild, forEachDependency, forEachGroup, forEachGroupDependency...

  final registry = DIRegistry();
  final _parents =
      <DIContainer>{}; // typically we only have 1 parent, addParent(DIContainer), removeParent(DIContainer)
  DIKey focusGroup = DIKey.defaultGroup;
  DIContainer? _completers;

  //
  //
  //

  // must return the registration index
  FutureOr<T> register<T extends Object>(
    FutureOr<T> value, {
    DIKey? groupKey,
    DependencyValidator<FutureOr<T>>? validator,
    OnUnregisterCallback<FutureOr<T>>? onUnregister,
    bool overrideExisting = false,
  }) {
    final key = groupKey ?? focusGroup;
    final metadata = DependencyMetadata(
      index: -1, // TODO: Count index
      groupKey: key,
      validator: validator != null ? (e) => validator(e as FutureOr<T>) : null,
      onUnregister: onUnregister != null ? (e) => onUnregister(e as FutureOr<T>) : null,
    );

    /// TODO: TEST and set traverse to false
    // If there's a completer waiting for this value that was registered via the untilOrNull() function,
    // complete it.
    _completers?.getOrNull<CompleterOr<FutureOr<T>>>()?.thenOr((e) => e.complete(value));

    final registeredDep = _registerDependency<FutureOr<T>>(
      dependency: Dependency<FutureOr<T>>(
        value: value,
        metadata: metadata,
      ),
      overrideExisting: overrideExisting,
    );

    return registeredDep.thenOr((e) => e.value);
  }

  //
  //
  //

  /// Register a [dependency] of type [T] in the [registry].
  ///
  /// If the [dependency] is an instance of [DIContainer], it will be
  /// registered as a child of this container. This action sets the child’s
  /// parent to this [DIContainer] and ensures that the child's registry is
  /// cleared upon unregistration.
  ///
  /// Throws a [DependencyAlreadyRegisteredException] if a dependency of the
  /// same type and group is already registered and [overrideExisting] is set
  /// to `false`. If [overrideExisting] is set to `true`, any existing
  /// dependency of the same type and group is replaced.
  ///
  /// Returns the registered [Dependency] object as a [FutureOr] that
  /// completes with the [dependency] object once it is registered.
  FutureOr<Dependency<T>> _registerDependency<T extends FutureOr<Object>>({
    required Dependency<T> dependency,
    bool overrideExisting = false,
  }) {
    // Throw an exception if the dependency is already registered and
    // [overrideExisting] is set to false.
    final groupKey = dependency.metadata.groupKey;
    if (!overrideExisting) {
      final existingDep = _getDependencyOrNull<T>(
        groupKey: groupKey,
        traverse: false,
      );
      if (existingDep != null) {
        throw DependencyAlreadyRegisteredException(
          type: T,
          groupKey: groupKey,
        );
      }
    }

    // If [dependency] is another [DIContainer], register it as a child via
    // [_setChildDependency].
    if (dependency is Dependency<FutureOr<DIContainer>>) {
      return _setChildDependency(dependency as Dependency<FutureOr<DIContainer>>).thenOr((_) {
        return dependency;
      });
    }

    // If [dependency] is not a [DIContainer], register it as a normal
    // dependency.
    registry.setDependency<T>(
      dependency: dependency,
    );
    return dependency;
  }

  /// Waits for the value of [childContainer] to resolve, updates its
  /// [DependencyMetadata.onUnregister] callback to clear the child's
  /// registry upon unregistration, and then uses [DIRegistry.setDependency]
  /// to complete the registration.
  ///
  /// Returns a [FutureOr] that completes when [childContainer] is fully
  /// registered in [registry].
  FutureOr<void> _setChildDependency(
    Dependency<FutureOr<DIContainer>> childContainer,
  ) {
    final value = childContainer.value;
    return value.thenOr(
      (child) {
        child._parents.add(this);
        registry.setDependency<FutureOr<DIContainer>>(
          dependency: childContainer.copyWith(
            metadata: childContainer.metadata.copyWith(
              onUnregister: (_) {
                return (childContainer.metadata.onUnregister?.call(child)).thenOr((_) {
                  print('[_setChildDependency] Clearing child registry');
                  child.registry.clear();
                });
              },
            ),
          ),
        );
      },
    );
  }

  //
  //
  //

  // what happens when you do an await or and there are pending completers? must complete the completer if it exists or something
  FutureOr<T> unregister<T extends Object>({
    DIKey? groupKey,
    bool skipOnUnregisterCallback = false,
  }) {
    final key = groupKey ?? focusGroup;
    final removed = registry.removeDependency<T>(groupKey: key) ??
        registry.removeDependency<Future<T>>(groupKey: key);
    if (removed == null) {
      throw 1;
    }
    final value = removed.value as FutureOr<T>;
    if (skipOnUnregisterCallback) {
      return value;
    }
    return (removed.metadata.onUnregister?.call(value)).thenOr((_) {
      return value;
    });
  }

  //
  //
  //

  FutureOr<T>? getOrNull<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
    bool registerFutureResults = true,
    bool unregisterFutures = false,
  }) {
    final key = groupKey ?? focusGroup;
    final existingDep = _getDependencyOrNull<FutureOr<T>>(
      groupKey: key,
      traverse: traverse,
    );
    final futureOrValue = existingDep?.value;
    switch (futureOrValue) {
      case Future<T> _:
        return futureOrValue.then((value) {
          if (registerFutureResults) {
            register<T>(
              value,
              groupKey: key,
              onUnregister: existingDep?.metadata.onUnregister,
              validator: existingDep?.metadata.validator,
            );
          }
          if (unregisterFutures) {
            return unregister<T>(
              groupKey: key,
              skipOnUnregisterCallback: true,
            );
          }
          return value;
        }) as FutureOr<T>;
      case T _:
        return futureOrValue;
      default:
        return null;
    }
  }

  //
  //
  //

  Dependency? _getDependencyOrNull<T extends Object>({
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
      final valid = dependency.metadata.validator?.call(dependency) ?? true;
      if (valid) {
        return dependency;
      } else {
        // TODO: Throw error!
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

  //
  //
  //

  FutureOr<T>? untilOrNull<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
    bool registerFutureResults = true,
    bool unregisterFutures = false,
  }) {
    final key = groupKey ?? focusGroup;

    // Check if the dependency is already registered.
    final test = getOrNull<T>(groupKey: key);
    if (test != null) {
      // Return the dependency if it is already registered.
      return test;
    }

    // If it's not already registered, register a Completer for the type
    // inside the untilsContainer.
    final completer = CompleterOr<FutureOr<T>>();
    _completers ??= DIContainer();
    _completers!.register<CompleterOr<FutureOr<T>>>(completer);
    // Wait for the register function to complete the Completer, then unregister
    // the completer before returning the value...
    return completer.futureOr.thenOr((value) {
      return _completers!.unregister<CompleterOr<FutureOr<T>>>().thenOr((_) {
        return value;
      });
    });
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
