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
    Entity? groupEntity,
  }) {
    (getK(Entity.type(Lazy, [type]), groupEntity: groupEntity) as Lazy)
        .resetSingleton();
  }

  void resetSingleton<T extends Object>({
    Entity? groupEntity,
  }) {
    get<Lazy<T>>(groupEntity: groupEntity).asSync.resetSingleton();
  }

  Lazy<T> registerLazy<T extends Object>(
    TConstructor<T> constructor, {
    Entity? groupEntity,
    bool Function(FutureOr<T> instance)? validator,
    FutureOr<void> Function(FutureOr<T> instance)? onUnregister,
  }) {
    return register<Lazy<T>>(
      Lazy<T>(constructor),
      groupEntity: groupEntity,
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
    Entity? groupEntity,
    bool traverse = true,
  }) async {
    return getSingletonT(
      type,
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

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

  FutureOr<Object>? getSingletonOrNullT(
    Type type, {
    Entity? groupEntity,
    bool traverse = true,
  }) {
    return (getOrNullK(
      Entity.type(Lazy, [type]),
      groupEntity: groupEntity,
      traverse: traverse,
    ) as Lazy?)
        ?.singleton;
  }

  Future<T> getSingletonAsync<T extends Object>({
    Entity? groupEntity,
    bool traverse = true,
  }) async {
    return getSingleton<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  T getSingletonSync<T extends Object>({
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final value = getSingleton<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (value is Future) {
      throw DependencyIsFutureException(
        type: T,
        groupEntity: groupEntity,
      );
    } else {
      return value;
    }
  }

  T? getSingletonSyncOrNull<T extends Object>({
    Entity? groupEntity,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getSingletonOrNull<T>(
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

  FutureOr<T> getSingleton<T extends Object>({
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final groupEntity1 = groupEntity ?? focusGroup;
    final value = getSingletonOrNull<T>(
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

  FutureOr<T>? getSingletonOrNull<T extends Object>({
    Entity? groupEntity,
    bool traverse = true,
  }) {
    return getOrNull<Lazy<T>>(
      groupEntity: groupEntity,
      traverse: traverse,
    )?.asSyncOrNull?.singleton;
  }

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

  FutureOr<Object>? getFactoryOrNullT(
    Type type, {
    Entity? groupEntity,
    bool traverse = true,
  }) {
    return (getOrNullK(
      Entity.type(Lazy, [type]),
      groupEntity: groupEntity,
      traverse: traverse,
    ) as Lazy?)
        ?.factory;
  }

  Future<T> getFactoryAsync<T extends Object>({
    Entity? groupEntity,
    bool traverse = true,
  }) async {
    return getFactory<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  T getFactorySync<T extends Object>({
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final value = getFactory<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (value is Future) {
      throw DependencyIsFutureException(
        type: T,
        groupEntity: groupEntity,
      );
    } else {
      return value;
    }
  }

  T? getFactorySyncOrNull<T extends Object>({
    Entity? groupEntity,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getFactoryOrNull<T>(
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

  FutureOr<T> getFactory<T extends Object>({
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final groupEntity1 = groupEntity ?? focusGroup;
    final value = getFactoryOrNull<T>(
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

  FutureOr<T>? getFactoryOrNull<T extends Object>({
    Entity? groupEntity,
    bool traverse = true,
  }) {
    return getOrNull<Lazy<T>>(
      groupEntity: groupEntity,
      traverse: traverse,
    )?.asSyncOrNull?.factory;
  }
}
