//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// ignore_for_file: invalid_use_of_protected_member

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base mixin SupportsConstructorsMixinT on SupportsMixinT {
  /// Removes the cached instance of the exact [type] with the specified
  /// [groupEntity] in the [registry].
  ///
  /// This allows it to be re-created via [getSingletonT].
  void resetSingletonT(
    Type type, {
    Entity? groupEntity,
  }) {
    (getK(TypeEntity(Lazy, [type]), groupEntity: groupEntity) as Lazy).resetSingleton();
  }

  /// Retrieves a singleton instance of the exact [type] under the specified
  /// [groupEntity] from the [registry].
  ///
  /// Upon result, the [Object] can be cast [type].
  ///
  /// If no instance is cached, a new one is created using the [Lazy]
  /// constructor provided during registration.
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  ///
  /// If the dependency does not exist, a [DependencyNotFoundException] is
  /// thrown.
  ///
  /// This method always returns a [Future], ensuring compatibility. This
  /// provides a safe and consistent way to retrieve dependencies, even if the
  /// registered dependency is not a [Future].
  Future<Object> getSingletonAsyncT(
    Type type, {
    Entity? groupEntity,
    bool traverse = true,
  }) async {
    return getSingletonT(
      type,
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Retrieves a singleton instance of the exact [type] under the
  /// specified [groupEntity] from the [registry].
  ///
  /// Upon result, the [Object] can be cast [type].
  ///
  /// If no instance is cached, a new one is created using the [Lazy]
  /// constructor provided during registration.
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  ///
  /// If the dependency is a [Future], a [DependencyIsFutureException] is
  /// thrown.
  ///
  /// If the dependency does not exist, a [DependencyNotFoundException] is
  /// thrown.
  Object getSingletonSyncT(
    Type type, {
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final value = getSingletonT(
      type,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (value is Future) {
      throw DependencyIsFutureException(
        type: type,
        groupEntity: groupEntity,
      );
    } else {
      return value;
    }
  }

  /// Retrieves a singleton instance of  of the exact [type] under the
  /// specified [groupEntity] from the [registry].
  ///
  /// Upon result, the [Object] can be cast [type].
  ///
  /// If no instance is cached, a new one is created using the [Lazy]
  /// constructor provided during registration.
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  ///
  /// If the dependency is a [Future], a [DependencyIsFutureException] is
  /// thrown.
  ///
  /// Throws a [DependencyIsFutureException] if the dependency is a [Future]
  /// and [throwIfAsync] is true, otherwise returns `null` if the dependency
  /// is a [Future].
  Object? getSingletonSyncOrNullT(
    Type type, {
    Entity? groupEntity,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getSingletonOrNullT(
      type,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (throwIfAsync && value is Future) {
      throw DependencyIsFutureException(
        type: type,
        groupEntity: groupEntity,
      );
    }
    return value?.asSyncOrNull;
  }

  /// Retrieves a singleton instance of the exact type  under the
  /// specified [groupEntity] from the [registry].
  ///
  /// Upon result, the [Object] can be cast [type].
  ///
  /// If no instance is cached, a new one is created using the [Lazy]
  /// constructor provided during registration.
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  ///
  /// If the dependency does not exist, a [DependencyNotFoundException] is
  /// thrown.
  FutureOr<Object> getSingletonT(
    Type type, {
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final groupEntity1 = groupEntity ?? focusGroup;
    final value = getSingletonOrNullT(
      type,
      groupEntity: groupEntity1,
      traverse: traverse,
    );

    if (value == null) {
      throw DependencyNotFoundException(
        type: type,
        groupEntity: groupEntity1,
      );
    }
    return value;
  }

  /// Retrieves a singleton instance of the exact [type] under the
  /// specified [groupEntity] from the [registry].
  ///
  /// Upon result, the [Object] can be cast [type].
  ///
  /// If no instance is cached, a new one is created using the [Lazy]
  /// constructor provided during registration.
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  ///
  /// If the dependency does not exist, `null` is returned.
  FutureOr<Object>? getSingletonOrNullT(
    Type type, {
    Entity? groupEntity,
    bool traverse = true,
  }) {
    return (getOrNullK(
      TypeEntity(Lazy, [type]),
      groupEntity: groupEntity,
      traverse: traverse,
    ) as Lazy?)
        ?.singleton;
  }

  /// Retrieves a new instance of the exact [type] from the [registry] under
  /// the specified [groupEntity] from the [registry].
  ///
  /// Upon result, the [Object] can be cast [type].
  ///
  /// The instance is created using the [Lazy] constructor provided during the
  /// registration of the factory dependency.
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  ///
  /// If the dependency does not exist, a [DependencyNotFoundException] is
  /// thrown.
  ///
  /// This method always returns a [Future], ensuring compatibility. This
  /// provides a safe and consistent way to retrieve dependencies, even if the
  /// registered dependency is not a [Future].
  Future<Object> getFactoryAsyncT(
    Type type, {
    Entity? groupEntity,
    bool traverse = true,
  }) async {
    return getFactoryT(
      type,
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Retrieves a new instance of the exact [type] from the [registry] under
  /// the specified [groupEntity] from the [registry].
  ///
  /// Upon result, the [Object] can be cast [type].
  ///
  /// The instance is created using the [Lazy] constructor provided during the
  /// registration of the factory dependency.
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  ///
  /// If the dependency is a [Future], a [DependencyIsFutureException] is
  /// thrown.
  ///
  /// If the dependency does not exist, a [DependencyNotFoundException] is
  /// thrown.
  Object getFactorySyncT(
    Type type, {
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final value = getFactoryT(
      type,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (value is Future) {
      throw DependencyIsFutureException(
        type: type,
        groupEntity: groupEntity,
      );
    } else {
      return value;
    }
  }

  /// Retrieves a new instance of the exact [type] from the [registry] under the
  /// specified [groupEntity] from the [registry].
  ///
  /// Upon result, the [Object] can be cast [type].
  ///
  /// The instance is created using the [Lazy] constructor provided during the
  /// registration of the factory dependency.
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  ///
  /// If the dependency is a [Future], a [DependencyIsFutureException] is
  /// thrown.
  ///
  /// Throws a [DependencyIsFutureException] if the dependency is a [Future]
  /// and [throwIfAsync] is true, otherwise returns `null` if the dependency
  /// is a [Future].
  Object? getFactorySyncOrNullT(
    Type type, {
    Entity? groupEntity,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getFactoryOrNullT(
      type,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (throwIfAsync && value is Future) {
      throw DependencyIsFutureException(
        type: type,
        groupEntity: groupEntity,
      );
    }
    return value?.asSyncOrNull;
  }

  /// Retrieves a new instance of the exact [type] from the [registry] under
  /// the specified [groupEntity] from the [registry].
  ///
  /// Upon result, the [Object] can be cast [type].
  ///
  /// The instance is created using the [Lazy] constructor provided during the
  /// registration of the factory dependency.
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  ///
  /// If the dependency does not exist, a [DependencyNotFoundException] is
  /// thrown.
  FutureOr<Object> getFactoryT(
    Type type, {
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final groupEntity1 = groupEntity ?? focusGroup;
    final value = getFactoryOrNullT(
      type,
      groupEntity: groupEntity1,
      traverse: traverse,
    );
    if (value == null) {
      throw DependencyNotFoundException(
        type: type,
        groupEntity: groupEntity1,
      );
    }
    return value;
  }

  /// Retrieves a new instance of the exact [type] from the [registry] under
  /// the specified [groupEntity] from the [registry].
  ///
  /// Upon result, the [Object] can be cast [type].
  ///
  /// The instance is created using the [Lazy] constructor provided during the
  /// registration of the factory dependency.
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  ///
  /// If the dependency does not exist, `null` is returned.
  FutureOr<Object>? getFactoryOrNullT(
    Type type, {
    Entity? groupEntity,
    bool traverse = true,
  }) {
    return (getOrNullK(
      TypeEntity(Lazy, [type]),
      groupEntity: groupEntity,
      traverse: traverse,
    ) as Lazy?)
        ?.factory;
  }
}
