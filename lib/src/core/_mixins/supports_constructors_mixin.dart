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

base mixin SupportsConstructorsMixin on SupportsRuntimeTypeMixin {
  void resetSingletonT(
    Type type, {
    DIKey? groupKey,
  }) {
    (getK(DIKey.type(Lazy, [type]), groupKey: groupKey) as Lazy).resetSingleton();
  }

  void resetSingleton<T extends Object>({
    DIKey? groupKey,
  }) {
    get<Lazy<T>>(groupKey: groupKey).asSync.resetSingleton();
  }

  Lazy<T> registerLazy<T extends Object>(
    TConstructor<T> constructor, {
    DIKey? groupKey,
    bool Function(FutureOr<T> instance)? validator,
    FutureOr<void> Function(FutureOr<T> instance)? onUnregister,
  }) {
    return register<Lazy<T>>(
      Lazy<T>(constructor),
      groupKey: groupKey,
      validator: validator != null
          ? (constructor) {
              final instance = constructor.asSync.currentInstance;
              return instance != null ? validator(instance) : true;
            }
          : null,
      onUnregister: onUnregister != null
          ? (constructor) {
              final instance = constructor.asSync.currentInstance;
              return instance != null ? onUnregister(instance) : null;
            }
          : null,
    ).asSync;
  }

  Future<Object> getSingletonAsyncT(
    Type type, {
    DIKey? groupKey,
    bool traverse = true,
  }) async {
    return getSingletonT(
      type,
      groupKey: groupKey,
      traverse: traverse,
    );
  }

  Object getSingletonSyncT(
    Type type, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final value = getSingletonT(
      type,
      groupKey: groupKey,
      traverse: traverse,
    );
    if (value is Future) {
      throw DependencyIsFutureException(
        type: type,
        groupKey: groupKey,
      );
    } else {
      return value;
    }
  }

  Object? getSingletonSyncOrNullT(
    Type type, {
    DIKey? groupKey,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getSingletonOrNullT(
      type,
      groupKey: groupKey,
      traverse: traverse,
    );
    if (throwIfAsync && value is Future) {
      throw DependencyIsFutureException(
        type: type,
        groupKey: groupKey,
      );
    }
    return value?.asSyncOrNull;
  }

  FutureOr<Object> getSingletonT(
    Type type, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final groupKey1 = groupKey ?? focusGroup;
    final value = getSingletonOrNullT(
      type,
      groupKey: groupKey1,
      traverse: traverse,
    );

    if (value == null) {
      throw DependencyNotFoundException(
        type: type,
        groupKey: groupKey1,
      );
    }
    return value;
  }

  FutureOr<Object>? getSingletonOrNullT(
    Type type, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    return (getOrNullK(
      DIKey.type(Lazy, [type]),
      groupKey: groupKey,
      traverse: traverse,
    ) as Lazy?)
        ?.singleton;
  }

  Future<T> getSingletonAsync<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) async {
    return getSingleton<T>(
      groupKey: groupKey,
      traverse: traverse,
    );
  }

  T getSingletonSync<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final value = getSingleton<T>(
      groupKey: groupKey,
      traverse: traverse,
    );
    if (value is Future) {
      throw DependencyIsFutureException(
        type: T,
        groupKey: groupKey,
      );
    } else {
      return value;
    }
  }

  T? getSingletonSyncOrNull<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getSingletonOrNull<T>(
      groupKey: groupKey,
      traverse: traverse,
    );
    if (throwIfAsync && value is Future) {
      throw DependencyIsFutureException(
        type: T,
        groupKey: groupKey,
      );
    }
    return value?.asSyncOrNull;
  }

  FutureOr<T> getSingleton<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final groupKey1 = groupKey ?? focusGroup;
    final value = getSingletonOrNull<T>(
      groupKey: groupKey1,
      traverse: traverse,
    );

    if (value == null) {
      throw DependencyNotFoundException(
        type: T,
        groupKey: groupKey1,
      );
    }
    return value;
  }

  FutureOr<T>? getSingletonOrNull<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    return getOrNull<Lazy<T>>(
      groupKey: groupKey,
      traverse: traverse,
    )?.asSyncOrNull?.singleton;
  }

  Future<Object> getFactoryAsyncT(
    Type type, {
    DIKey? groupKey,
    bool traverse = true,
  }) async {
    return getFactoryT(
      type,
      groupKey: groupKey,
      traverse: traverse,
    );
  }

  Object getFactorySyncT(
    Type type, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final value = getFactoryT(
      type,
      groupKey: groupKey,
      traverse: traverse,
    );
    if (value is Future) {
      throw DependencyIsFutureException(
        type: type,
        groupKey: groupKey,
      );
    } else {
      return value;
    }
  }

  Object? getFactorySyncOrNullT(
    Type type, {
    DIKey? groupKey,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getFactoryOrNullT(
      type,
      groupKey: groupKey,
      traverse: traverse,
    );
    if (throwIfAsync && value is Future) {
      throw DependencyIsFutureException(
        type: type,
        groupKey: groupKey,
      );
    }
    return value?.asSyncOrNull;
  }

  FutureOr<Object> getFactoryT(
    Type type, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final groupKey1 = groupKey ?? focusGroup;
    final value = getFactoryOrNullT(
      type,
      groupKey: groupKey1,
      traverse: traverse,
    );
    if (value == null) {
      throw DependencyNotFoundException(
        type: type,
        groupKey: groupKey1,
      );
    }
    return value;
  }

  FutureOr<Object>? getFactoryOrNullT(
    Type type, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    return (getOrNullK(
      DIKey.type(Lazy, [type]),
      groupKey: groupKey,
      traverse: traverse,
    ) as Lazy?)
        ?.factory;
  }

  Future<T> getFactoryAsync<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) async {
    return getFactory<T>(
      groupKey: groupKey,
      traverse: traverse,
    );
  }

  T getFactorySync<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final value = getFactory<T>(
      groupKey: groupKey,
      traverse: traverse,
    );
    if (value is Future) {
      throw DependencyIsFutureException(
        type: T,
        groupKey: groupKey,
      );
    } else {
      return value;
    }
  }

  T? getFactorySyncOrNull<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getFactoryOrNull<T>(
      groupKey: groupKey,
      traverse: traverse,
    );
    if (throwIfAsync && value is Future) {
      throw DependencyIsFutureException(
        type: T,
        groupKey: groupKey,
      );
    }
    return value?.asSyncOrNull;
  }

  FutureOr<T> getFactory<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final groupKey1 = groupKey ?? focusGroup;
    final value = getFactoryOrNull<T>(
      groupKey: groupKey1,
      traverse: traverse,
    );

    if (value == null) {
      throw DependencyNotFoundException(
        type: T,
        groupKey: groupKey1,
      );
    }
    return value;
  }

  FutureOr<T>? getFactoryOrNull<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    return getOrNull<Lazy<T>>(
      groupKey: groupKey,
      traverse: traverse,
    )?.asSyncOrNull?.factory;
  }
}
