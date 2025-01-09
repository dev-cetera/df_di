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

base mixin SupportsServicesMixinT on SupportsConstructorsMixinT, SupportsMixinT {
  // /// Retrieves an instance of the exact [type] under the specified
  // /// [groupEntity] from the [registry].
  // ///
  // /// If no instance is cached, a new one is created using the [Lazy]
  // /// constructor provided during registration.
  // ///
  // /// Calls [Service.init] with the provided [params] on first retrieval.
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// Throws a [DependencyNotFoundException] if the dependency does not exist.
  // FutureOr<Service> getServiceSingletonT(
  //   Type type, {
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   final groupEntity1 = groupEntity ?? focusGroup;
  //   final value = getServiceSingletonOrNullT(
  //     type,
  //     params: params,
  //     groupEntity: groupEntity1,
  //     traverse: traverse,
  //   );

  //   if (value == null) {
  //     throw DependencyNotFoundException(
  //       type: type,
  //       groupEntity: groupEntity1,
  //     );
  //   }
  //   return value;
  // }

  // /// Retrieves an instance of the exact [type] under the specified
  // /// [groupEntity] from the [registry].
  // ///
  // /// If no instance is cached, a new one is created using the [Lazy]
  // /// constructor provided during registration.
  // ///
  // /// Calls [Service.init] with the provided [params] on first retrieval.
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// Throws a [DependencyNotFoundException] if the dependency does not exist.
  // FutureOr<Service>? getServiceSingletonOrNullT(
  //   Type type, {
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   final instance = getSingletonOrNullT(type);
  //   return instance?.thenOr((e) {
  //     e as Service;
  //     return e.initialized ? e : consec(e.init(params), (_) => e);
  //   });
  // }

  // /// Retrieves an instance of the exact [type] under the specified
  // /// [groupEntity] from the [registry].
  // ///
  // /// If no instance is cached, a new one is created using the [Lazy]
  // /// constructor provided during registration.
  // ///
  // /// Calls [Service.init] with the provided [params] on first retrieval.
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// Throws a [DependencyNotFoundException] if the dependency does not exist.
  // ///
  // /// Throws a [DependencyIsFutureException] if the dependency is a [Future].
  // Service getServiceSingletonSyncT(
  //   Type type, {
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   final value = getServiceSingletonT(
  //     type,
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  //   if (value is Future) {
  //     throw DependencyIsFutureException(
  //       type: type,
  //       groupEntity: groupEntity,
  //     );
  //   }
  //   return value;
  // }

  // /// Retrieves an instance of the exact [type] under the specified
  // /// [groupEntity] from the [registry].
  // ///
  // /// If no instance is cached, a new one is created using the [Lazy]
  // /// constructor provided during registration.
  // ///
  // /// Calls [Service.init] with the provided [params] on first retrieval.
  // ///
  // /// Throws a [DependencyIsFutureException] if the dependency is a [Future].
  // ///
  // /// Throws a [DependencyIsFutureException] if the dependency is a [Future]
  // /// and [throwIfAsync] is true, otherwise returns `null` if the dependency
  // /// is a [Future].
  // Service? getServiceSingletonSyncOrNullT(
  //   Type type, {
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  //   bool throwIfAsync = false,
  // }) {
  //   final value = getServiceSingletonOrNullT(
  //     type,
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  //   if (throwIfAsync && value is Future) {
  //     throw DependencyIsFutureException(
  //       type: type,
  //       groupEntity: groupEntity,
  //     );
  //   }
  //   return value?.asSyncOrNull;
  // }

  // /// Retrieves an instance of the exact [type] under the specified
  // /// [groupEntity] from the [registry].
  // ///
  // /// Calls [Service.init] with the provided [params] on first retrieval.
  // ///
  // /// Throws a [DependencyNotFoundException] if the dependency does not exist.
  // ///
  // /// This method always returns a [Future], ensuring compatibility. This
  // /// provides a safe and consistent way to retrieve dependencies, even if the
  // /// registered dependency is not a [Future].
  // Future<Service> getServiceSingletonAsyncT(
  //   Type type, {
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) async {
  //   return getServiceSingletonT(
  //     type,
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  // }

  // /// Retrieves a new instance of the exact [type] under the specified
  // /// [groupEntity] from the [registry].
  // ///
  // /// The instance is created using the [Lazy] constructor provided during
  // /// the registration of the factory dependency, then calls [Service.init]
  // /// with the provided [params].
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// Throws a [DependencyNotFoundException] if the dependency does not exist.
  // FutureOr<Service> getServiceFactoryT(
  //   Type type, {
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   final groupEntity1 = groupEntity ?? focusGroup;
  //   final value = getServiceFactoryOrNullT(
  //     type,
  //     params: params,
  //     groupEntity: groupEntity1,
  //     traverse: traverse,
  //   );
  //   if (value == null) {
  //     throw DependencyNotFoundException(
  //       type: type,
  //       groupEntity: groupEntity1,
  //     );
  //   }
  //   return value;
  // }

  // /// Retrieves a new instance of the exact [type] under the specified
  // /// [groupEntity] from the [registry].
  // ///
  // /// The instance is created using the [Lazy] constructor provided during
  // /// the registration of the factory dependency, then calls [Service.init]
  // /// with the provided [params].
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// Returns `null` if the dependency does not exist.
  // FutureOr<Service>? getServiceFactoryOrNullT(
  //   Type type, {
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   final instance = getFactoryOrNullT(type);
  //   return instance?.thenOr((e) {
  //     e as Service;
  //     return e.initialized ? e : consec(e.init(params), (_) => e);
  //   });
  // }

  // /// Retrieves a new instance of the exact [type] under the specified
  // /// [groupEntity] from the [registry].
  // ///
  // /// The instance is created using the [Lazy] constructor provided during
  // /// the registration of the factory dependency, then calls [Service.init]
  // /// with the provided [params].
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// Throws a [DependencyNotFoundException] if the dependency does not exist.
  // ///
  // /// Throws a [DependencyIsFutureException] if the dependency is a [Future].
  // Service getServiceFactorySyncT(
  //   Type type, {
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   final value = getServiceFactoryT(
  //     type,
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  //   if (value is Future) {
  //     throw DependencyIsFutureException(
  //       type: type,
  //       groupEntity: groupEntity,
  //     );
  //   }
  //   return value;
  // }

  // /// Retrieves a new instance of the exact [type] under the specified
  // /// [groupEntity] from the [registry].
  // ///
  // /// The instance is created using the [Lazy] constructor provided during
  // /// the registration of the factory dependency, then calls [Service.init]
  // /// with the provided [params].
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// Throws a [DependencyNotFoundException] if the dependency does not exist.
  // ///
  // /// Throws a [DependencyIsFutureException] if the dependency is a [Future]
  // /// and [throwIfAsync] is true, otherwise returns `null` if the dependency
  // /// is a [Future].
  // Service? getServiceFactorySyncOrNullT(
  //   Type type, {
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  //   bool throwIfAsync = false,
  // }) {
  //   final value = getServiceFactoryOrNullT(
  //     type,
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  //   if (throwIfAsync && value is Future) {
  //     throw DependencyIsFutureException(
  //       type: type,
  //       groupEntity: groupEntity,
  //     );
  //   }
  //   return value?.asSyncOrNull;
  // }

  // /// Retrieves a new instance of the exact [type] under the specified
  // /// [groupEntity] from the [registry].
  // ///
  // /// The instance is created using the [Lazy] constructor provided during
  // /// the registration of the factory dependency, then calls [Service.init]
  // /// with the provided [params].
  // ///
  // /// Throws a [DependencyNotFoundException] if the dependency does not exist.
  // ///
  // /// This method always returns a [Future], ensuring compatibility. This
  // /// provides a safe and consistent way to retrieve dependencies, even if the
  // /// registered dependency is not a [Future].
  // Future<Service> getServiceFactoryAsyncT(
  //   Type type, {
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) async {
  //   return getServiceFactoryT(
  //     type,
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  // }
}
