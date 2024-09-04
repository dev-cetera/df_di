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
base mixin GetUsingExactTypeImpl on DIBase implements GetUsingExactTypeIface {
  @override
  FutureOr<Object> getUsingExactType({
    required Gr type,
    Gr? group,
  }) {
    focusGroup = preferFocusGroup(group);
    final dep = _get(type: type, group: focusGroup);
    if (dep == null) {
      throw DependencyNotFoundException(
        type: type,
        group: focusGroup,
      );
    }
    return dep.thenOr((e) => e.value);
  }

  @override
  FutureOr<Object> getUsingRuntimeType(
    Type type, {
    Gr? group,
  }) {
    return getUsingExactType(
      type: TypeGr(type),
      group: group,
    );
  }

  @protected
  FutureOr<Dependency<Object>>? _get({
    required Gr type,
    required Gr group,
  }) {
    // Sync types.
    {
      final dep = registry.getDependencyUsingExactTypeOrNull(
        type: type,
        group: group,
      );
      if (dep != null) {
        return dep;
      }
    }
    // Future types.
    {
      final genericType = GenericTypeGr<FutureInst>([type, TypeGr(Object)]);
      final res = _inst(
        type: type,
        genericType: genericType,
        group: group,
      );
      if (res != null) {
        return res;
      }
    }
    // Singleton types.
    {
      final genericType = GenericTypeGr<SingletonInst>([type, TypeGr(Object)]);
      final res = _inst(
        type: type,
        genericType: genericType,
        group: group,
      );
      if (res != null) {
        return res;
      }
    }
    return null;
  }

  FutureOr<Dependency<Object>>? _inst({
    required Gr type,
    required Gr genericType,
    required Gr group,
  }) {
    final dep = registry.getDependencyUsingExactTypeOrNull(
      type: genericType,
      group: group,
    );
    if (dep != null) {
      final value = dep.value;
      return value.thenOr((value) {
        return (value as Inst).constructor(-1);
      }).thenOr((newValue) {
        return registerDependencyUsingExactType(
          type: type,
          dependency: dep.reassign(newValue),
          suppressDependencyAlreadyRegisteredException: true,
        );
      }).thenOr((_) {
        return registry.removeDependencyUsingExactType(
          type: genericType,
          group: group,
        );
      }).thenOr((_) {
        return _get(
          type: type,
          group: group,
        )!;
      });
    }
    return null;
  }
}
