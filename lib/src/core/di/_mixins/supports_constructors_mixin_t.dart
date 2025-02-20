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

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base mixin SupportsConstructorsMixinT on SupportsConstructorsMixinK {
  @pragma('vm:prefer-inline')
  Resolvable<void> resetSingletonT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    return resetSingletonK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
    );
  }

  @pragma('vm:prefer-inline')
  FutureOr<Object> getSingletonUnsafeT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getSingletonUnsafeK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  @pragma('vm:prefer-inline')
  OptionResolvable getSingletonT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getSingletonK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  @pragma('vm:prefer-inline')
  FutureOr<T> getFactoryUnsafeT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getFactoryUnsafeK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  @pragma('vm:prefer-inline')
  OptionResolvable<T> getFactoryT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getFactoryK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  @pragma('vm:prefer-inline')
  Resolvable<T> untilT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    ).trans<T>();
  }
}
