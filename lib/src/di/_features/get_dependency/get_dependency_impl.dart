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
base mixin GetDependencyImpl on DIBase implements GetDependencyIface {
  @protected
  @override
  Dependency<Object> getDependency1<T extends Object, P extends Object>({
    Gr? group,
    required bool getFromParents,
  }) {
    final fg = preferFocusGroup(group);
    final dep = getDependencyOrNull1<T, P>(
      group: group,
       getFromParents: getFromParents,
    );
    if (dep == null) {
      throw DependencyNotFoundException(
        type: T,
        group: fg,
      );
    } else {
      return dep;
    }
  }

  @protected
  @override
  Dependency<Object>? getDependencyOrNull1<T extends Object, P extends Object>({
    Gr? group,
    required bool getFromParents,
  }) {
    final fg = preferFocusGroup(group);
    final getters = [
      () => registry.getDependencyOrNull<T>(group: fg),
      () => registry.getDependencyOrNull<FutureOrInst<T, Object>>(group: fg),
    ];
    for (final getter in getters) {
      final dep = getter();
      if (dep != null) {
        final conditionMet = dep.condition?.call(this) ?? true;
        if (conditionMet) {
          return dep;
        }
      }
    }
    if (getFromParents) {
      return parent?.getDependencyOrNull1<T, P>(
        group: group,
         getFromParents: getFromParents,
      );
    }
    return null;
  }

  @protected
  @override
  Dependency<Object> getDependencyUsingExactType1({
    required Gr type,
    Gr? paramsType,
    Gr? group,
    required bool getFromParents,
  }) {
    final fg = preferFocusGroup(group);
    final dep = getDependencyUsingExactTypeOrNull1(
      type: type,
      paramsType: paramsType,
      group: group,
       getFromParents: getFromParents,
    );
    if (dep == null) {
      throw DependencyNotFoundException(
        type: type,
        group: fg,
      );
    } else {
      return dep;
    }
  }

  @protected
  @override
  Dependency<Object>? getDependencyUsingExactTypeOrNull1({
    required Gr type,
    Gr? paramsType,
    Gr? group,
    required bool getFromParents,
  }) {
    final fg = preferFocusGroup(group);
    final paramsType1 = paramsType ?? Gr(Object);
    final getters = [
      type,
      FutureOrInst.gr(type, paramsType1),
    ].map(
      (type) {
        return () => registry.getDependencyUsingExactTypeOrNull(
              type: type,
              group: fg,
            );
      },
    );
    for (final getter in getters) {
      final dep = getter();
      if (dep != null) {
        final conditionMet = dep.condition?.call(this) ?? true;
        if (conditionMet) {
          return dep;
        }
      }
    }
    return parent?.getDependencyUsingExactTypeOrNull1(
      type: type,
      paramsType: paramsType,
      group: group,
       getFromParents: getFromParents,
    );
  }

  @protected
  @override
  @pragma('vm:prefer-inline')
  Dependency<Object> getDependencyUsingRuntimeType1({
    required Type type,
    Gr? paramsType,
    Gr? group,
     required bool getFromParents,
  }) {
    return getDependencyUsingExactType1(
      type: Gr(type),
      paramsType: paramsType,
      group: group,
       getFromParents: getFromParents,
    );
  }

  @protected
  @override
  @pragma('vm:prefer-inline')
  Dependency<Object>? getDependencyUsingRuntimeTypeOrNull1({
    required Type type,
    Gr? paramsType,
    Gr? group,
     required bool getFromParents,
  }) {
    return getDependencyUsingExactTypeOrNull1(
      type: Gr(type),
      paramsType: paramsType,
      group: group,
      getFromParents: getFromParents,
    );
  }
}
