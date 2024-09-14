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

base mixin SupportsRuntimeTypeMixin on DIBase {
  //
  //
  //

  FutureOr<Object> registerT(
    FutureOr<Object> value, {
    DIKey? groupKey,
    DependencyValidator<FutureOr<Object>>? validator,
    OnUnregisterCallback<FutureOr<Object>>? onUnregister,
  }) {
    final groupKey1 = groupKey ?? focusGroup;
    final metadata = DependencyMetadata(
      index: dependencyCount++,
      groupKey: groupKey1,
      validator: validator,
      onUnregister: onUnregister,
    );
    completeRegistration(value);
    final registeredDep = _registerDependencyT(
      dependency: Dependency(
        value,
        metadata: metadata,
      ),
      checkExisting: true,
    );
    return registeredDep.value;
  }

  //
  //
  //

  Dependency<FutureOr<Object>> _registerDependencyT({
    required Dependency<FutureOr<Object>> dependency,
    bool checkExisting = false,
  }) {
    final groupKey1 = dependency.metadata?.groupKey ?? focusGroup;
    final runtimeType = dependency.value.runtimeType;
    if (checkExisting) {
      final existingDep = _getDependencyOrNullT(
        dependency.value.runtimeType,
        groupKey: groupKey1,
        traverse: false,
      );
      if (existingDep != null) {
        throw DependencyAlreadyRegisteredException(
          groupKey: groupKey1,
          type: runtimeType,
        );
      }
    }
    registry.setDependency(dependency);
    return dependency;
  }

  //
  //
  //

  FutureOr<Object> unregisterT(
    Type runtimeType, {
    DIKey? groupKey,
    bool skipOnUnregisterCallback = false,
  }) {
    final groupKey1 = groupKey ?? focusGroup;
    final removed = [
      registry.removeDependencyK(
        DIKey.type(runtimeType),
        groupKey: groupKey1,
      ),
      registry.removeDependencyK(
        DIKey.type(Future, [runtimeType]),
        groupKey: groupKey1,
      ),
      registry.removeDependencyK(
        DIKey.type(Constructor, [runtimeType]),
        groupKey: groupKey1,
      ),
    ].nonNulls.firstOrNull;
    if (removed == null) {
      throw DependencyNotFoundException(
        groupKey: groupKey1,
        type: runtimeType,
      );
    }
    final value = removed.value as FutureOr<Object>;
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

  FutureOr<Object>? getOrNullT(
    Type runtimeType, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final groupKey1 = groupKey ?? focusGroup;
    final existingDep = _getDependencyOrNullT(
      runtimeType,
      groupKey: groupKey1,
      traverse: traverse,
    );
    final value = existingDep?.value;
    switch (value) {
      case Future<Object> futureValue:
        return futureValue.then(
          (value) {
            _registerDependencyT(
              dependency: Dependency(
                value,
                metadata: existingDep!.metadata,
              ),
              checkExisting: false,
            );
            registry.removeDependencyT(
              runtimeType,
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

  Dependency<FutureOr<Object>>? _getDependencyOrNullT(
    Type runtimeType, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final groupKey1 = groupKey ?? focusGroup;
    final dependency = registry.getDependencyOrNullK(
          DIKey.type(runtimeType),
          groupKey: groupKey1,
        ) ??
        registry.getDependencyOrNullK(
          DIKey.type(Future, [runtimeType]),
          groupKey: groupKey1,
        );
    if (dependency != null) {
      final valid = dependency.metadata?.validator?.call(dependency) ?? true;
      if (valid) {
        return dependency.cast();
      } else {
        throw DependencyInvalidException(
          groupKey: groupKey1,
          type: runtimeType,
        );
      }
    }
    if (traverse) {
      for (final parent in parents) {
        final parentDep = (parent as SupportsRuntimeTypeMixin)._getDependencyOrNullT(
          runtimeType,
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

  FutureOr<Object> untilT(
    Type runtimeType, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final groupKey1 = groupKey ?? focusGroup;

    // Check if the dependency is already registered.
    final test = getOrNullT(runtimeType, groupKey: groupKey1);
    if (test != null) {
      // Return the dependency if it is already registered.
      return test;
    }

    CompleterOr<FutureOr<Object>>? completer;
    completer = (completers?.registry
        .getDependencyOrNullT(
          Object,
          groupKey: DIKey(runtimeType),
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
          groupKey: DIKey(runtimeType),
        ),
      ),
    );

    // Wait for the register function to complete the Completer, then unregister
    // the completer before returning the value.
    return completer.futureOr.thenOr((value) {
      completers!.registry.removeDependencyT(
        Object,
        groupKey: DIKey(runtimeType),
      );
      return value;
    });
  }
}
