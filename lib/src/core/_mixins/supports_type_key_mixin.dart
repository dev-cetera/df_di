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

base mixin SupportsTypeKeyMixin on DIBase {
  //
  //
  //

  @protected
  Dependency<FutureOr<Object>> _registerDependencyK({
    required Dependency<FutureOr<Object>> dependency,
    bool checkExisting = false,
  }) {
    final groupKey1 = dependency.metadata?.groupKey ?? focusGroup;
    final typeKey = dependency.typeKey;
    if (checkExisting) {
      final existingDep = _getDependencyOrNullK(
        typeKey,
        groupKey: groupKey1,
        traverse: false,
      );
      if (existingDep != null) {
        throw DependencyAlreadyRegisteredException(
          groupKey: groupKey1,
          type: typeKey,
        );
      }
    }
    registry.setDependency(dependency);
    return dependency;
  }

  //
  //
  //

  @protected
  FutureOr<Object> unregisterK(
    DIKey typeKey, {
    DIKey? groupKey,
    bool skipOnUnregisterCallback = false,
  }) {
    final groupKey1 = groupKey ?? focusGroup;
    final removed = [
      registry.removeDependencyK(
        typeKey,
        groupKey: groupKey1,
      ),
      registry.removeDependencyK(
        DIKey.type(Future, [typeKey]),
        groupKey: groupKey1,
      ),
      registry.removeDependencyK(
        DIKey.type(Constructor, [typeKey]),
        groupKey: groupKey1,
      ),
    ].nonNulls.firstOrNull;
    if (removed == null) {
      throw DependencyNotFoundException(
        groupKey: groupKey1,
        type: typeKey,
      );
    }
    final value = removed.value;
    if (skipOnUnregisterCallback) {
      return value;
    }
    return mapFutureOr(
      removed.metadata?.onUnregister?.call(value),
      (_) => value,
    );
  }

  //
  //
  //

  bool isRegisteredK(
    DIKey typeKey, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final groupKey1 = groupKey ?? focusGroup;
    return [
      () =>
          registry.getDependencyOrNullK(
            typeKey,
            groupKey: groupKey1,
          ) !=
          null,
      () =>
          registry.getDependencyOrNullK(
            DIKey.type(Future, [typeKey]),
            groupKey: groupKey1,
          ) !=
          null,
      () =>
          registry.getDependencyOrNullK(
            DIKey.type(Constructor, [typeKey]),
            groupKey: groupKey1,
          ) !=
          null,
      if (traverse)
        () => parents.any(
              (e) => (e as SupportsTypeKeyMixin).isRegisteredK(
                typeKey,
                groupKey: groupKey,
                traverse: true,
              ),
            ),
    ].any((e) => e());
  }

  //
  //
  //

  @protected
  FutureOr<Object> getK(
    DIKey typeKey, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final value = getOrNullK(
      typeKey,
      groupKey: groupKey,
      traverse: traverse,
    );

    if (value == null) {
      throw DependencyNotFoundException(
        type: typeKey,
        groupKey: groupKey,
      );
    }
    return value;
  }

  //
  //
  //

  @protected
  FutureOr<Object>? getOrNullK(
    DIKey typeKey, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final groupKey1 = groupKey ?? focusGroup;
    final existingDep = _getDependencyOrNullK(
      typeKey,
      groupKey: groupKey1,
      traverse: traverse,
    );
    final value = existingDep?.value;
    switch (value) {
      case Future<Object> _:
        return value.then(
          (value) {
            _registerDependencyK(
              dependency: Dependency(
                value,
                metadata: existingDep!.metadata,
              ),
              checkExisting: false,
            );
            registry.removeDependencyK(
              typeKey,
              groupKey: groupKey1,
            );
            return value;
          },
        );
      case Object _:
        return value;
      default:
        return null;
    }
  }

  //
  //
  //

  Dependency<FutureOr<Object>>? _getDependencyOrNullK(
    DIKey typeKey, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final groupKey1 = groupKey ?? focusGroup;
    final dependency = registry.getDependencyOrNullK(
          typeKey,
          groupKey: groupKey1,
        ) ??
        registry.getDependencyOrNullK(
          DIKey.type(Future, [typeKey]),
          groupKey: groupKey1,
        );
    if (dependency != null) {
      final valid = dependency.metadata?.validator?.call(dependency) ?? true;
      if (valid) {
        return dependency.cast();
      } else {
        throw DependencyInvalidException(
          groupKey: groupKey1,
          type: typeKey,
        );
      }
    }
    if (traverse) {
      for (final parent in parents) {
        final parentDep = (parent as SupportsTypeKeyMixin)._getDependencyOrNullK(
          typeKey,
          groupKey: groupKey1,
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

  @protected
  FutureOr<Object> untilK(
    DIKey typeKey, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final groupKey1 = groupKey ?? focusGroup;

    // Check if the dependency is already registered.
    final test = getOrNullK(typeKey, groupKey: groupKey1);
    if (test != null) {
      // Return the dependency if it is already registered.
      return test;
    }

    CompleterOr<FutureOr<Object>>? completer;
    completer = (completers?.registry
        .getDependencyOrNullT(
          Object,
          groupKey: typeKey,
        )
        ?.value as CompleterOr<FutureOr<Object>>?);
    if (completer != null) {
      return completer.futureOr.thenOr((value) => value);
    }
    completers ??= DIBase();

    // If it's not already registered, register a Completer for the type
    // inside the untilsContainer.
    completer = CompleterOr<FutureOr<Object>>();

    completers!.registry.setDependency(
      Dependency<Object>(
        completer,
        metadata: DependencyMetadata(
          groupKey: typeKey,
        ),
      ),
    );

    // Wait for the register function to complete the Completer, then unregister
    // the completer before returning the value.
    return completer.futureOr.thenOr((value) {
      completers!.registry.removeDependencyT(
        Object,
        groupKey: typeKey,
      );
      return value;
    });
  }
}
