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
base mixin RemoveDependencyImpl on DIBase implements RemoveDependencyIface {
  @override
  Dependency<Object> removeDependency<T extends Object, P extends Object>({
    Gr? group,
  }) {
    final fg = preferFocusGroup(group);
    final removers = [
      () => registry.removeDependency<T>(group: fg),
      () => registry.removeDependency<FutureOrInst<T, P>>(group: fg),
      () => registry.removeDependency<SingletonInst<T, P>>(group: fg),
      () => registry.removeDependency<FactoryInst<T, P>>(group: fg),
    ];
    for (final remover in removers) {
      final dep = remover();
      if (dep != null) {
        return dep;
      }
    }
    throw DependencyNotFoundException(
      type: T,
      group: fg,
    );
  }

  @protected
  @override
  Dependency<Object> removeDependencyUsingExactType({
    required Gr type,
    Gr? paramsType,
    Gr? group,
  }) {
    final fg = preferFocusGroup(group);
    final paramsType1 = paramsType ?? Gr(Object);
    final removers = [
      type,
      FutureOrInst.gr(type, paramsType1),
      SingletonInst.gr(type, paramsType1),
      FactoryInst.gr(type, paramsType1),
    ].map(
      (type) => () => registry.removeDependencyUsingExactType(
            type: type,
            group: fg,
          ),
    );
    for (final remover in removers) {
      final dep = remover();
      if (dep != null) {
        return dep;
      }
    }
    throw DependencyNotFoundException(
      type: type,
      group: fg,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  Dependency<Object> removeDependencyOfRuntimeType({
    required Type type,
    Gr? paramsType,
    Gr? group,
  }) {
    return removeDependencyUsingExactType(
      type: Gr(type),
      paramsType: paramsType,
      group: group,
    );
  }
}
