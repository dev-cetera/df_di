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
base mixin RemoveDependencyMixin on DIBase implements RemoveDependencyInterface {
  @override
  Dependency removeDependency<T extends Object, P extends Object>({
    DIKey? groupKey,
  }) {
    final fg = preferFocusGroup(groupKey);
    final removers = [
      () => registry.removeDependency<T>(groupKey: fg),
      () => registry.removeDependency<FutureOrInst<T, P>>(groupKey: fg),
    ];
    for (final remover in removers) {
      final dep = remover();
      if (dep != null) {
        return dep;
      }
    }
    throw DependencyNotFoundException(
      type: T,
      groupKey: fg,
    );
  }

  @protected
  @override
  Dependency removeDependencyUsingExactType({
    required DIKey type,
    DIKey? paramsType,
    DIKey? groupKey,
  }) {
    final fg = preferFocusGroup(groupKey);
    final paramsType1 = paramsType ?? DIKey(Object);
    final removers = [
      type,
      FutureOrInst.gr(type, paramsType1),
    ].map(
      (type) => () => registry.removeDependencyOfType(
            type: type,
            groupKey: fg,
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
      groupKey: fg,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  Dependency removeDependencyOfRuntimeType({
    required Type type,
    DIKey? paramsType,
    DIKey? groupKey,
  }) {
    return removeDependencyUsingExactType(
      type: DIKey(type),
      paramsType: paramsType,
      groupKey: groupKey,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
abstract interface class RemoveDependencyInterface {
  /// ...

  Dependency removeDependency<T extends Object, P extends Object>({
    DIKey? groupKey,
  });

  /// ...

  Dependency removeDependencyUsingExactType({
    required DIKey type,
    DIKey? paramsType,
    DIKey? groupKey,
  });

  /// ...

  Dependency removeDependencyOfRuntimeType({
    required Type type,
    DIKey? paramsType,
    DIKey? groupKey,
  });
}
