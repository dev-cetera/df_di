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

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base mixin SupportsServicesMixin
    on SupportsConstructorsMixin, SupportsRuntimeTypeMixin {
  FutureOr<T> registerService<T extends Service>(
    FutureOr<T> service, {
    Object? params,
    Entity? groupEntity,
    bool Function(FutureOr<T> instance)? validator,
    FutureOr<void> Function(FutureOr<T> instance)? onUnregister,
  }) {
    return consec(
      register<T>(
        consec(
          service,
          (e) => consec(
            e.initialized ? null : e.init(params),
            (_) => service,
          ),
        ),
        groupEntity: groupEntity,
        validator: validator,
        onUnregister: (e) => consec(
          e,
          (service) => consec(
            onUnregister?.call(service),
            (_) => service.dispose(),
          ),
        ),
      ),
      (_) => getOrNull<T>(
        groupEntity: groupEntity,
      )!,
    );
  }

  void registerLazyService<T extends Service>(
    TConstructor<T> constructor, {
    Entity? groupEntity,
    bool Function(FutureOr<T> instance)? validator,
    FutureOr<void> Function(FutureOr<T> instance)? onUnregister,
  }) {
    registerLazy<T>(
      constructor,
      groupEntity: groupEntity,
      validator: validator,
      onUnregister: (e) {
        return consec(
          e,
          (service) {
            return consec(
              onUnregister?.call(service),
              (_) {
                return service.dispose();
              },
            );
          },
        );
      },
    );
  }

  // --- Singleton ---

  FutureOr<T> getServiceSingleton<T extends Service>({
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final groupEntity1 = groupEntity ?? focusGroup;
    final value = getServiceSingletonOrNull<T>(
      params: params,
      groupEntity: groupEntity1,
      traverse: traverse,
    );

    if (value == null) {
      throw DependencyNotFoundException(
        type: T,
        groupEntity: groupEntity1,
      );
    }
    return value;
  }

  FutureOr<Service> getServiceSingletonT(
    Type type, {
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final groupEntity1 = groupEntity ?? focusGroup;
    final value = getServiceSingletonOrNullT(
      type,
      params: params,
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

  FutureOr<T>
      getServiceSingletonWithParams<T extends Service<P>, P extends Object?>({
    required P params,
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final groupEntity1 = groupEntity ?? focusGroup;
    final value = getServiceSingletonWithParamsOrNull<T, P>(
      params: params,
      groupEntity: groupEntity1,
      traverse: traverse,
    );

    if (value == null) {
      throw DependencyNotFoundException(
        type: T,
        groupEntity: groupEntity1,
      );
    }
    return value;
  }

  Future<T> getServiceSingletonAsync<T extends Service>({
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
  }) async {
    return getServiceSingleton<T>(
      params: params,
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  T getServiceSingletonSync<T extends Service>({
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getServiceSingleton<T>(
      params: params,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (value is Future) {
      throw DependencyIsFutureException(
        type: T,
        groupEntity: groupEntity,
      );
    }
    return value;
  }

  T? getServiceSingletonSyncOrNull<T extends Service>({
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getServiceSingletonOrNull<T>(
      params: params,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (throwIfAsync && value is Future) {
      throw DependencyIsFutureException(
        type: T,
        groupEntity: groupEntity,
      );
    }
    return value?.asSyncOrNull;
  }

  FutureOr<T>? getServiceSingletonOrNull<T extends Service>({
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
  }) {
    return getServiceSingletonWithParamsOrNull<T, Object?>(
      params: params,
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  Future<Service> getServiceSingletonAsyncT(
    Type type, {
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
  }) async {
    return getServiceSingletonT(
      type,
      params: params,
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  Service getServiceSingletonSyncT(
    Type type, {
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getServiceSingletonT(
      type,
      params: params,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (value is Future) {
      throw DependencyIsFutureException(
        type: type,
        groupEntity: groupEntity,
      );
    }
    return value;
  }

  Service? getServiceSingletonSyncOrNullT(
    Type type, {
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getServiceSingletonOrNullT(
      type,
      params: params,
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

  FutureOr<Service>? getServiceSingletonOrNullT(
    Type type, {
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final instance = getSingletonOrNullT(type);
    return instance?.thenOr((e) {
      e as Service;
      return e.initialized ? e : consec(e.init(params), (_) => e);
    });
  }

  Future<T> getServiceSingletonWithParamsAsync<T extends Service<P>,
      P extends Object?>({
    required P params,
    Entity? groupEntity,
    bool traverse = true,
  }) async {
    return getServiceSingletonWithParams<T, P>(
      params: params,
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  T getServiceSingletonWithParamsSync<T extends Service<P>, P extends Object?>({
    required P params,
    Entity? groupEntity,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getServiceSingletonWithParams<T, P>(
      params: params,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (value is Future) {
      throw DependencyIsFutureException(
        type: T,
        groupEntity: groupEntity,
      );
    }
    return value;
  }

  T? getServiceSingletonWithParamsSyncOrNull<T extends Service<P>,
      P extends Object?>({
    required P params,
    Entity? groupEntity,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getServiceSingletonWithParamsOrNull<T, P>(
      params: params,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (throwIfAsync && value is Future) {
      throw DependencyIsFutureException(
        type: T,
        groupEntity: groupEntity,
      );
    }
    return value?.asSyncOrNull;
  }

  FutureOr<T>? getServiceSingletonWithParamsOrNull<T extends Service<P>,
      P extends Object?>({
    required P params,
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final instance = getSingletonOrNull<T>();
    return instance?.thenOr(
      (e) => e.initialized ? e : consec(e.init(params), (_) => e),
    );
  }

  // --- Factory ---

  FutureOr<T> getServiceFactory<T extends Service>({
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final groupEntity1 = groupEntity ?? focusGroup;
    final value = getServiceFactoryOrNull<T>(
      params: params,
      groupEntity: groupEntity1,
      traverse: traverse,
    );

    if (value == null) {
      throw DependencyNotFoundException(
        type: T,
        groupEntity: groupEntity1,
      );
    }
    return value;
  }

  FutureOr<Service> getServiceFactoryT(
    Type type, {
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final groupEntity1 = groupEntity ?? focusGroup;
    final value = getServiceFactoryOrNullT(
      type,
      params: params,
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

  FutureOr<T>
      getServiceFactoryWithParams<T extends Service<P>, P extends Object?>({
    required P params,
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final groupEntity1 = groupEntity ?? focusGroup;
    final value = getServiceFactoryWithParamsOrNull<T, P>(
      params: params,
      groupEntity: groupEntity1,
      traverse: traverse,
    );
    if (value == null) {
      throw DependencyNotFoundException(
        type: T,
        groupEntity: groupEntity1,
      );
    }
    return value;
  }

  Future<T> getServiceFactoryAsync<T extends Service>({
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
  }) async {
    return getServiceFactory<T>(
      params: params,
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  T getServiceFactorySync<T extends Service>({
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getServiceFactory<T>(
      params: params,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (value is Future) {
      throw DependencyIsFutureException(
        type: T,
        groupEntity: groupEntity,
      );
    }
    return value;
  }

  T? getServiceFactorySyncOrNull<T extends Service>({
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getServiceFactoryOrNull<T>(
      params: params,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (throwIfAsync && value is Future) {
      throw DependencyIsFutureException(
        type: T,
        groupEntity: groupEntity,
      );
    }
    return value?.asSyncOrNull;
  }

  FutureOr<T>? getServiceFactoryOrNull<T extends Service>({
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
  }) {
    return getServiceFactoryWithParamsOrNull<T, Object?>(
      params: params,
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  Future<Service> getServiceFactoryAsyncT(
    Type type, {
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
  }) async {
    return getServiceFactoryT(
      type,
      params: params,
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  Service getServiceFactorySyncT(
    Type type, {
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getServiceFactoryT(
      type,
      params: params,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (value is Future) {
      throw DependencyIsFutureException(
        type: type,
        groupEntity: groupEntity,
      );
    }
    return value;
  }

  Service? getServiceFactorySyncOrNullT(
    Type type, {
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getServiceFactoryOrNullT(
      type,
      params: params,
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

  FutureOr<Service>? getServiceFactoryOrNullT(
    Type type, {
    Object? params,
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final instance = getFactoryOrNullT(type);
    return instance?.thenOr((e) {
      e as Service;
      return e.initialized ? e : consec(e.init(params), (_) => e);
    });
  }

  Future<T> getServiceFactoryWithParamsAsync<T extends Service<P>,
      P extends Object?>({
    required P params,
    Entity? groupEntity,
    bool traverse = true,
  }) async {
    return getServiceFactoryWithParams<T, P>(
      params: params,
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  T getServiceFactoryWithParamsSync<T extends Service<P>, P extends Object?>({
    required P params,
    Entity? groupEntity,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getServiceFactoryWithParams<T, P>(
      params: params,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (value is Future) {
      throw DependencyIsFutureException(
        type: T,
        groupEntity: groupEntity,
      );
    }
    return value;
  }

  T? getServiceFactoryWithParamsSyncOrNull<T extends Service<P>,
      P extends Object?>({
    required P params,
    Entity? groupEntity,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getServiceFactoryWithParamsOrNull<T, P>(
      params: params,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (throwIfAsync && value is Future) {
      throw DependencyIsFutureException(
        type: T,
        groupEntity: groupEntity,
      );
    }
    return value?.asSyncOrNull;
  }

  FutureOr<T>? getServiceFactoryWithParamsOrNull<T extends Service<P>,
      P extends Object?>({
    required P params,
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final instance = getFactoryOrNull<T>();
    return instance?.thenOr(
      (e) => e.initialized ? e : consec(e.init(params), (_) => e),
    );
  }
}
