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
base mixin GetDependencyMixin on DIBase implements GetDependencyInterface {
  @protected
  @override
  Dependency getDependency1<T extends Object, P extends Object>({
    DIKey? groupKey,
    required bool getFromParents,
  }) {
    final fg = preferFocusGroup(groupKey);
    final dep = getDependencyOrNull1<T, P>(
      groupKey: groupKey,
      getFromParents: getFromParents,
    );
    if (dep == null) {
      throw DependencyNotFoundException(
        type: T,
        groupKey: fg,
      );
    } else {
      return dep;
    }
  }

  @protected
  @override
  Dependency? getDependencyOrNull1<T extends Object, P extends Object>({
    DIKey? groupKey,
    required bool getFromParents,
  }) {
    final fg = preferFocusGroup(groupKey);
    final getters = [
      () => registry.getDependencyOrNull<T>(groupKey: fg),
      () => registry.getDependencyOrNull<FutureOrInst<T, Object>>(groupKey: fg),
    ];
    for (final getter in getters) {
      final dep = getter();
      if (dep != null) {
        final conditionMet = dep.metadata.condition?.call(this) ?? true;
        if (conditionMet) {
          return dep;
        }
      }
    }
    if (getFromParents) {
      return parent?.getDependencyOrNull1<T, P>(
        groupKey: groupKey,
        getFromParents: getFromParents,
      );
    }
    return null;
  }

  @protected
  @override
  Dependency getDependencyUsingExactType1({
    required DIKey type,
    DIKey? paramsType,
    DIKey? groupKey,
    required bool getFromParents,
  }) {
    final fg = preferFocusGroup(groupKey);
    final dep = getDependencyUsingExactTypeOrNull1(
      type: type,
      paramsType: paramsType,
      groupKey: groupKey,
      getFromParents: getFromParents,
    );
    if (dep == null) {
      throw DependencyNotFoundException(
        type: type,
        groupKey: fg,
      );
    } else {
      return dep;
    }
  }

  @protected
  @override
  Dependency? getDependencyUsingExactTypeOrNull1({
    required DIKey type,
    DIKey? paramsType,
    DIKey? groupKey,
    required bool getFromParents,
  }) {
    final fg = preferFocusGroup(groupKey);
    final paramsType1 = paramsType ?? DIKey(Object);
    final getters = [
      type,
      FutureOrInst.gr(type, paramsType1),
    ].map(
      (type) {
        return () => registry.getDependencyOfTypeOrNull(
              type: type,
              groupKey: fg,
            );
      },
    );
    for (final getter in getters) {
      final dep = getter();
      if (dep != null) {
        final conditionMet = dep.metadata.condition?.call(this) ?? true;
        if (conditionMet) {
          return dep;
        }
      }
    }
    return parent?.getDependencyUsingExactTypeOrNull1(
      type: type,
      paramsType: paramsType,
      groupKey: groupKey,
      getFromParents: getFromParents,
    );
  }

  @protected
  @override
  @pragma('vm:prefer-inline')
  Dependency getDependencyUsingRuntimeType1({
    required Type type,
    DIKey? paramsType,
    DIKey? groupKey,
    required bool getFromParents,
  }) {
    return getDependencyUsingExactType1(
      type: DIKey(type),
      paramsType: paramsType,
      groupKey: groupKey,
      getFromParents: getFromParents,
    );
  }

  @protected
  @override
  @pragma('vm:prefer-inline')
  Dependency? getDependencyUsingRuntimeTypeOrNull1({
    required Type type,
    DIKey? paramsType,
    DIKey? groupKey,
    required bool getFromParents,
  }) {
    return getDependencyUsingExactTypeOrNull1(
      type: DIKey(type),
      paramsType: paramsType,
      groupKey: groupKey,
      getFromParents: getFromParents,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
abstract interface class GetDependencyInterface {
  Dependency getDependency1<T extends Object, P extends Object>({
    DIKey? groupKey,
    required bool getFromParents,
  });

  Dependency getDependencyUsingExactType1({
    required DIKey type,
    DIKey? paramsType,
    DIKey? groupKey,
    required bool getFromParents,
  });

  Dependency? getDependencyOrNull1<T extends Object, P extends Object>({
    DIKey? groupKey,
    required bool getFromParents,
  });

  Dependency? getDependencyUsingExactTypeOrNull1({
    required DIKey type,
    DIKey? paramsType,
    DIKey? groupKey,
    required bool getFromParents,
  });

  Dependency getDependencyUsingRuntimeType1({
    required Type type,
    DIKey? paramsType,
    DIKey? groupKey,
    required bool getFromParents,
  });

  Dependency? getDependencyUsingRuntimeTypeOrNull1({
    required Type type,
    DIKey? paramsType,
    DIKey? groupKey,
    required bool getFromParents,
  });
}
