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

import 'package:meta/meta.dart';

import '../_index.g.dart';
import '/src/_index.g.dart';
import '../../_di_base.dart';
import '../../../_dependency.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
base mixin GetDependencyImpl on DIBase implements GetDependencyIface {
  @override
  Dependency<Object> getDependency<T extends Object>({
    Descriptor? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final dep = getDependencyOrNull<T>(
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
  Dependency<Object> getDependencyUsingExactType({
    required Descriptor type,
    required Descriptor paramsType,
    required Descriptor group,
  }) {
    final dep = getDependencyUsingExactTypeOrNull(
      type: type,
      paramsType: paramsType,
      group: group,
    );
    if (dep == null) {
      throw DependencyNotFoundException(
        type: type,
        group: group,
      );
    } else {
      return dep;
    }
  }

  @override
  Dependency<Object>? getDependencyOrNull<T extends Object>({
    Descriptor? group,
  }) {
    return getFirstNonNull(
      child: this,
      parent: parent,
      test: (di) => _getDependencyOrNull<T>(
        di: di,
        group: group,
      ),
    );
  }

  @override
  Dependency<Object>? getDependencyUsingExactTypeOrNull({
    required Descriptor type,
    required Descriptor paramsType,
    Descriptor? group,
  }) {
    return getFirstNonNull(
      child: this,
      parent: parent,
      test: (di) => _getDependencyUsingExactTypeOrNull(
        di: di,
        type: type,
        paramsType: paramsType,
        group: group,
      ),
    );
  }

  @override
  @pragma('vm:prefer-inline')
  Dependency<Object> getDependencyUsingRuntimeType({
    required Type type,
    required Descriptor paramsType,
    required Descriptor group,
  }) {
    return getDependencyUsingExactType(
      type: Descriptor.type(type),
      paramsType: paramsType,
      group: group,
    );
  }

  @pragma('vm:prefer-inline')
  @override
  Dependency<Object>? getDependencyUsingRuntimeTypeOrNull({
    required Type type,
    required Descriptor paramsType,
    Descriptor? group,
  }) {
    return getDependencyUsingExactTypeOrNull(
      type: Descriptor.type(type),
      paramsType: paramsType,
      group: group,
    );
  }
}

Dependency<Object>? _getDependencyOrNull<T extends Object>({
  required DI di,
  required Descriptor? group,
}) {
  final focusGroup = di.preferFocusGroup(group);
  final getters = [
    () => di.registry.getDependencyOrNull<T>(group: focusGroup),
    () => di.registry.getDependencyOrNull<FutureInst<T>>(group: focusGroup),
    () => di.registry.getDependencyOrNull<SingletonInst<T>>(group: focusGroup),
    () => di.registry.getDependencyOrNull<FactoryInst<T, Object>>(group: focusGroup),
  ];
  for (final getter in getters) {
    final dep = getter();
    if (dep != null) {
      return dep;
    }
  }
  return null;
}

Dependency<Object>? _getDependencyUsingExactTypeOrNull({
  required DI di,
  required Descriptor type,
  required Descriptor paramsType,
  required Descriptor? group,
}) {
  final focusGroup = di.preferFocusGroup(group);
  final getters = [
    type,
    Descriptor.genericType<FutureInst>([type, paramsType]),
    Descriptor.genericType<SingletonInst>([type, paramsType]),
    Descriptor.genericType<FactoryInst>([type, paramsType]),
  ].map(
    (type) => () => di.registry.getDependencyUsingExactTypeOrNull(
          type: type,
          group: focusGroup,
        ),
  );
  for (final getter in getters) {
    final dep = getter();
    if (dep != null) {
      return dep;
    }
  }
  return null;
}
