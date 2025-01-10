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

base mixin SupportsConstructorsMixin on SupportsMixinT {
  /// Registers a [Lazy] dependency with the specified [groupEntity] in the
  /// [registry].
  ///
  /// Lazy dependencies are created by the provided [constructor] function by
  /// either [getSingleton] or [getFactory].
  ///
  /// You can provide a [validator] function to validate the dependency before
  /// it gets retrieved. If the validation fails [DependencyInvalidException]
  /// will be throw upon retrieval.
  ///
  /// Additionally, an [onUnregister] callback can be specified to execute when
  /// the dependency is unregistered via [unregister].
  //Lazy<T>

  Result<void> registerLazy<T extends Object>(
    TConstructor<T> constructor, {
    Entity groupEntity = const Entity.defaultEntity(),
    Option<DependencyValidator<Concur<T>>> validator = const None(),
    Option<OnUnregisterCallback<Concur<T>>> onUnregister = const None(),
  }) {
    return register<Lazy<T>>(
      Sync(Lazy<T>(constructor)),
      groupEntity: groupEntity,
      validator: validator.map(
        (f) => (e) => e.sync.value.currentInstance.fold((instance) => f(instance), () => true),
      ),
      onUnregister: onUnregister.map(
        (f) => (e) =>
            e.sync.value.currentInstance.fold((instance) => f(instance), () => Concur<void>(null)),
      ),
    ).asSync;
  }

  /// Removes the cached instance of type [T] or its subtypes with the
  /// specified [groupEntity] in the [registry].
  ///
  /// This allows it to be re-created via [getSingleton].
  Result<void> resetSingleton<T extends Object>({
    Entity groupEntity = const Entity.defaultEntity(),
  }) {
    return get<Lazy<T>>(groupEntity: groupEntity)
        .map((e) => e.map((e) => e.map((e) => e.resetSingleton())));
  }

  // /// Retrieves a singleton instance of type [T] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
  // ///
  // /// If no instance is cached, a new one is created using the [Lazy]
  // /// constructor provided during registration.
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// If the dependency does not exist, a [DependencyNotFoundException] is
  // /// thrown.
  // ///
  // /// This method always returns a [Future], ensuring compatibility. This
  // /// provides a safe and consistent way to retrieve dependencies, even if the
  // /// registered dependency is not a [Future].
  // Future<T> getSingletonAsync<T extends Object>({
  //   Entity groupEntity = const Entity.defaultEntity(),
  //   bool traverse = true,
  // }) async {
  //   return getSingleton<T>(
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  // }

  // /// Retrieves a singleton instance of type [T] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
  // ///
  // /// If no instance is cached, a new one is created using the [Lazy]
  // /// constructor provided during registration.
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// If the dependency is a [Future], a [DependencyIsFutureException] is
  // /// thrown.
  // ///
  // /// If the dependency does not exist, a [DependencyNotFoundException] is
  // /// thrown.
  // T getSingletonSync<T extends Object>({
  //   Entity groupEntity = const Entity.defaultEntity(),
  //   bool traverse = true,
  // }) {
  //   final value = getSingleton<T>(
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  //   if (value is Future) {
  //     throw DependencyIsFutureException(
  //       type: T,
  //       groupEntity: groupEntity,
  //     );
  //   } else {
  //     return value;
  //   }
  // }

  // /// Retrieves a singleton instance of type [T] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
  // ///
  // /// If no instance is cached, a new one is created using the [Lazy]
  // /// constructor provided during registration.
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// If the dependency is a [Future], a [DependencyIsFutureException] is
  // /// thrown.
  // ///
  // /// Throws a [DependencyIsFutureException] if the dependency is a [Future]
  // /// and [throwIfAsync] is true, otherwise returns `null` if the dependency
  // /// is a [Future].
  // T? getSingletonSyncOrNull<T extends Object>({
  //   Entity groupEntity = const Entity.defaultEntity(),
  //   bool traverse = true,
  //   bool throwIfAsync = false,
  // }) {
  //   final value = getSingletonOrNull<T>(
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  //   if (throwIfAsync && value is Future) {
  //     throw DependencyIsFutureException(
  //       type: T,
  //       groupEntity: groupEntity,
  //     );
  //   }
  //   return value?.asSyncOrNull;
  // }

  // /// Retrieves a singleton instance of type [T] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
  // ///
  // /// If no instance is cached, a new one is created using the [Lazy]
  // /// constructor provided during registration.
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// If the dependency does not exist, a [DependencyNotFoundException] is
  // /// thrown.
  // FutureOr<T> getSingleton<T extends Object>({
  //   Entity groupEntity = const Entity.defaultEntity(),
  //   bool traverse = true,
  // }) {
  //   final groupEntity1 = groupEntity ?? focusGroup;
  //   final value = getSingletonOrNull<T>(
  //     groupEntity: groupEntity1,
  //     traverse: traverse,
  //   );

  //   if (value == null) {
  //     throw DependencyNotFoundException(
  //       type: T,
  //       groupEntity: groupEntity1,
  //     );
  //   }
  //   return value;
  // }

  /// Retrieves a singleton instance of type [T] or its subtypes under the
  /// specified [groupEntity] from the [registry].
  ///
  /// If no instance is cached, a new one is created using the [Lazy]
  /// constructor provided during registration.
  ///
  /// If [traverse] is true, it will also search recursively in parent
  /// containers.
  ///
  /// If the dependency does not exist, `null` is returned.
  Result<Option<Concur<T>>> getSingleton<T extends Object>({
    Entity groupEntity = const Entity.defaultEntity(),
    bool traverse = true,
  }) {
    return get<Lazy<T>>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.map((e) => flattenConcur(e.map((e) => e.singleton))));
  }

  // /// Retrieves a new instance of type [T] or its subtypes from the [registry]
  // /// under the specified [groupEntity] from the [registry].
  // ///
  // /// The instance is created using the [Lazy] constructor provided during the
  // /// registration of the factory dependency.
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// If the dependency does not exist, a [DependencyNotFoundException] is
  // /// thrown.
  // ///
  // /// This method always returns a [Future], ensuring compatibility. This
  // /// provides a safe and consistent way to retrieve dependencies, even if the
  // /// registered dependency is not a [Future].
  // Future<T> getFactoryAsync<T extends Object>({
  //   Entity groupEntity = const Entity.defaultEntity(),
  //   bool traverse = true,
  // }) async {
  //   return getFactory<T>(
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  // }

  // /// Retrieves a new instance of type [T] or its subtypes from the [registry]
  // /// under the specified [groupEntity] from the [registry].
  // ///
  // /// The instance is created using the [Lazy] constructor provided during the
  // /// registration of the factory dependency.
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// If the dependency is a [Future], a [DependencyIsFutureException] is
  // /// thrown.
  // ///
  // /// If the dependency does not exist, a [DependencyNotFoundException] is
  // /// thrown.
  // T getFactorySync<T extends Object>({
  //   Entity groupEntity = const Entity.defaultEntity(),
  //   bool traverse = true,
  // }) {
  //   final value = getFactory<T>(
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  //   if (value is Future) {
  //     throw DependencyIsFutureException(
  //       type: T,
  //       groupEntity: groupEntity,
  //     );
  //   } else {
  //     return value;
  //   }
  // }

  // /// Retrieves a new instance of type [T] or its subtypes from the [registry]
  // /// under the specified [groupEntity] from the [registry].
  // ///
  // /// The instance is created using the [Lazy] constructor provided during the
  // /// registration of the factory dependency.
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// If the dependency is a [Future], a [DependencyIsFutureException] is
  // /// thrown.
  // ///
  // /// Throws a [DependencyIsFutureException] if the dependency is a [Future]
  // /// and [throwIfAsync] is true, otherwise returns `null` if the dependency
  // /// is a [Future].
  // T? getFactorySyncOrNull<T extends Object>({
  //   Entity groupEntity = const Entity.defaultEntity(),
  //   bool traverse = true,
  //   bool throwIfAsync = false,
  // }) {
  //   final value = getFactoryOrNull<T>(
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  //   if (throwIfAsync && value is Future) {
  //     throw DependencyIsFutureException(
  //       type: T,
  //       groupEntity: groupEntity,
  //     );
  //   }
  //   return value?.asSyncOrNull;
  // }

  // /// Retrieves a new instance of type [T] or its subtypes from the [registry]
  // /// under the specified [groupEntity] from the [registry].
  // ///
  // /// The instance is created using the [Lazy] constructor provided during the
  // /// registration of the factory dependency.
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// If the dependency does not exist, a [DependencyNotFoundException] is
  // /// thrown.
  // FutureOr<T> getFactory<T extends Object>({
  //   Entity groupEntity = const Entity.defaultEntity(),
  //   bool traverse = true,
  // }) {
  //   final groupEntity1 = groupEntity ?? focusGroup;
  //   final value = getFactoryOrNull<T>(
  //     groupEntity: groupEntity1,
  //     traverse: traverse,
  //   );

  //   if (value == null) {
  //     throw DependencyNotFoundException(
  //       type: T,
  //       groupEntity: groupEntity1,
  //     );
  //   }
  //   return value;
  // }

  /// Retrieves a new instance of type [T] or its subtypes from the [registry]
  /// under the specified [groupEntity] from the [registry].
  ///
  /// The instance is created using the [Lazy] constructor provided during the
  /// registration of the factory dependency.
  ///
  /// If [traverse] is true, it will also search recursively in parent
  /// containers.
  ///
  /// If the dependency does not exist, `null` is returned.
  Result<Option<Concur<T>>> getFactory<T extends Object>({
    Entity groupEntity = const Entity.defaultEntity(),
    bool traverse = true,
  }) {
    return get<Lazy<T>>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.map((e) => flattenConcur(e.map((e) => e.singleton))));
  }
}
