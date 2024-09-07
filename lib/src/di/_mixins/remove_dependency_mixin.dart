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
  Dependency<Object> removeDependency<T extends Object, P extends Object>({
    DIKey? typeGroup,
  }) {
    final fg = preferFocusGroup(typeGroup);
    final removers = [
      () => registry.removeDependency<T>(typeGroup: fg),
      () => registry.removeDependency<FutureOrInst<T, P>>(typeGroup: fg),
    ];
    for (final remover in removers) {
      final dep = remover();
      if (dep != null) {
        return dep;
      }
    }
    throw DependencyNotFoundException(
      type: T,
      typeGroup: fg,
    );
  }

  @protected
  @override
  Dependency<Object> removeDependencyUsingExactType({
    required DIKey type,
    DIKey? paramsType,
    DIKey? typeGroup,
  }) {
    final fg = preferFocusGroup(typeGroup);
    final paramsType1 = paramsType ?? DIKey(Object);
    final removers = [
      type,
      FutureOrInst.gr(type, paramsType1),
    ].map(
      (type) => () => registry.removeDependencyByType(
            type: type,
            typeGroup: fg,
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
      typeGroup: fg,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  Dependency<Object> removeDependencyOfRuntimeType({
    required Type type,
    DIKey? paramsType,
    DIKey? typeGroup,
  }) {
    return removeDependencyUsingExactType(
      type: DIKey(type),
      paramsType: paramsType,
      typeGroup: typeGroup,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
abstract interface class RemoveDependencyInterface {
  /// ...

  Dependency<Object> removeDependency<T extends Object, P extends Object>({
    DIKey? typeGroup,
  });

  /// ...

  Dependency<Object> removeDependencyUsingExactType({
    required DIKey type,
    DIKey? paramsType,
    DIKey? typeGroup,
  });

  /// ...

  Dependency<Object> removeDependencyOfRuntimeType({
    required Type type,
    DIKey? paramsType,
    DIKey? typeGroup,
  });
}
