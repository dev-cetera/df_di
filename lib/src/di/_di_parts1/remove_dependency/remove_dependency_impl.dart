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
import '/src/di/_di_inter.dart';
import '/src/utils/_dependency.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
base mixin RemoveDependencyImpl on DIBase implements RemoveDependencyIface {
  @override
  Dependency<Object> removeDependency<T extends Object>({
    Descriptor? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final removers = [
      () => registry.removeDependency<T>(group: focusGroup),
      () => registry.removeDependency<FutureInst<T, Object>>(group: focusGroup),
      () => registry.removeDependency<SingletonInst<T, Object>>(group: focusGroup),
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
    required Descriptor type,
    required Descriptor paramsType,
    Descriptor? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final removers = [
      type,
      Descriptor.genericType<FutureInst>([type, paramsType]),
      Descriptor.genericType<SingletonInst>([type, paramsType]),
      Descriptor.genericType<FactoryInst>([type, paramsType]),
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
    required Descriptor paramsType,
    Descriptor? group,
  }) {
    return removeDependencyUsingExactType(
      type: Descriptor.type(type),
      paramsType: Descriptor.type(Object),
      group: group,
    );
  }
}
