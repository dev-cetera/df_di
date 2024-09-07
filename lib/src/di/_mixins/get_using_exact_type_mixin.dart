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

@internal
base mixin GetUsingExactTypeMixin on DIBase implements GetUsingExactTypeInterface {
  @protected
  @override
  FutureOr<Object> getUsingExactType({
    required DIKey type,
    DIKey? typeGroup,
  }) {
    final fg = preferFocusGroup(typeGroup);
    final value = getUsingExactTypeOrNull(
      type: type,
      typeGroup: fg,
    );
    if (value == null) {
      throw DependencyNotFoundException(
        type: type,
        typeGroup: fg,
      );
    }
    return value;
  }

  @protected
  @override
  FutureOr<Object>? getUsingExactTypeOrNull({
    required DIKey type,
    DIKey? typeGroup,
    bool getFromParents = true,
  }) {
    final fg = preferFocusGroup(typeGroup);
    final dep = _get(
      type: type,
      typeGroup: fg,
      getFromParents: getFromParents,
    );
    return dep?.thenOr((e) => e.value);
  }

  @override
  FutureOr<Object> getUsingRuntimeType(
    Type type, {
    DIKey? typeGroup,
  }) {
    return getUsingExactType(
      type: DIKey(type),
      typeGroup: typeGroup,
    );
  }

  @override
  FutureOr<Object>? getUsingRuntimeTypeOrNull(
    Type type, {
    DIKey? typeGroup,
  }) {
    return getUsingExactTypeOrNull(
      type: DIKey(type),
      typeGroup: typeGroup,
    );
  }

  FutureOr<Dependency<Object>>? _get({
    required DIKey type,
    required DIKey typeGroup,
    required bool getFromParents,
  }) {
    final dep = getDependencyUsingExactTypeOrNull1(
      type: type,
      typeGroup: typeGroup,
      getFromParents: getFromParents,
    );
    if (dep != null) {
      switch (dep.value) {
        case FutureOrInst _:
          final genericType = FutureOrInst.gr(type, Object);
          return _inst(
            type: type,
            genericType: genericType,
            typeGroup: typeGroup,
            getFromParents: getFromParents,
          );
        case Object _:
          return dep.cast();
      }
    }
    return null;
  }

  FutureOr<Dependency<Object>>? _inst({
    required DIKey type,
    required DIKey genericType,
    required DIKey typeGroup,
    required bool getFromParents,
  }) {
    final dep = registry.getDependencyOfTypeOrNull(
      type: genericType,
      typeGroup: typeGroup,
    );
    if (dep != null) {
      final value = dep.value;
      return value.thenOr((value) {
        return (value as Inst).constructor(-1);
      }).thenOr((newValue) {
        return registerDependencyUsingExactType(
          type: type,
          dependency: dep.passNewValue(newValue),
          suppressDependencyAlreadyRegisteredException: true,
        );
        // }).thenOr((_) {
        //   return registry.removeDependencyUsingExactType(
        //     type: genericType,
        //     typeGroup: typeGroup,
        //   );
      }).thenOr((_) {
        return _get(
          type: type,
          typeGroup: typeGroup,
          getFromParents: getFromParents,
        )!;
      });
    }
    return null;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
abstract interface class GetUsingExactTypeInterface {
  FutureOr<Object> getUsingExactType({
    required DIKey type,
    DIKey? typeGroup,
  });

  FutureOr<Object>? getUsingExactTypeOrNull({
    required DIKey type,
    DIKey? typeGroup,
  });

  FutureOr<Object> getUsingRuntimeType(
    Type type, {
    DIKey? typeGroup,
  });

  FutureOr<Object>? getUsingRuntimeTypeOrNull(
    Type type, {
    DIKey? typeGroup,
  });
}
