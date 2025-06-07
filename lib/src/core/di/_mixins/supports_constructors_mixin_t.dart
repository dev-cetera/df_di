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

/// A mixin that provides methods for working with constructors of dependencies,
/// using `Type` for type resolution.
base mixin SupportsConstructorsMixinT on SupportsConstructorsMixinK {
  /// Unregisters a lazily loaded dependency.
  @pragma('vm:prefer-inline')
  Resolvable<None> unregisterLazyT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    bool removeAll = true,
    bool triggerOnUnregisterCallbacks = true,
  }) {
    return unregisterLazyK(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
      removeAll: removeAll,
      triggerOnUnregisterCallbacks: triggerOnUnregisterCallbacks,
    );
  }

  /// Retrieves the lazily loaded dependency.
  @pragma('vm:prefer-inline')
  Option<Resolvable<Lazy<T>>> getLazyT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getLazyK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Retrieves the lazily loaded dependency, returning the instance directly or
  /// throwing an error if not found or not a singleton.
  @protected
  @pragma('vm:prefer-inline')
  FutureOr<Lazy<T>> getLazyUnsafeT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getLazyUnsafeK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// You must register dependencies via [register] and set its parameter
  /// `enableUntilExactlyK` to true to use this method.
  @pragma('vm:prefer-inline')
  Resolvable<Lazy<T>> untilLazyExactlyT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilLazyExactlyK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Resets the singleton instance of a lazily loaded dependency.
  @pragma('vm:prefer-inline')
  Resolvable<None> resetLazySingletonT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    return resetLazySingletonK<T>(TypeEntity(type), groupEntity: groupEntity);
  }

  /// Retrieves the lazily loaded singleton dependency.
  @pragma('vm:prefer-inline')
  Option<Resolvable<T>> getLazySingletonT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getLazySingletonK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Retrieves the lazily loaded singleton dependency unsafely, returning the
  /// instance directly or throwing an error if not found or not a singleton.
  @pragma('vm:prefer-inline')
  FutureOr<Object> getLazySingletonUnsafeT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getLazySingletonUnsafeK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Waits until a dependency of type `TSuper` is registered. `TSuper` should
  /// typically be the most general type expected.
  @pragma('vm:prefer-inline')
  Resolvable<T> untilLazySingletonyExactlyT<T extends Object>(
    T type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilLazySingletonyExactlyK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Retrieves the factory dependency.
  @pragma('vm:prefer-inline')
  Option<Resolvable<T>> getFactoryT<T extends Object>(
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

  /// Retrieves the factory dependency unsafely, returning the instance directly
  /// or throwing an error if not found.
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

  /// Waits until a dependency of type `TSuper` is registered. `TSuper` should
  /// typically be the most general type expected.
  @pragma('vm:prefer-inline')
  Resolvable<T> untilFactoryExactlyT<T extends Object>(
    T type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilFactoryExactlyK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }
}
