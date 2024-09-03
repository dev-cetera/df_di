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

import 'package:meta/meta.dart';

import '../_index.g.dart';
import '/src/_index.g.dart';
import '../../_di_base.dart';
import '../../../_dependency.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
base mixin RemoveDependencyImpl on DIBase implements RemoveDependencyIface {
  @override
  Dependency<Object> removeDependency<T extends Object>({
    Id? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final removers = [
      () => registry.removeDependency<T>(group: focusGroup),
      () => registry.removeDependency<FutureInst<T>>(group: focusGroup),
      () => registry.removeDependency<SingletonInst<T>>(group: focusGroup),
      () => registry.removeDependency<FactoryInst<T, Object>>(group: focusGroup),
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

  @override
  Dependency<Object> removeDependencyUsingExactType({
    required Id type,
    required Id paramsType,
    Id? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final removers = [
      type,
      GenericTypeId<FutureInst>([type, paramsType]),
      GenericTypeId<SingletonInst>([type, paramsType]),
      GenericTypeId<FactoryInst>([type, paramsType]),
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
    required Id paramsType,
    Id? group,
  }) {
    return removeDependencyUsingExactType(
      type: TypeId(type),
      paramsType: TypeId(Object),
      group: group,
    );
  }
}
