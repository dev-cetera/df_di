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

base mixin SupportsConstructorsMixinK on SupportsMixinK {
  @protected
  Resolvable<None> resetLazySingletonK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final temp = getK<T>(
      TypeEntity(Lazy, [typeEntity]),
      groupEntity: groupEntity,
    );
    if (temp.isSome()) {
      return temp.unwrap().map((e) => (e as Lazy).resetSingleton());
    }
    return const Sync(Ok(None()));
  }

  @protected
  @pragma('vm:prefer-inline')
  FutureOr<T> getLazySingletonUnsafeK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getLazySingletonK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().unwrap();
  }

  @pragma('vm:prefer-inline')
  FutureOr<Lazy<T>> getLazyUnsafeK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getK<Lazy<T>>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.unwrap()).unwrap();
  }

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

  @protected
  @pragma('vm:prefer-inline')
  Resolvable<None<Object>> unregisterLazyK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    bool removeAll = true,
    bool triggerOnUnregisterCallbacks = true,
  }) {
    return unregisterK<Lazy<T>>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
      removeAll: removeAll,
      triggerOnUnregisterCallbacks: triggerOnUnregisterCallbacks,
    );
  }

  @protected
  Option<Resolvable<T>> getLazySingletonK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final option = getLazyK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (option.isNone()) {
      return const None();
    }
    final lazy = option.unwrap().sync().unwrap().unwrap();
    return Some(lazy.singleton);
  }

  @protected
  @pragma('vm:prefer-inline')
  FutureOr<T> getFactoryUnsafeK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getFactoryK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().unwrap();
  }

  @protected
  Option<Resolvable<T>> getFactoryK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final option = getLazyK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (option.isNone()) {
      return const None();
    }
    final lazy = option.unwrap().sync().unwrap().unwrap();
    return Some(lazy.factory);
  }

  @protected
  @pragma('vm:prefer-inline')
  Resolvable<Lazy<T>> untilLazyK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilK<Lazy<T>>(
      TypeEntity(Lazy, [typeEntity]),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  @protected
  Resolvable<T> untilK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final test = getK<T>(typeEntity, groupEntity: g);
    if (test.isSome()) {
      return test.unwrap();
    }
    ReservedSafeFinisher<T> finisher;
    final option = getSyncOrNone<ReservedSafeFinisher<T>>(
      groupEntity: g,
      traverse: traverse,
    );
    if (option.isSome()) {
      finisher = option.unwrap();
    } else {
      finisher = ReservedSafeFinisher<T>(typeEntity);
      register<ReservedSafeFinisher<T>>(finisher, groupEntity: g);
    }
    return finisher.resolvable().map((e) {
      unregisterK(
        TypeEntity(ReservedSafeFinisher, [typeEntity]),
        groupEntity: g,
        traverse: traverse,
        removeAll: false,
      );
      return getK<T>(typeEntity, groupEntity: g).unwrap();
    }).merge();
  }
}
