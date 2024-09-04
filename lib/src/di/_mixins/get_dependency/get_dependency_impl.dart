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
  @override
  Dependency<Object> getDependency1<T extends Object>({
    Id? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final dep = getDependencyOrNull1<T>(
      group: group,
    );
    if (dep == null) {
      throw DependencyNotFoundException(
        type: T,
        group: focusGroup,
      );
    } else {
      return dep;
    }
  }

  @override
  Dependency<Object>? getDependencyOrNull1<T extends Object>({
    Id? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final getters = [
      () => registry.getDependencyOrNull<T>(group: focusGroup),
      () => registry.getDependencyOrNull<FutureInst<T>>(group: focusGroup),
      () => registry.getDependencyOrNull<SingletonInst<T>>(group: focusGroup),
      () => registry.getDependencyOrNull<FactoryInst<T, Object>>(group: focusGroup),
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
    return parent?.getDependencyOrNull1<T>(
      group: group,
    );
  }

  @override
  Dependency<Object> getDependencyUsingExactType1({
    required Id type,
    Id? paramsType,
    Id? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final dep = getDependencyUsingExactTypeOrNull1(
      type: type,
      paramsType: paramsType,
      group: group,
    );
    if (dep == null) {
      throw DependencyNotFoundException(
        type: type,
        group: focusGroup,
      );
    } else {
      return dep;
    }
  }

  @override
  Dependency<Object>? getDependencyUsingExactTypeOrNull1({
    required Id type,
    Id? paramsType,
    Id? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final getters = [
      type,
      GenericTypeId<FutureInst>([type, paramsType]),
      GenericTypeId<SingletonInst>([type, paramsType]),
      GenericTypeId<FactoryInst>([type, paramsType]),
    ].map(
      (type) => () => registry.getDependencyUsingExactTypeOrNull(
            type: type,
            group: focusGroup,
          ),
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
    );
  }

  @override
  @pragma('vm:prefer-inline')
  Dependency<Object> getDependencyUsingRuntimeType1({
    required Type type,
    Id? paramsType,
    Id? group,
  }) {
    return getDependencyUsingExactType1(
      type: TypeId(type),
      paramsType: paramsType,
      group: group,
    );
  }

  @pragma('vm:prefer-inline')
  @override
  Dependency<Object>? getDependencyUsingRuntimeTypeOrNull1({
    required Type type,
    Id? paramsType,
    Id? group,
  }) {
    return getDependencyUsingExactTypeOrNull1(
      type: TypeId(type),
      paramsType: paramsType,
      group: group,
    );
  }
}
