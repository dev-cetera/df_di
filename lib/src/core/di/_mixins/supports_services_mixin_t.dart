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
  // --- Singleton ---

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

  // --- Factory ---

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
}
