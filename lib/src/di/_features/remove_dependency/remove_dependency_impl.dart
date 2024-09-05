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

import '/src/_internal.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
base mixin RemoveDependencyImpl on DIBase implements RemoveDependencyIface {
  @override
  Dependency<Object> removeDependency<T extends Object, P extends Object>({
    Gr? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final removers = [
      () => registry.removeDependency<T>(group: focusGroup),
      () => registry.removeDependency<FutureInst<T, P>>(group: focusGroup),
      () => registry.removeDependency<SingletonInst<T, P>>(group: focusGroup),
      () => registry.removeDependency<FactoryInst<T, P>>(group: focusGroup),
    ];
    for (final remover in removers) {
      final dep = remover();
      if (dep != null) {
        return dep;
      }
    }
    throw DependencyNotFoundException(
      type: T,
      group: focusGroup,
    );
  }

  @protected
  @override
  Dependency<Object> removeDependencyUsingExactType({
    required Gr type,
    Gr? paramsType,
    Gr? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final paramsType1 = paramsType ?? Gr(Object);
    final removers = [
      type,
      FutureInst.gr(type, paramsType1),
      SingletonInst.gr(type, paramsType1),
      FactoryInst.gr(type, paramsType1),
    ].map(
      (type) => () => registry.removeDependencyUsingExactType(
            type: type,
            group: focusGroup,
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
      group: focusGroup,
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
