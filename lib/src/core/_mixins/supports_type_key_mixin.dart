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

base mixin SupportstypeEntityMixin on DIBase {
  //
  //
  //

  @protected
  Dependency<FutureOr<Object>> _registerDependencyK({
    required Dependency<FutureOr<Object>> dependency,
    bool checkExisting = false,
  }) {
    final groupEntity1 = dependency.metadata?.groupEntity ?? focusGroup;
    final typeEntity = dependency.typeEntity;
    if (checkExisting) {
      final existingDep = _getDependencyOrNullK(
        typeEntity,
        groupEntity: groupEntity1,
        traverse: false,
      );
      if (existingDep != null) {
        throw DependencyAlreadyRegisteredException(
          groupEntity: groupEntity1,
          type: typeEntity,
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
    Entity typeEntity, {
    Entity? groupEntity,
    bool skipOnUnregisterCallback = false,
  }) {
    final groupEntity1 = groupEntity ?? focusGroup;
    final removed = [
      registry.removeDependencyK(
        typeEntity,
        groupEntity: groupEntity1,
      ),
      registry.removeDependencyK(
        TypeEntity(Future, [typeEntity]),
        groupEntity: groupEntity1,
      ),
      registry.removeDependencyK(
        TypeEntity(Lazy, [typeEntity]),
        groupEntity: groupEntity1,
      ),
    ].nonNulls.firstOrNull;
    if (removed == null) {
      throw DependencyNotFoundException(
        groupEntity: groupEntity1,
        type: typeEntity,
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

  //
  //
  //

  bool isRegisteredK(
    Entity typeEntity, {
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final groupEntity1 = groupEntity ?? focusGroup;
    return [
      () =>
          registry.getDependencyOrNullK(
            typeEntity,
            groupEntity: groupEntity1,
          ) !=
          null,
      () =>
          registry.getDependencyOrNullK(
            TypeEntity(Future, [typeEntity]),
            groupEntity: groupEntity1,
          ) !=
          null,
      () =>
          registry.getDependencyOrNullK(
            TypeEntity(Lazy, [typeEntity]),
            groupEntity: groupEntity1,
          ) !=
          null,
      if (traverse)
        () => parents.any(
              (e) => (e as SupportstypeEntityMixin).isRegisteredK(
                typeEntity,
                groupEntity: groupEntity,
                traverse: true,
              ),
            ),
    ].any((e) => e());
  }

  //
  //
  //

  /// Retrieves a dependency of the exact type [typeEntity] registered under the
  /// specified [groupEntity].
  ///
  /// Note that this method will not return instances of subtypes. For example,
  /// if [typeEntity] is `Entity('List<dynamic>')` and `Entity('List<String>')` is
  /// actually registered, this method will not return that registered
  /// dependency. This limitation arises from the use of runtime types. If you
  /// need to retrieve subtypes, consider using the standard [get] method that
  /// employs generics and will return subtypes.
  ///
  /// If the dependency exists, it is returned; otherwise, a
  /// [DependencyNotFoundException] is thrown.
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
  @protected
  FutureOr<Object> getK(
    Entity typeEntity, {
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final groupEntity1 = groupEntity ?? focusGroup;
    final value = getOrNullK(
      typeEntity,
      groupEntity: groupEntity1,
      traverse: traverse,
    );
    if (value == null) {
      throw DependencyNotFoundException(
        type: typeEntity,
        groupEntity: groupEntity1,
      );
    }
    return value;
  }

  //
  //
  //

  /// Retrieves a dependency of the exact type [typeEntity] registered under the
  /// specified [groupEntity].
  ///
  /// Note that this method will not return instances of subtypes. For example,
  /// if [typeEntity] is `Entity('List<dynamic>')` and `Entity('List<String>')` is
  /// actually registered, this method will not return that registered
  /// dependency. This limitation arises from the use of runtime types. If you
  /// need to retrieve subtypes, consider using the standard [get] method that
  /// employs generics and will return subtypes.
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
  @protected
  FutureOr<Object>? getOrNullK(
    Entity typeEntity, {
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final groupEntity1 = groupEntity ?? focusGroup;
    final existingDep = _getDependencyOrNullK(
      typeEntity,
      groupEntity: groupEntity1,
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
              typeEntity,
              groupEntity: groupEntity1,
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
    Entity typeEntity, {
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final groupEntity1 = groupEntity ?? focusGroup;
    var dependency = registry.getDependencyOrNullK(
          typeEntity,
          groupEntity: groupEntity1,
        ) ??
        registry.getDependencyOrNullK(
          TypeEntity(Future, [typeEntity]),
          groupEntity: groupEntity1,
        );

    if (dependency == null && traverse) {
      for (final parent in parents) {
        dependency = (parent as SupportstypeEntityMixin)._getDependencyOrNullK(
          typeEntity,
          groupEntity: groupEntity1,
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
          groupEntity: groupEntity1,
          type: typeEntity,
        );
      }
    }

    return null;
  }

  //
  //
  //

  @protected
  FutureOr<Object> untilK(
    Entity typeEntity, {
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final groupEntity1 = groupEntity ?? focusGroup;

    // Check if the dependency is already registered.
    final test = getOrNullK(typeEntity, groupEntity: groupEntity1);
    if (test != null) {
      // Return the dependency if it is already registered.
      return test;
    }

    CompleterOr<FutureOr<Object>>? completer;
    completer = (completers?.registry
        .getDependencyOrNullK(
          TypeEntity(CompleterOr<FutureOr<Object>>, [typeEntity]),
          groupEntity: groupEntity1,
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
      Dependency<CompleterOr<FutureOr<Object>>>(
        completer,
        metadata: DependencyMetadata(
          groupEntity: groupEntity1,
          preemptivetypeEntity: TypeEntity(CompleterOr<Future<Object>>, [typeEntity]),
        ),
      ),
    );

    // Wait for the register function to complete the Completer, then unregister
    // the completer before returning the value.
    return completer.futureOr.thenOr((value) {
      completers!.registry.removeDependencyK(
        TypeEntity(CompleterOr<FutureOr<Object>>, [typeEntity]),
        groupEntity: groupEntity1,
      );
      return getK(
        typeEntity,
        groupEntity: groupEntity,
        traverse: traverse,
      );
    });
  }
}
