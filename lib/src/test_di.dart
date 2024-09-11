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

  int _registrationCount = 0;
  int get registrationCount => _registrationCount;

  //
  //
  //

  FutureOr<T> register<T extends Object>(
    FutureOr<T> value, {
    DIKey? groupKey,
    DependencyValidator<FutureOr<T>>? validator,
    OnUnregisterCallback<FutureOr<T>>? onUnregister,
    bool checkExisting = true,
  }) {
    final key = groupKey ?? focusGroup;
    final metadata = DependencyMetadata(
      index: _registrationCount++,
      groupKey: key,
      validator: validator != null ? (e) => validator(e as FutureOr<T>) : null,
      onUnregister: onUnregister != null ? (e) => onUnregister(e as FutureOr<T>) : null,
    );

    _completers?.registry.getDependencyOrNull<CompleterOr<FutureOr<T>>>()?.value.complete(value);

    final registeredDep = _registerDependency(
      dependency: Dependency(
        value,
        metadata: metadata,
      ),
      checkExisting: checkExisting,
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
    //already registered.
    final groupKey = dependency.metadata?.groupKey ?? focusGroup;
    if (checkExisting) {
      final existingDep = _getDependencyOrNull<T>(
        groupKey: groupKey,
        traverse: false,
      );
      if (existingDep != null) {
        throw DependencyAlreadyRegisteredException(
          groupKey: groupKey,
          type: T,
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
    registry.setDependency<T>(dependency);
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
        final dependency = childContainer.copyWith(
          metadata: (childContainer.metadata ?? DependencyMetadata()).copyWith(
            onUnregister: (_) {
              return (childContainer.metadata?.onUnregister?.call(child)).thenOr((_) {
                print('[_setChildDependency] Clearing child registry');
                child.registry.clear();
              });
            },
          ),
        );
        registry.setDependency<FutureOr<DIContainer>>(dependency);
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
    bool unregisterCorrespondingFuture = true,
  }) {
    final key = groupKey ?? focusGroup;
    final removed = [
      registry.removeDependency<T>(groupKey: key),
      if (unregisterCorrespondingFuture) registry.removeDependency<Future<T>>(groupKey: key),
    ].firstWhereOrNull((e) => e != null) as Dependency<FutureOr<T>>?;
    if (removed == null) {
      throw 1;
    }

    final value = removed.value;

    if (skipOnUnregisterCallback) {
      return value;
    }
    return (removed.metadata?.onUnregister?.call(value)).thenOr((_) {
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
    bool unregisterRedundantFutures = false,
  }) {
    final key = groupKey ?? focusGroup;
    final existingDep = _getDependencyOrNull<T>(
      groupKey: key,
      traverse: traverse,
    );
    final value = existingDep?.value;
    switch (value) {
      case Future<T> futureValue:
        return futureValue.then(
          (value) {
            return (registerFutureResults
                    ? _registerDependency<T>(
                        dependency: Dependency<T>(
                          value,
                          metadata: existingDep!.metadata,
                        ),
                        checkExisting: false,
                      ).thenOr((_) => value)
                    : value)
                .thenOr(
              (value) {
                return (unregisterRedundantFutures
                    ? registry.removeDependency<Future<T>>(groupKey: key).thenOr((_) => value)
                    : value);
              },
            );
          },
        );
      case T _:
        return value;
      default:
        return null;
    }
  }

  //
  //
  //

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
