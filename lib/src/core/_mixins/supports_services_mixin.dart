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

base mixin SupportsServicesMixin on SupportsConstructorsMixin {
  void registerService<T extends Service<Object>>(
    TConstructor<T> constructor, {
    DIKey? groupKey,
    bool Function(FutureOr<T> instance)? validator,
    FutureOr<void> Function(FutureOr<T> instance)? onUnregister,
  }) {
    registerConstructor<T>(
      constructor,
      groupKey: groupKey,
      validator: validator,
      onUnregister: (e) {
        return e.thenOr((e) => mapFutureOr(e.initializedFuture, (_) => e.dispose()));
      },
    );
  }

  FutureOr<T>? getServiceSingletonOrNull<T extends Service<Object>>({
    Object? params,
    DIKey? groupKey,
    bool traverse = true,
  }) {
    return getServiceSingletonWithParamsOrNull<T, Object>(
      params: params,
      groupKey: groupKey,
      traverse: traverse,
    );
  }

  FutureOr<T>? getServiceSingletonWithParamsOrNull<T extends Service<P>, P extends Object>({
    P? params,
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final singleton = getSingletonOrNull<T>();
    if (params != null) {
      return singleton
          ?.thenOr((e) => e.initialized ? mapFutureOr(e.initService(params), (_) => e) : e);
    } else {
      return singleton;
    }
  }

  FutureOr<T>? getServiceFactoryOrNull<T extends Service<Object>>({
    Object? params,
    DIKey? groupKey,
    bool traverse = true,
  }) {
    return getServiceFactoryWithParamsOrNull<T, Object>(
      params: params,
      groupKey: groupKey,
      traverse: traverse,
    );
  }

  FutureOr<T>? getServiceFactoryWithParamsOrNull<T extends Service<P>, P extends Object>({
    P? params,
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final singleton = getFactoryOrNull<T>();
    if (params != null) {
      return singleton
          ?.thenOr((e) => e.initialized ? mapFutureOr(e.initService(params), (_) => e) : e);
    } else {
      return singleton;
    }
  }
}
