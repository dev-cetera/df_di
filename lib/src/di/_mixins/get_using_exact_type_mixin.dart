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
    DIKey? groupKey,
  }) {
    final fg = preferFocusGroup(groupKey);
    final value = getUsingExactTypeOrNull(
      type: type,
      groupKey: fg,
    );
    if (value == null) {
      throw DependencyNotFoundException(
        type: type,
        groupKey: fg,
      );
    }
    return value;
  }

  @protected
  @override
  FutureOr<Object>? getUsingExactTypeOrNull({
    required DIKey type,
    DIKey? groupKey,
    bool getFromParents = true,
  }) {
    final fg = preferFocusGroup(groupKey);
    final dep = _get(
      type: type,
      groupKey: fg,
      getFromParents: getFromParents,
    );
    return dep?.thenOr((e) => e.value);
  }

  @override
  FutureOr<Object> getUsingRuntimeType(
    Type type, {
    DIKey? groupKey,
  }) {
    return getUsingExactType(
      type: DIKey(type),
      groupKey: groupKey,
    );
  }

  @override
  FutureOr<Object>? getUsingRuntimeTypeOrNull(
    Type type, {
    DIKey? groupKey,
  }) {
    return getUsingExactTypeOrNull(
      type: DIKey(type),
      groupKey: groupKey,
    );
  }

  FutureOr<Dependency>? _get({
    required DIKey type,
    required DIKey groupKey,
    required bool getFromParents,
  }) {
    final dep = getDependencyUsingExactTypeOrNull1(
      type: type,
      groupKey: groupKey,
      getFromParents: getFromParents,
    );
    if (dep != null) {
      switch (dep.value) {
        case FutureOrInst _:
          final genericType = FutureOrInst.gr(type, Object);
          return _inst(
            type: type,
            genericType: genericType,
            groupKey: groupKey,
            getFromParents: getFromParents,
          );
        case Object _:
          return dep.cast();
      }
    }
    return null;
  }

  FutureOr<Dependency>? _inst({
    required DIKey type,
    required DIKey genericType,
    required DIKey groupKey,
    required bool getFromParents,
  }) {
    final dep = registry.getDependencyWithKeyOrNull(
      genericType,
      groupKey: groupKey,
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
        //     groupKey: groupKey,
        //   );
      }).thenOr((_) {
        return _get(
          type: type,
          groupKey: groupKey,
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
    DIKey? groupKey,
  });

  FutureOr<Object>? getUsingExactTypeOrNull({
    required DIKey type,
    DIKey? groupKey,
  });

  FutureOr<Object> getUsingRuntimeType(
    Type type, {
    DIKey? groupKey,
  });

  FutureOr<Object>? getUsingRuntimeTypeOrNull(
    Type type, {
    DIKey? groupKey,
  });
}
