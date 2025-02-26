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

base mixin SupportsConstructorsMixin on SupportsMixinT {
  //
  //
  //

  Resolvable<Lazy<T>> registerLazy<T extends Object>(
    LazyConstructor<T> constructor, {
    FutureOr<void> Function(Lazy<T> lazy)? onRegister,
    OnUnregisterCallback<Lazy<T>>? onUnregister,
    Entity groupEntity = const DefaultEntity(),
  }) {
    return register<Lazy<T>>(
      Lazy<T>(constructor),
      onRegister: onRegister,
      onUnregister: onUnregister,
      groupEntity: groupEntity,
    );
  }

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

  @pragma('vm:prefer-inline')
  Option<Resolvable<Lazy<T>>> getLazy<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return get<Lazy<T>>(groupEntity: groupEntity, traverse: traverse);
  }

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

  @pragma('vm:prefer-inline')
  Resolvable<Lazy<T>> untilLazy<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return until<Lazy<T>>(groupEntity: groupEntity, traverse: traverse);
  }

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

  @pragma('vm:prefer-inline')
  Resolvable<T> untilLazySingleton<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilLazy<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.singleton).merge();
  }

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
    return const Sync(Ok(None()));
  }

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

  @pragma('vm:prefer-inline')
  Resolvable<T> untilFactory<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilLazy<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.factory).merge();
  }
}
