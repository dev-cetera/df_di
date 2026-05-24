//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A mixin that provides methods for working with constructors of dependencies,
/// using `Entity` for type resolution.
base mixin SupportsConstructorsMixinK on SupportsMixinK {
  /// Retrieves the lazily loaded singleton dependency.
  @protected
  @pragma('vm:prefer-inline')
  Resolvable<Option> unregisterLazyK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    bool removeAll = true,
    bool triggerOnUnregisterCallbacks = true,
  }) {
    return unregisterK(
      TypeEntity(Lazy, [typeEntity]),
      groupEntity: groupEntity,
      traverse: traverse,
      removeAll: removeAll,
      triggerOnUnregisterCallbacks: triggerOnUnregisterCallbacks,
    );
  }

  /// Retrieves the lazily loaded dependency.
  @protected
  @pragma('vm:prefer-inline')
  Option<Resolvable<Lazy<T>>> getLazyK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getK<Lazy<T>>(
      TypeEntity(Lazy, [typeEntity]),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Retrieves the lazily loaded dependency.
  @protected
  @pragma('vm:prefer-inline')
  Option<Lazy<T>> getLazySyncOrNoneK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getSyncOrNoneK<Lazy<T>>(
      TypeEntity(Lazy, [typeEntity]),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Retrieves the lazily loaded dependency, returning the instance directly or
  /// throwing an error if not found.
  @protected
  @pragma('vm:prefer-inline')
  FutureOr<Lazy<T>> getLazyUnsafeK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    UNSAFE:
    return getLazyK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.unwrap()).unwrap();
  }

  /// You must register dependencies via [register] and set its parameter
  /// `enableUntilExactlyK` to true to use this method.
  @protected
  @pragma('vm:prefer-inline')
  Resolvable<Lazy<T>> untilLazyExactlyK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilExactlyK<Lazy<T>>(
      TypeEntity(Lazy, [typeEntity]),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Resets the singleton instance of a lazily loaded dependency.
  @protected
  Resolvable<Unit> resetLazySingletonK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    return switch (
        getK<T>(TypeEntity(Lazy, [typeEntity]), groupEntity: groupEntity)) {
      Some(value: final r) => r.then((e) {
          (e as Lazy).resetSingleton();
          return Unit();
        }),
      None() => syncUnit(),
    };
  }

  /// Retrieves the lazily loaded singleton dependency.
  @protected
  Option<Resolvable<T>> getLazySingletonK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return switch (getLazyK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    )) {
      Some(value: Sync(value: Ok(value: final lazy))) => Some(lazy.singleton),
      _ => const None(),
    };
  }

  /// Retrieves the lazily loaded singleton dependency unsafely, returning the
  /// instance as an [Option].
  Option<T> getLazySingletonSyncOrNoneK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getLazySyncOrNoneK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => switch (e.singleton) {
          Sync(value: Ok(value: final v)) => Some(v),
          _ => None<T>(),
        },).flatten();
  }

  /// Retrieves the lazily loaded singleton dependency unsafely, returning the
  /// instance directly or throwing an error if not found or not a singleton.
  @protected
  @pragma('vm:prefer-inline')
  FutureOr<T> getLazySingletonUnsafeK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    UNSAFE:
    return getLazySingletonK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().unwrap();
  }

  /// Waits until a dependency of type `TSuper` is registered. `TSuper` should
  /// typically be the most general type expected.
  @protected
  @pragma('vm:prefer-inline')
  Resolvable<T> untilLazySingletonExactlyK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilLazyExactlyK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).then((e) => e.singleton).flatten();
  }

  /// Retrieves the factory dependency.
  @protected
  Option<Resolvable<T>> getFactoryK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return switch (getLazyK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    )) {
      Some(value: Sync(value: Ok(value: final lazy))) => Some(lazy.factory),
      _ => const None(),
    };
  }

  /// Retrieves the lazily loaded factory dependency unsafely, returning the
  /// instance as an [Option].
  Option<T> getLazyFactorySyncOrNoneK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getLazySyncOrNoneK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => switch (e.singleton) {
          Sync(value: Ok(value: final v)) => Some(v),
          _ => None<T>(),
        },).flatten();
  }

  /// Retrieves the factory dependency, returning the instance directly or
  /// throwing an error if not found.
  @protected
  @pragma('vm:prefer-inline')
  FutureOr<T> getFactoryUnsafeK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    UNSAFE:
    return getFactoryK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().unwrap();
  }

  /// Waits until a dependency of type `TSuper` is registered. `TSuper` should
  /// typically be the most general type expected.
  @pragma('vm:prefer-inline')
  Resolvable<T> untilFactoryExactlyK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilLazyExactlyK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).then((e) => e.factory).flatten();
  }
}
