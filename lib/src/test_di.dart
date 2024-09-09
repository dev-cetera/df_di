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
  void register<T extends Object>(
    FutureOr<T> value, {
    DIKey? groupKey,
    OnUnregisterCallback<T>? onUnregister,
    DependencyValidator? validator,
  }) {
    final key = groupKey ?? focusGroup;
    final metadata = DependencyMetadata(
      index: -1, // TODO: Count index
      groupKey: key,
      validator: validator,
      onUnregister: onUnregister != null
          ? (value) {
              return onUnregister(value as FutureOr<T>);
            }
          : null,
    );
    _registerDependency<FutureOr<T>>(
      dependency: Dependency<FutureOr<T>>(
        value: value,
        metadata: metadata,
      ),
    );

    /// TODO: TEST and set traverse to false
    // If there's a completer waiting for this value that was registered via the untilOrNull() function,
    // complete it.
    _completers?.getOrNull<_Completer<T>>()?.thenOr((e) => e.complete(value));
  }

  // //
  // //
  // //

  void registerChild({
    DIKey? groupKey,
    OnUnregisterCallback<DIContainer>? onUnregister,
    DependencyValidator? validator,
  }) {
    register<DIContainer>(
      DIContainer(),
      groupKey: groupKey,
      validator: validator,
      onUnregister: onUnregister,
    );
  }

  //
  //
  //

  FutureOr<DIContainer?> unregisterChild({
    DIKey? groupKey,
  }) {
    return unregister<DIContainer>(
      groupKey: groupKey,
    );
  }

  //
  //
  //

  // what happens when you do an await or and there are pending completers? must complete the completer if it exists or something
  FutureOr<T> unregister<T extends Object>({
    DIKey? groupKey,
  }) {
    final key = groupKey ?? focusGroup;
    final removed = registry.removeDependency<T>(groupKey: key);
    if (removed == null) {
      throw 1;
    }
    final value = removed.value;
    return (removed.metadata.onUnregister?.call(value)).thenOr((_) {
      return value;
    });
  }

  void _registerDependency<T extends Object>({
    required Dependency<T> dependency,
    bool overrideExisting = false,
  }) {
    final groupKey = dependency.metadata.groupKey;
    if (overrideExisting) {
      final existingDep = _getDependencyOrNull<T>(
        groupKey: groupKey,
        traverse: false,
      );
      if (existingDep != null) {
        // TODO: Throw error!
      }
    }

    if (dependency is Dependency<FutureOr<DIContainer>>) {
      final childDependency = dependency.copyWith(
        metadata: dependency.metadata.copyWith(
          onUnregister: (child) {
            print(child.runtimeType);
            return child.thenOr((child) {
              child as DIContainer;
              return (dependency.metadata.onUnregister?.call(child)).thenOr((_) {
                print('CHILD UNREG!!!');
                child.registry.clear();
              });
            });
          },
        ),
      );
      print('REG CHILKD');
      registry.setDependency<T>(
        dependency: childDependency,
      );
    } else {
      registry.setDependency<T>(
        dependency: dependency,
      );
    }
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
    final test = _getDependencyOrNull<T>(
      groupKey: key,
      traverse: traverse,
    )?.value;
    switch (test) {
      case Future<T> _:
        return test.then((e) async {
          if (registerFutureResults) {
            register<T>(e, groupKey: key); // on unregister
          }
          if (unregisterFutures) {
            await unregister<T>(groupKey: key); // on unregister
          }
          return e;
        });
      case T _:
        return test;
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
    final dependency = registry.getDependencyOrNull<FutureOr<T>>(
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
        final parentDep = parent._getDependencyOrNull<FutureOr<T>>(
          groupKey: key,
        );
        if (parentDep != null) {
          return parentDep;
        }
      }
    } else {
      return null;
    }
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
    final completer = _Completer<T>();
    _completers ??= DIContainer();
    _completers!.register<_Completer<T>>(completer);
    // Wait for the register function to complete the Completer, then unregister
    // the completer before returning the value...
    return completer.futureOr.thenOr((value) {
      return _completers!.unregister<_Completer<T>>().thenOr((_) {
        return value;
      });
    });
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef _Completer<T> = CompleterOr<FutureOr<T>>;

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
