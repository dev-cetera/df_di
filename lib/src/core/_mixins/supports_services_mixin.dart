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

base mixin SupportsServicesMixin
    on SupportsConstructorsMixin, SupportsRuntimeTypeMixin {
  FutureOr<T> registerService<T extends Service>(
    FutureOr<T> service, {
    Object? params,
    DIKey? groupKey,
    bool Function(FutureOr<T> instance)? validator,
    FutureOr<void> Function(FutureOr<T> instance)? onUnregister,
  }) {
    final initializedService = mapSyncOrAsync(
      service,
      (e) => mapSyncOrAsync(
        e.initialized ? null : e.initService(params),
        (_) => service,
      ),
    );
    return register<T>(
      initializedService,
      onUnregister: (e) {
        return mapSyncOrAsync(
          e,
          (service) {
            return mapSyncOrAsync(
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

  void registerLazyService<T extends Service>(
    TConstructor<T> constructor, {
    DIKey? groupKey,
    bool Function(FutureOr<T> instance)? validator,
    FutureOr<void> Function(FutureOr<T> instance)? onUnregister,
  }) {
    registerLazy<T>(
      constructor,
      groupKey: groupKey,
      validator: validator,
      onUnregister: (e) {
        return mapSyncOrAsync(
          e,
          (service) {
            return mapSyncOrAsync(
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

  FutureOr<Service> getServiceSingletonT(
    Type type, {
    Object? params,
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final value = getServiceSingletonOrNullT(
      type,
      params: params,
      groupKey: groupKey,
      traverse: traverse,
    );

    if (value == null) {
      throw DependencyNotFoundException(
        type: type,
        groupKey: groupKey,
      );
    }
    return value;
  }

  FutureOr<T> getServiceSingleton<T extends Service>({
    Object? params,
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final value = getServiceSingletonOrNull<T>(
      params: params,
      groupKey: groupKey,
      traverse: traverse,
    );

    if (value == null) {
      throw DependencyNotFoundException(
        type: T,
        groupKey: groupKey,
      );
    }
    return value;
  }

  FutureOr<T>? getServiceSingletonOrNull<T extends Service>({
    Object? params,
    DIKey? groupKey,
    bool traverse = true,
  }) {
    return getServiceSingletonWithParamsOrNull<T, Object?>(
      params: params,
      groupKey: groupKey,
      traverse: traverse,
    );
  }

  FutureOr<T>
      getServiceSingletonWithParams<T extends Service<P>, P extends Object?>({
    P? params,
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final value = getServiceSingletonWithParamsOrNull<T, P>(
      params: params,
      groupKey: groupKey,
      traverse: traverse,
    );

    if (value == null) {
      throw DependencyNotFoundException(
        type: T,
        groupKey: groupKey,
      );
    }
    return value;
  }

  FutureOr<Service>? getServiceSingletonOrNullT(
    Type type, {
    Object? params,
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final instance = getSingletonOrNullT(type);
    return instance?.thenOr((e) {
      e as Service;
      return e.initialized
          ? e
          : mapSyncOrAsync(e.initService(params), (_) => e);
    });
  }

  FutureOr<T>? getServiceSingletonWithParamsOrNull<T extends Service<P>,
      P extends Object?>({
    P? params,
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final instance = getSingletonOrNull<T>();
    return instance?.thenOr(
      (e) =>
          e.initialized ? e : mapSyncOrAsync(e.initService(params), (_) => e),
    );
  }

  FutureOr<Service> getServiceFactoryT(
    Type type, {
    Object? params,
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final value = getServiceFactoryOrNullT(
      type,
      params: params,
      groupKey: groupKey,
      traverse: traverse,
    );

    if (value == null) {
      throw DependencyNotFoundException(
        type: type,
        groupKey: groupKey,
      );
    }
    return value;
  }

  FutureOr<T> getServiceFactory<T extends Service>({
    Object? params,
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final value = getServiceFactoryOrNull<T>(
      params: params,
      groupKey: groupKey,
      traverse: traverse,
    );

    if (value == null) {
      throw DependencyNotFoundException(
        type: T,
        groupKey: groupKey,
      );
    }
    return value;
  }

  FutureOr<T>? getServiceFactoryOrNull<T extends Service>({
    Object? params,
    DIKey? groupKey,
    bool traverse = true,
  }) {
    return getServiceFactoryWithParamsOrNull<T, Object?>(
      params: params,
      groupKey: groupKey,
      traverse: traverse,
    );
  }

  FutureOr<T>
      getServiceFactoryWithParams<T extends Service<P>, P extends Object?>({
    P? params,
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final value = getServiceFactoryWithParamsOrNull<T, P>(
      params: params,
      groupKey: groupKey,
      traverse: traverse,
    );

    if (value == null) {
      throw DependencyNotFoundException(
        type: T,
        groupKey: groupKey,
      );
    }
    return value;
  }

  FutureOr<Service>? getServiceFactoryOrNullT(
    Type type, {
    Object? params,
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final instance = getFactoryOrNullT(type);
    return instance?.thenOr((e) {
      e as Service;
      return e.initialized
          ? e
          : mapSyncOrAsync(e.initService(params), (_) => e);
    });
  }

  FutureOr<T>? getServiceFactoryWithParamsOrNull<T extends Service<P>,
      P extends Object?>({
    P? params,
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final instance = getFactoryOrNull<T>();
    return instance?.thenOr(
      (e) =>
          e.initialized ? e : mapSyncOrAsync(e.initService(params), (_) => e),
    );
  }
}
