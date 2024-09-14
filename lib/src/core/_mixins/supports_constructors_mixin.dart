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

base mixin SupportsConstructorsMixin on SupportsRuntimeTypeMixin {
  void resetSingleton<T extends Object>({
    DIKey? groupKey,
  }) {
    get<Constructor<T>>(groupKey: groupKey).asValue.resetSingleton();
  }

  Constructor<T> registerConstructor<T extends Object>(
    TConstructor<T> constructor, {
    DIKey? groupKey,
    bool Function(FutureOr<T> instance)? validator,
    FutureOr<void> Function(FutureOr<T> instance)? onUnregister,
  }) {
    return register<Constructor<T>>(
      Constructor<T>(constructor),
      groupKey: groupKey,
      validator: validator != null
          ? (constructor) {
              final instance = constructor.asValue.currentInstance;
              return instance != null ? validator(instance) : true;
            }
          : null,
      onUnregister: onUnregister != null
          ? (constructor) {
              final instance = constructor.asValue.currentInstance;
              return instance != null ? onUnregister(instance) : true;
            }
          : null,
    ).asValue;
  }

  FutureOr<T> getSingleton<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final value = getSingletonOrNull<T>(
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

  FutureOr<T>? getSingletonOrNull<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    return getOrNull<Constructor<T>>(
      groupKey: groupKey,
      traverse: traverse,
    )?.asValue.singleton;
  }

  FutureOr<T> getFactory<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final value = getFactoryOrNull<T>(
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

  FutureOr<T>? getFactoryOrNull<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    return getOrNull<Constructor<T>>(
      groupKey: groupKey,
      traverse: traverse,
    )?.asValue.factory;
  }
}
