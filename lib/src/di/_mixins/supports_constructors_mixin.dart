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
/// using generic types for type resolution.
base mixin SupportsConstructorsMixin on DIBase {
  /// Registers a lazy dependency.
  @pragma('vm:prefer-inline')
  Resolvable<Lazy<T>> registerLazy<T extends Object>(
    @sendable LazyConstructor<T> constructor, {
    Option<TOnRegisterCallback<Lazy<T>>> onRegister = const None(),
    Option<TOnUnregisterCallback<Lazy<T>>> onUnregister = const None(),
    Entity groupEntity = const DefaultEntity(),
  }) {
    return register<Lazy<T>>(
      Lazy<T>(constructor),
      onRegister: onRegister,
      onUnregister: onUnregister,
      groupEntity: groupEntity,
    );
  }

  /// Registers a lazy dependency.
  @pragma('vm:prefer-inline')
  Resolvable<Lazy<T>> registerConstructor<T extends Object>(
    @sendable FutureOr<T> Function() constructor, {
    Option<TOnRegisterCallback<Lazy<T>>> onRegister = const None(),
    Option<TOnUnregisterCallback<Lazy<T>>> onUnregister = const None(),
    Entity groupEntity = const DefaultEntity(),
  }) {
    // One-line adapter closure that only captures `constructor` (itself
    // `@sendable`). The analyzer cannot verify transitive sendability of
    // arbitrary closures, but the capture set here is provably sendable
    // when callers respect the `@sendable` requirement on `constructor`.
    return registerLazy<T>(
      // ignore: sendable
      () => Resolvable<T>(() => constructor()),
      onRegister: onRegister,
      onUnregister: onUnregister,
      groupEntity: groupEntity,
    );
  }

  /// Unregisters a lazily loaded dependency.
  @pragma('vm:prefer-inline')
  Resolvable<Option> unregisterLazy<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    bool removeAll = true,
    bool triggerOnUnregisterCallbacks = true,
  }) {
    return unregister<Lazy<T>>(
      groupEntity: groupEntity,
      traverse: traverse,
      removeAll: removeAll,
      triggerOnUnregisterCallbacks: triggerOnUnregisterCallbacks,
    );
  }

  /// Retrieves the lazily loaded dependency.
  @pragma('vm:prefer-inline')
  Option<Resolvable<Lazy<T>>> getLazy<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return get<Lazy<T>>(groupEntity: groupEntity, traverse: traverse);
  }

  /// Retrieves the lazily loaded dependency.
  @pragma('vm:prefer-inline')
  Option<Lazy<T>> getLazySyncOrNone<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getSyncOrNone<Lazy<T>>(groupEntity: groupEntity, traverse: traverse);
  }

  /// Retrieves the lazily loaded singleton dependency unsafely, returning the
  /// instance directly or throwing an error if not found or not a singleton.
  @pragma('vm:prefer-inline')
  FutureOr<Lazy<T>> getLazyUnsafe<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    UNSAFE:
    return getLazy<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.unwrap()).unwrap();
  }

  /// Waits until a dependency of type `TSuper` is registered. `TSuper` should
  /// typically be the most general type expected.
  @pragma('vm:prefer-inline')
  Resolvable<Lazy<TSuper>> untilLazySuper<TSuper extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilSuper<Lazy<TSuper>>(
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Waits until a dependency of type `TSuper` or its subtype `TSub` is
  /// registered. `TSuper` should typically be the most general type expected.
  @pragma('vm:prefer-inline')
  Resolvable<Lazy<TSub>> untilLazy<TSuper extends Object, TSub extends TSuper>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return until<Lazy<TSuper>, Lazy<TSub>>(
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Resets the singleton instance of a lazily loaded dependency.
  Resolvable<Unit> resetLazySingleton<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    return switch (getLazy<T>(groupEntity: groupEntity)) {
      Some(value: final r) => r.then((e) {
          e.resetSingleton();
          return Unit();
        }),
      None() => syncUnit(),
    };
  }

  /// Retrieves the lazily loaded singleton dependency.
  Option<Resolvable<T>> getLazySingleton<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return switch (getLazy<T>(groupEntity: groupEntity, traverse: traverse)) {
      Some(value: Sync(value: Ok(value: final lazy))) => Some(lazy.singleton),
      _ => const None(),
    };
  }

  /// Retrieves the lazily loaded singleton dependency unsafely, returning the
  /// instance as an [Option].
  Option<T> getLazySingletonSyncOrNone<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getLazySyncOrNone<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    )
        .map(
          (e) => switch (e.singleton) {
            Sync(value: Ok(value: final v)) => Some(v),
            _ => None<T>(),
          },
        )
        .flatten();
  }

  /// Retrieves the lazily loaded singleton dependency unsafely, returning the
  /// instance directly or throwing an error if not found or not a singleton.
  @pragma('vm:prefer-inline')
  FutureOr<T> getLazySingletonUnsafe<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    UNSAFE:
    return getLazySingleton<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.unwrap()).unwrap();
  }

  /// Waits until a dependency of type `TSuper` is registered. `TSuper` should
  /// typically be the most general type expected.
  @pragma('vm:prefer-inline')
  Resolvable<TSuper> untilLazySingletonSuper<TSuper extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilLazySingleton<TSuper, TSuper>(
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Waits until a dependency of type `TSuper` or its subtype `TSub` is
  /// registered. `TSuper` should typically be the most general type expected.
  @pragma('vm:prefer-inline')
  Resolvable<TSub>
      untilLazySingleton<TSuper extends Object, TSub extends TSuper>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilLazy<TSuper, TSub>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).then((e) => e.singleton).flatten();
  }

  /// Retrieves the factory dependency.
  Option<Resolvable<T>> getFactory<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return switch (getLazy<T>(groupEntity: groupEntity, traverse: traverse)) {
      Some(value: Sync(value: Ok(value: final lazy))) => Some(lazy.factory),
      _ => const None(),
    };
  }

  /// Retrieves the lazily loaded factory dependency unsafely, returning the
  /// instance as an [Option].
  Option<T> getFactorySyncOrNone<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getLazySyncOrNone<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    )
        .map(
          (e) => switch (e.factory) {
            Sync(value: Ok(value: final v)) => Some(v),
            _ => None<T>(),
          },
        )
        .flatten();
  }

  /// Retrieves the factory dependency unsafely, returning the instance directly
  /// or throwing an error if not found.
  @pragma('vm:prefer-inline')
  FutureOr<T> getFactoryUnsafe<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    UNSAFE:
    return getFactory<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.unwrap()).unwrap();
  }

  /// Waits until a dependency of type `TSuper` is registered. `TSuper` should
  /// typically be the most general type expected.
  @pragma('vm:prefer-inline')
  Resolvable<TSuper> untilFactorySuper<TSuper extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilFactory<TSuper, TSuper>(
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Waits until a dependency of type `TSuper` or its subtype `TSub` is
  /// registered. `TSuper` should typically be the most general type expected.
  @pragma('vm:prefer-inline')
  Resolvable<TSub> untilFactory<TSuper extends Object, TSub extends TSuper>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilLazy<TSuper, TSub>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).then((e) => e.factory).flatten();
  }
}
