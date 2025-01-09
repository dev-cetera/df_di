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
  // /// Registers a [Lazy] dependency with the specified [groupEntity] in the
  // /// [registry].
  // ///
  // /// Lazy dependencies are created by the provided [constructor] function by
  // /// either [getSingleton] or [getFactory].
  // ///
  // /// You can provide a [validator] function to validate the dependency before
  // /// it gets retrieved. If the validation fails [DependencyInvalidException]
  // /// will be throw upon retrieval.
  // ///
  // /// Additionally, an [onUnregister] callback can be specified to execute when
  // /// the dependency is unregistered via [unregister].
  // Lazy<T> registerLazy<T extends Object>(
  //   TConstructor<T> constructor, {
  //   Entity? groupEntity,
  //   bool Function(FutureOr<T> instance)? validator,
  //   FutureOr<void> Function(FutureOr<T> instance)? onUnregister,
  // }) {
  //   return register<Lazy<T>>(
  //     Lazy<T>(constructor),
  //     groupEntity: groupEntity,
  //     validator: validator != null
  //         ? (constructor) {
  //             final instance = constructor.asSync.currentInstance;
  //             return instance != null ? validator(instance) : true;
  //           }
  //         : null,
  //     onUnregister: onUnregister != null
  //         ? (constructor) {
  //             final instance = constructor.asSync.currentInstance;
  //             return instance != null ? onUnregister(instance) : null;
  //           }
  //         : null,
  //   ).asSync;
  // }

  // /// Removes the cached instance of type [T] or its subtypes with the
  // /// specified [groupEntity] in the [registry].
  // ///
  // /// This allows it to be re-created via [getSingleton].
  // void resetSingleton<T extends Object>({
  //   Entity? groupEntity,
  // }) {
  //   get<Lazy<T>>(groupEntity: groupEntity).asSync.resetSingleton();
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
  // ///
  // /// This method always returns a [Future], ensuring compatibility. This
  // /// provides a safe and consistent way to retrieve dependencies, even if the
  // /// registered dependency is not a [Future].
  // Future<T> getSingletonAsync<T extends Object>({
  //   Entity? groupEntity,
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
  //   Entity? groupEntity,
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
  //   Entity? groupEntity,
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
  //   Entity? groupEntity,
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

  // /// Retrieves a singleton instance of type [T] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
  // ///
  // /// If no instance is cached, a new one is created using the [Lazy]
  // /// constructor provided during registration.
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// If the dependency does not exist, `null` is returned.
  // FutureOr<T>? getSingletonOrNull<T extends Object>({
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   return getOrNull<Lazy<T>>(
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   )?.asSyncOrNull?.singleton;
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
  // ///
  // /// This method always returns a [Future], ensuring compatibility. This
  // /// provides a safe and consistent way to retrieve dependencies, even if the
  // /// registered dependency is not a [Future].
  // Future<T> getFactoryAsync<T extends Object>({
  //   Entity? groupEntity,
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
  //   Entity? groupEntity,
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
  //   Entity? groupEntity,
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
  //   Entity? groupEntity,
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

  // /// Retrieves a new instance of type [T] or its subtypes from the [registry]
  // /// under the specified [groupEntity] from the [registry].
  // ///
  // /// The instance is created using the [Lazy] constructor provided during the
  // /// registration of the factory dependency.
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// If the dependency does not exist, `null` is returned.
  // FutureOr<T>? getFactoryOrNull<T extends Object>({
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   return getOrNull<Lazy<T>>(
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   )?.asSyncOrNull?.factory;
  // }
}
