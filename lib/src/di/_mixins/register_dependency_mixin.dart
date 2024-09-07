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
base mixin RegisterDependencyMixin on DIBase implements RegisterDependencyInterface {
  @protected
  @override
  void registerDependency<T extends Object, P extends Object>({
    required Dependency<T> dependency,
    bool suppressDependencyAlreadyRegisteredException = false,
  }) {
    final typeGroup = dependency.metadata.typeGroup;
    final dep = getDependencyOrNull1<T, P>(
      typeGroup: typeGroup,
      getFromParents: false,
    );
    if (!suppressDependencyAlreadyRegisteredException && dep != null) {
      throw DependencyAlreadyRegisteredException(
        type: T,
        typeGroup: typeGroup,
      );
    }
    // Store the dependency in the type map.
    registry.setDependency<T>(
      value: dependency,
    );
  }

  @protected
  @override
  void registerDependencyUsingExactType({
    required DIKey type,
    required Dependency<Object> dependency,
    bool suppressDependencyAlreadyRegisteredException = false,
  }) {
    final typeGroup = dependency.metadata.typeGroup;
    final dep = getDependencyUsingExactTypeOrNull1(
      type: type,
      typeGroup: typeGroup,
      getFromParents: false,
    );
    if (!suppressDependencyAlreadyRegisteredException && dep != null) {
      throw DependencyAlreadyRegisteredException(
        type: type,
        typeGroup: typeGroup,
      );
    }
    // Store the dependency in the type map.
    registry.setDependencyUsingExactType(
      type: type,
      value: dependency,
    );
  }

  @protected
  @override
  void registerDependencyUsingRuntimeType(
    Type type, {
    required Dependency<Object> dependency,
    bool suppressDependencyAlreadyRegisteredException = false,
  }) {
    registerDependencyUsingExactType(
      dependency: dependency,
      type: DIKey(type),
      suppressDependencyAlreadyRegisteredException: suppressDependencyAlreadyRegisteredException,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
abstract interface class RegisterDependencyInterface {
  void registerDependency<T extends Object, P extends Object>({
    required Dependency<T> dependency,
    bool suppressDependencyAlreadyRegisteredException = false,
  });

  void registerDependencyUsingExactType({
    required DIKey type,
    required Dependency<Object> dependency,
    bool suppressDependencyAlreadyRegisteredException = false,
  });

  void registerDependencyUsingRuntimeType(
    Type type, {
    required Dependency<Object> dependency,
    bool suppressDependencyAlreadyRegisteredException = false,
  });
}
