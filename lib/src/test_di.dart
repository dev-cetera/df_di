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

  final registry = DIRegistry();
  final _parents = <DIContainer>{}; // typically we only have 1 parent
  DIKey focusGroup = DIKey.defaultGroup;
  DIContainer? _completers;

  //
  //
  //

  // must return the registration index
  void register<F extends FutureOr<Object>>(
    F value, {
    DIKey? groupKey,
    DependencyValidator<F>? validator,
    OnUnregisterCallback<F>? onUnregister,
    bool overrideExisting = false,
  }) {
    final key = groupKey ?? focusGroup;
    final metadata = DependencyMetadata(
      index: -1, // TODO: Count index
      groupKey: key,
      validator: validator != null ? (e) => validator(e as F) : null,
      onUnregister: onUnregister != null ? (e) => onUnregister(e as F) : null,
    );
    _registerDependency<F>(
      dependency: Dependency<F>(
        value: value,
        metadata: metadata,
      ),
      overrideExisting: overrideExisting,
    );

    /// TODO: TEST and set traverse to false
    // If there's a completer waiting for this value that was registered via the untilOrNull() function,
    // complete it.
    _completers?.getOrNull<CompleterOr<F>>()?.thenOr((e) => e.complete(value));
  }

  //
  //
  //

  // what happens when you do an await or and there are pending completers? must complete the completer if it exists or something
  FutureOr<F> unregister<F extends FutureOr<Object>>({
    DIKey? groupKey,
    bool skipOnUnregisterCallback = false,
  }) {
    final key = groupKey ?? focusGroup;
    final removed = registry.removeDependency<F>(groupKey: key) ??
        registry.removeDependency<Future<F>>(groupKey: key);
    if (removed == null) {
      throw 1;
    }
    final value = removed.value as FutureOr<F>;
    if (skipOnUnregisterCallback) {
      return value;
    }
    return (removed.metadata.onUnregister?.call(value)).thenOr((_) {
      return value;
    });
  }

  void _registerDependency<F extends FutureOr<Object>>({
    required Dependency<F> dependency,
    bool overrideExisting = false,
  }) {
    final groupKey = dependency.metadata.groupKey;
    if (overrideExisting) {
      final existingDep = _getDependencyOrNull<F>(
        groupKey: groupKey,
        traverse: false,
      );
      if (existingDep != null) {
        throw 'ERROR: EXISTS!!!';
      }
    }

    if (dependency is Dependency<FutureOr<DIContainer>>) {
      final childDependency = dependency.copyWith(
        metadata: dependency.metadata.copyWith(
          onUnregister: (child) {
            return child.thenOr((child) {
              child as DIContainer;
              return (dependency.metadata.onUnregister?.call(child)).thenOr((_) {
                print('Properly unregistering child');
                child.registry.clear();
              });
            });
          },
        ),
      );
      registry.setDependency<F>(
        dependency: childDependency,
      );
    } else {
      registry.setDependency<F>(
        dependency: dependency,
      );
    }
  }

  //
  //
  //

  FutureOr<F>? getOrNull<F extends FutureOr<Object>>({
    DIKey? groupKey,
    bool traverse = true,
    bool registerFutureResults = true,
    bool unregisterFutures = false,
  }) {
    final key = groupKey ?? focusGroup;
    final existingDep = _getDependencyOrNull<F>(
      groupKey: key,
      traverse: traverse,
    );
    final futureOrValue = existingDep?.value;
    switch (futureOrValue) {
      case Future<F> _:
        return futureOrValue.then((value) {
          if (registerFutureResults) {
            register<F>(
              value,
              groupKey: key,
              onUnregister: existingDep?.metadata.onUnregister,
              validator: existingDep?.metadata.validator,
            );
          }
          if (unregisterFutures) {
            return unregister<F>(
              groupKey: key,
              skipOnUnregisterCallback: true,
            );
          }
          return value;
        });
      case F _:
        return futureOrValue;
      default:
        return null;
    }
  }

  //
  //
  //

  Dependency? _getDependencyOrNull<F extends FutureOr<Object>>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final key = groupKey ?? focusGroup;
    final dependency = registry.getDependencyOrNull<F>(
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
        final parentDep = parent._getDependencyOrNull<F>(
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

  FutureOr<F>? untilOrNull<F extends FutureOr<Object>>({
    DIKey? groupKey,
    bool traverse = true,
    bool registerFutureResults = true,
    bool unregisterFutures = false,
  }) {
    final key = groupKey ?? focusGroup;

    // Check if the dependency is already registered.
    final test = getOrNull<F>(groupKey: key);
    if (test != null) {
      // Return the dependency if it is already registered.
      return test;
    }

    // If it's not already registered, register a Completer for the type
    // inside the untilsContainer.
    final completer = CompleterOr<F>();
    _completers ??= DIContainer();
    _completers!.register<CompleterOr<F>>(completer);
    // Wait for the register function to complete the Completer, then unregister
    // the completer before returning the value...
    return completer.futureOr.thenOr((value) {
      return _completers!.unregister<CompleterOr<F>>().thenOr((_) {
        return value;
      });
    });
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A [DFDIPackageException] that may be thrown by
/// [DIContainer._getDependencyOrNull] if the associated [Dependency] fails
/// validation as deemed by [DependencyMetadata.validator].
final class DependencyDeemedInvalidException extends DFDIPackageException {
  DependencyDeemedInvalidException({
    required Object type,
    required DIKey groupKey,
  }) : super(
          'Dependency of type "$type" in group "$groupKey" has been deemed invalid by the specified validator, resulting in this error.',
        );
}
