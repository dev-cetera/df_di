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
base mixin RegisterDependencyImpl on DIBase implements RegisterDependencyIface {
  @override
  void registerDependency<T extends Object>({
    required Dependency<T> dependency,
    bool suppressDependencyAlreadyRegisteredException = false,
  }) {
    final group = dependency.group;
    final dep = registry.getDependencyOrNull<T>(
      group: group,
    );
    if (!suppressDependencyAlreadyRegisteredException && dep != null) {
      throw DependencyAlreadyRegisteredException(
        type: T,
        group: group,
      );
    }
    // Store the dependency in the type map.
    registry.setDependency<T>(
      value: dependency,
    );
  }

  @override
  void registerDependencyUsingExactType({
    required Id type,
    required Dependency<Object> dependency,
    bool suppressDependencyAlreadyRegisteredException = false,
  }) {
    final group = dependency.group;
    final dep = registry.getDependencyUsingExactTypeOrNull(
      type: type,
      group: group,
    );
    if (!suppressDependencyAlreadyRegisteredException && dep != null) {
      throw DependencyAlreadyRegisteredException(
        type: type,
        group: group,
      );
    }
    // Store the dependency in the type map.
    registry.setDependencyUsingExactType(
      type: type,
      value: dependency,
    );
  }

  @override
  void registerDependencyUsingRuntimeType(
    Type type, {
    required Dependency<Object> dependency,
    bool suppressDependencyAlreadyRegisteredException = false,
  }) {
    registerDependencyUsingExactType(
      dependency: dependency,
      type: TypeId(type),
      suppressDependencyAlreadyRegisteredException: suppressDependencyAlreadyRegisteredException,
    );
  }
}
