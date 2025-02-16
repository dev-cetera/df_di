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
  Resolvable<void> resetSingletonK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final temp = getK<T>(
      TypeEntity(Lazy, [typeEntity]),
      groupEntity: groupEntity,
    );
    if (temp.isSome()) {
      return temp.unwrap().map((e) => (e as Lazy)..resetSingleton());
    }
    return const Sync(Ok(Object()));
  }

  @pragma('vm:prefer-inline')
  FutureOr<T> getSingletonUnsafeK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getSingletonK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().unwrap();
  }

  Option<Resolvable<T>> getSingletonK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final option = getK<Lazy<T>>(
      TypeEntity(Lazy, [typeEntity]),
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (option.isNone()) {
      return const None();
    }
    final lazy = option.unwrap().sync().unwrap().unwrap();
    return Some(lazy.singleton);
  }

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

  Option<Resolvable<T>> getFactoryK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final option = getK<Lazy<T>>(
      TypeEntity(Lazy, [typeEntity]),
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (option.isNone()) {
      return const None();
    }
    final lazy = option.unwrap().sync().unwrap().unwrap();
    return Some(lazy.factory);
  }

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
      return e;
    });
  }
}
