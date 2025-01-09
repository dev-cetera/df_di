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

base mixin SupportsServicesMixin on SupportsConstructorsMixin, SupportsMixinT {
  /// Registers a dependency of type [TService] under the specified
  /// [groupEntity] in the [registry]  and calls [Service.init] with the
  /// provided [params].
  ///
  /// You can provide a [validator] function to validate the dependency before
  /// it gets retrieved. If the validation fails [DependencyInvalidException]
  /// will be throw upon retrieval.
  ///
  /// Additionally, an [onUnregister] callback can be specified to execute when
  /// the dependency is unregistered via [unregister].
  ///
  /// Throws a [DependencyAlreadyRegisteredException] if a dependency of the
  /// same type and group is already registered.
  // FutureOr<TService> registerService<TService extends Service>(
  //   FutureOr<TService> service, {
  //   Object? params,
  //   Entity? groupEntity,
  //   bool Function(FutureOr<TService> instance)? validator,
  //   FutureOr<void> Function(FutureOr<TService> instance)? onUnregister,
  // }) {
  //   return consec(
  //     register<TService>(
  //       consec(
  //         service,
  //         (e) => consec(
  //           e.init(params),
  //           (_) => service,
  //         ),
  //       ),
  //       groupEntity: groupEntity,
  //       validator: validator,
  //       onUnregister: (e) => consec(
  //         e,
  //         (service) => consec(
  //           onUnregister?.call(service),
  //           (_) => service.dispose(),
  //         ),
  //       ),
  //     ),
  //     (_) => getOrNull<TService>(
  //       groupEntity: groupEntity,
  //     )!,
  //   );
  // }

  // /// Registers a [Lazy] dependency of type [TService] under the specified
  // /// [groupEntity] in the [registry].
  // ///
  // /// This allows the service to be retrieved with [getServiceSingleton] or
  // /// [getServiceFactory].
  // ///
  // /// You can provide a [validator] function to validate the dependency before
  // /// it gets retrieved. If the validation fails [DependencyInvalidException]
  // /// will be throw upon retrieval.
  // ///
  // /// Additionally, an [onUnregister] callback can be specified to execute when
  // /// the dependency is unregistered via [unregister].
  // void registerLazyService<TService extends Service>(
  //   TConstructor<TService> constructor, {
  //   Entity? groupEntity,
  //   bool Function(FutureOr<TService> instance)? validator,
  //   FutureOr<void> Function(FutureOr<TService> instance)? onUnregister,
  // }) {
  //   registerLazy<TService>(
  //     constructor,
  //     groupEntity: groupEntity,
  //     validator: validator,
  //     onUnregister: (e) {
  //       return consec(
  //         e,
  //         (service) {
  //           return consec(
  //             onUnregister?.call(service),
  //             (_) {
  //               return service.dispose();
  //             },
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  // /// Retrieves an instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
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
  // FutureOr<TService> getServiceSingleton<TService extends Service>({
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   final groupEntity1 = groupEntity ?? focusGroup;
  //   final value = getServiceSingletonOrNull<TService>(
  //     params: params,
  //     groupEntity: groupEntity1,
  //     traverse: traverse,
  //   );

  //   if (value == null) {
  //     throw DependencyNotFoundException(
  //       type: TService,
  //       groupEntity: groupEntity1,
  //     );
  //   }
  //   return value;
  // }

  // /// Retrieves an instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
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
  // FutureOr<TService>? getServiceSingletonOrNull<TService extends Service>({
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   return getServiceSingletonWithParamsOrNull<TService, Object?>(
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  // }

  // /// Retrieves an instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
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
  // FutureOr<TService>
  //     getServiceSingletonWithParams<TService extends Service<TParams>, TParams extends Object?>({
  //   required TParams params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   final groupEntity1 = groupEntity ?? focusGroup;
  //   final value = getServiceSingletonWithParamsOrNull<TService, TParams>(
  //     params: params,
  //     groupEntity: groupEntity1,
  //     traverse: traverse,
  //   );

  //   if (value == null) {
  //     throw DependencyNotFoundException(
  //       type: TService,
  //       groupEntity: groupEntity1,
  //     );
  //   }
  //   return value;
  // }

  // /// Retrieves an instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
  // ///
  // /// If no instance is cached, a new one is created using the [Lazy]
  // /// constructor provided during registration.
  // ///
  // /// Calls [Service.init] with the provided [params] on first
  // /// retrieval.
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// Throws a [DependencyNotFoundException] if the dependency does not exist.
  // ///
  // /// Returns `null` if the dependency does not exist.
  // FutureOr<TService>? getServiceSingletonWithParamsOrNull<TService extends Service<TParams>,
  //     TParams extends Object?>({
  //   required TParams params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   final instance = getSingletonOrNull<TService>();
  //   return instance?.thenOr(
  //     (e) => e.initialized ? e : consec(e.init(params), (_) => e),
  //   );
  // }

  // /// Retrieves an instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
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
  // TService getServiceSingletonSync<TService extends Service>({
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   final value = getServiceSingleton<TService>(
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  //   if (value is Future) {
  //     throw DependencyIsFutureException(
  //       type: TService,
  //       groupEntity: groupEntity,
  //     );
  //   }
  //   return value;
  // }

  // /// Retrieves an instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
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
  // TService? getServiceSingletonSyncOrNull<TService extends Service>({
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  //   bool throwIfAsync = false,
  // }) {
  //   final value = getServiceSingletonOrNull<TService>(
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  //   if (throwIfAsync && value is Future) {
  //     throw DependencyIsFutureException(
  //       type: TService,
  //       groupEntity: groupEntity,
  //     );
  //   }
  //   return value?.asSyncOrNull;
  // }

  // /// Retrieves an instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
  // ///
  // /// Calls [Service.init] with the provided [params] on first retrieval.
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// Throws a [DependencyNotFoundException] if the dependency does not exist.
  // ///
  // /// Throws a [DependencyIsFutureException] if the dependency is a [Future].
  // TService getServiceSingletonWithParamsSync<TService extends Service<TParams>,
  //     TParams extends Object?>({
  //   required TParams params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   final value = getServiceSingletonWithParams<TService, TParams>(
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  //   if (value is Future) {
  //     throw DependencyIsFutureException(
  //       type: TService,
  //       groupEntity: groupEntity,
  //     );
  //   }
  //   return value;
  // }

  // /// Retrieves an instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
  // ///
  // /// Calls [Service.init] with the provided [params] on first retrieval.
  // ///
  // /// Throws a [DependencyIsFutureException] if the dependency is a [Future].
  // ///
  // /// Throws a [DependencyIsFutureException] if the dependency is a [Future]
  // /// and [throwIfAsync] is true, otherwise returns `null` if the dependency
  // /// is a [Future].
  // TService? getServiceSingletonWithParamsSyncOrNull<TService extends Service<TParams>,
  //     TParams extends Object?>({
  //   required TParams params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  //   bool throwIfAsync = false,
  // }) {
  //   final value = getServiceSingletonWithParamsOrNull<TService, TParams>(
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  //   if (throwIfAsync && value is Future) {
  //     throw DependencyIsFutureException(
  //       type: TService,
  //       groupEntity: groupEntity,
  //     );
  //   }
  //   return value?.asSyncOrNull;
  // }

  // /// Retrieves an instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
  // ///
  // /// Calls [Service.init] with the provided [params] on first retrieval.
  // ///
  // /// Throws a [DependencyNotFoundException] if the dependency does not exist.
  // ///
  // /// This method always returns a [Future], ensuring compatibility. This
  // /// provides a safe and consistent way to retrieve dependencies, even if the
  // /// registered dependency is not a [Future].
  // Future<TService> getServiceSingletonAsync<TService extends Service>({
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) async {
  //   return getServiceSingleton<TService>(
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  // }

  // /// Retrieves an instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
  // ///
  // /// Calls [Service.init] with the provided [params] on first retrieval.
  // ///
  // /// Throws a [DependencyNotFoundException] if the dependency does not exist.
  // ///
  // /// This method always returns a [Future], ensuring compatibility. This
  // /// provides a safe and consistent way to retrieve dependencies, even if the
  // /// registered dependency is not a [Future].
  // Future<TService> getServiceSingletonWithParamsAsync<TService extends Service<TParams>,
  //     TParams extends Object?>({
  //   required TParams params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) async {
  //   return getServiceSingletonWithParams<TService, TParams>(
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  // }

  // /// Retrieves a new instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
  // ///
  // /// The instance is created using the [Lazy] constructor provided during
  // /// the registration of the factory dependency, then calls [Service.init]
  // /// with the provided [params].
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// Throws a [DependencyNotFoundException] if the dependency does not exist.
  // FutureOr<TService> getServiceFactory<TService extends Service>({
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   final groupEntity1 = groupEntity ?? focusGroup;
  //   final value = getServiceFactoryOrNull<TService>(
  //     params: params,
  //     groupEntity: groupEntity1,
  //     traverse: traverse,
  //   );

  //   if (value == null) {
  //     throw DependencyNotFoundException(
  //       type: TService,
  //       groupEntity: groupEntity1,
  //     );
  //   }
  //   return value;
  // }

  // /// Retrieves a new instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
  // ///
  // /// The instance is created using the [Lazy] constructor provided during
  // /// the registration of the factory dependency, then calls [Service.init]
  // /// with the provided [params].
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// Returns `null` if the dependency does not exist.
  // FutureOr<TService>? getServiceFactoryOrNull<TService extends Service>({
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   return getServiceFactoryWithParamsOrNull<TService, Object?>(
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  // }

  // /// Retrieves a new instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
  // ///
  // /// The instance is created using the [Lazy] constructor provided during
  // /// the registration of the factory dependency, then calls [Service.init]
  // /// with the provided [params].
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// Throws a [DependencyNotFoundException] if the dependency does not exist.
  // FutureOr<TService>
  //     getServiceFactoryWithParams<TService extends Service<TParams>, TParams extends Object?>({
  //   required TParams params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   final groupEntity1 = groupEntity ?? focusGroup;
  //   final value = getServiceFactoryWithParamsOrNull<TService, TParams>(
  //     params: params,
  //     groupEntity: groupEntity1,
  //     traverse: traverse,
  //   );
  //   if (value == null) {
  //     throw DependencyNotFoundException(
  //       type: TService,
  //       groupEntity: groupEntity1,
  //     );
  //   }
  //   return value;
  // }

  // /// Retrieves a new instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
  // ///
  // /// The instance is created using the [Lazy] constructor provided during
  // /// the registration of the factory dependency, then calls [Service.init]
  // /// with the provided [params].
  // ///
  // /// If [traverse] is true, it will also search recursively in parent
  // /// containers.
  // ///
  // /// Returns `null` if the dependency does not exist.
  // FutureOr<TService>? getServiceFactoryWithParamsOrNull<TService extends Service<TParams>,
  //     TParams extends Object?>({
  //   required TParams params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   final instance = getFactoryOrNull<TService>();
  //   return instance?.thenOr(
  //     (e) => e.initialized ? e : consec(e.init(params), (_) => e),
  //   );
  // }

  // /// Retrieves a new instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
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
  // TService getServiceFactorySync<TService extends Service>({
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   final value = getServiceFactory<TService>(
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  //   if (value is Future) {
  //     throw DependencyIsFutureException(
  //       type: TService,
  //       groupEntity: groupEntity,
  //     );
  //   }
  //   return value;
  // }

  // /// Retrieves a new instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
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
  // TService? getServiceFactorySyncOrNull<TService extends Service>({
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  //   bool throwIfAsync = false,
  // }) {
  //   final value = getServiceFactoryOrNull<TService>(
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  //   if (throwIfAsync && value is Future) {
  //     throw DependencyIsFutureException(
  //       type: TService,
  //       groupEntity: groupEntity,
  //     );
  //   }
  //   return value?.asSyncOrNull;
  // }

  // /// Retrieves a new instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
  // ///
  // /// The instance is created using the [Lazy] constructor provided during
  // /// the registration of the factory dependency, then calls [Service.init]
  // /// with the provided [params].
  // ///
  // /// Throws a [DependencyNotFoundException] if the dependency does not exist.
  // ///
  // /// Throws a [DependencyIsFutureException] if the dependency is a [Future].
  // TService
  //     getServiceFactoryWithParamsSync<TService extends Service<TParams>, TParams extends Object?>({
  //   required TParams params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) {
  //   final value = getServiceFactoryWithParams<TService, TParams>(
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  //   if (value is Future) {
  //     throw DependencyIsFutureException(
  //       type: TService,
  //       groupEntity: groupEntity,
  //     );
  //   }
  //   return value;
  // }

  // /// Retrieves a new instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
  // ///
  // /// The instance is created using the [Lazy] constructor provided during
  // /// the registration of the factory dependency, then calls [Service.init]
  // /// with the provided [params].
  // ///
  // /// Throws a [DependencyIsFutureException] if the dependency is a [Future].
  // ///
  // /// Throws a [DependencyIsFutureException] if the dependency is a [Future]
  // /// and [throwIfAsync] is true, otherwise returns `null` if the dependency
  // /// is a [Future].
  // TService? getServiceFactoryWithParamsSyncOrNull<TService extends Service<TParams>,
  //     TParams extends Object?>({
  //   required TParams params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  //   bool throwIfAsync = false,
  // }) {
  //   final value = getServiceFactoryWithParamsOrNull<TService, TParams>(
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  //   if (throwIfAsync && value is Future) {
  //     throw DependencyIsFutureException(
  //       type: TService,
  //       groupEntity: groupEntity,
  //     );
  //   }
  //   return value?.asSyncOrNull;
  // }

  // /// Retrieves an instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
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
  // Future<TService> getServiceFactoryAsync<TService extends Service>({
  //   Object? params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) async {
  //   return getServiceFactory<TService>(
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  // }

  // /// Retrieves an instance of type [TService] or its subtypes under the
  // /// specified [groupEntity] from the [registry].
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
  // Future<TService>
  //     getServiceFactoryWithParamsAsync<TService extends Service<TParams>, TParams extends Object?>({
  //   required TParams params,
  //   Entity? groupEntity,
  //   bool traverse = true,
  // }) async {
  //   return getServiceFactoryWithParams<TService, TParams>(
  //     params: params,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  // }
}
