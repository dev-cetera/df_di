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
  @protected
  @override
  FutureOr<Object> getUsingExactType({
    required Gr type,
    Gr? group,
  }) {
    final fg = preferFocusGroup(group);
    final value = getUsingExactTypeOrNull(
      type: type,
      group: fg,
    );
    if (value == null) {
      throw DependencyNotFoundException(
        type: type,
        group: fg,
      );
    }
    return value;
  }

  @protected
  @override
  FutureOr<Object>? getUsingExactTypeOrNull({
    required Gr type,
    Gr? group,
  }) {
    final fg = preferFocusGroup(group);
    final dep = _get(type: type, group: fg);
    return dep?.thenOr((e) => e.value);
  }

  @override
  FutureOr<Object> getUsingRuntimeType(
    Type type, {
    Gr? group,
  }) {
    return getUsingExactType(
      type: Gr(type),
      group: group,
    );
  }

  @override
  FutureOr<Object>? getUsingRuntimeTypeOrNull(
    Type type, {
    Gr? group,
  }) {
    return getUsingExactTypeOrNull(
      type: Gr(type),
      group: group,
    );
  }

  FutureOr<Dependency<Object>>? _get({
    required Gr type,
    required Gr group,
  }) {
    final dep = getDependencyUsingExactTypeOrNull1(
      type: type,
      group: group,
    );
    if (dep != null) {
      switch (dep.value) {
        case FutureInst _:
          final genericType = FutureInst.gr(type, Object);
          return _inst(
            type: type,
            genericType: genericType,
            group: group,
          );

        case SingletonInst _:
          final genericType = SingletonInst.gr(type, Object);
          return _inst(
            type: type,
            genericType: genericType,
            group: group,
          );
        case FactoryInst _:
          return dep.cast();
        case Object _:
          return dep.cast();
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
