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

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A mixin that provides methods for working with constructors of dependencies,
/// using generic types for type resolution.
base mixin SupportsConstructorsMixin on DIBase {
  /// Registers a lazy dependency.
  @pragma('vm:prefer-inline')
  Resolvable<Lazy<T>> registerLazy<T extends Object>(
    LazyConstructor<T> constructor, {
    FutureOr<void> Function(Lazy<T> lazy)? onRegister,
    TOnUnregisterCallback<Lazy<T>>? onUnregister,
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
    FutureOr<T> Function() constructor, {
    FutureOr<void> Function(Lazy<T> lazy)? onRegister,
    TOnUnregisterCallback<Lazy<T>>? onUnregister,
    Entity groupEntity = const DefaultEntity(),
  }) {
    return registerLazy<T>(
      () => Resolvable(constructor),
      onRegister: onRegister,
      onUnregister: onUnregister,
      groupEntity: groupEntity,
    );
  }

  /// Unregisters a lazily loaded dependency.
  @pragma('vm:prefer-inline')
  Resolvable<None<Object>> unregisterLazy<T extends Object>({
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
  Resolvable<None> resetLazySingleton<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final temp = getLazy<T>(groupEntity: groupEntity);
    if (temp.isSome()) {
      return temp.unwrap().map((e) {
        e.resetSingleton();
        return const None();
      });
    }
    return const Sync.value(Ok(None()));
  }

  /// Retrieves the lazily loaded singleton dependency.
  Option<Resolvable<T>> getLazySingleton<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final option = getLazy<T>(groupEntity: groupEntity, traverse: traverse);
    if (option.isNone()) {
      return const None();
    }
    final lazy = option.unwrap().sync().unwrap().unwrap();
    return Some(lazy.singleton);
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
    ).map((e) {
      final a = e.singleton;
      if (a.isAsync()) {
        return None<T>();
      }
      final b = a.sync().unwrap().value;
      if (b.isErr()) {
        return None<T>();
      }
      return Some(b.unwrap());
    }).flatten();
  }

  /// Retrieves the lazily loaded singleton dependency unsafely, returning the
  /// instance directly or throwing an error if not found or not a singleton.
  @pragma('vm:prefer-inline')
  FutureOr<T> getLazySingletonUnsafe<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
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
    ).map((e) => e.singleton).flatten();
  }

  /// Retrieves the factory dependency.
  Option<Resolvable<T>> getFactory<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final option = getLazy<T>(groupEntity: groupEntity, traverse: traverse);
    if (option.isNone()) {
      return const None();
    }
    final lazy = option.unwrap().sync().unwrap().unwrap();
    return Some(lazy.factory);
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
    ).map((e) {
      final a = e.factory;
      if (a.isAsync()) {
        return None<T>();
      }
      final b = a.sync().unwrap().value;
      if (b.isErr()) {
        return None<T>();
      }
      return Some(b.unwrap());
    }).flatten();
  }

  /// Retrieves the factory dependency unsafely, returning the instance directly
  /// or throwing an error if not found.
  @pragma('vm:prefer-inline')
  FutureOr<T> getFactoryUnsafe<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
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
    ).map((e) => e.factory).flatten();
  }
}
