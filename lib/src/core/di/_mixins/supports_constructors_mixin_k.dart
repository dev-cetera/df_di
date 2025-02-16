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

// ignore_for_file: invalid_use_of_protected_member

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base mixin SupportsConstructorsMixinK<H extends Object> on SupportsMixinK<H> {
  Resolvable<void> resetSingletonK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final temp = getK(
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
    assert(T != Object, 'T must be specified and cannot be Object.');
    return consec(
      getSingletonK(
        typeEntity,
        groupEntity: groupEntity,
        traverse: traverse,
      ).unwrap(),
      (e) => e.trans<T>().unwrap(),
    );
  }

  OptionResolvable<T> getSingleton<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final option = get<Lazy<T>>(groupEntity: groupEntity, traverse: traverse);
    if (option.isNone()) {
      return const None();
    }
    final resolvable = option.unwrap().map((e) => e.singleton).merge();
    return Some(resolvable);
  }

  OptionResolvable<T> getSingletonK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final option = getK<T>(
      TypeEntity(Lazy, [typeEntity]),
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (option.isNone()) {
      return const None();
    }
    final resolvable = option.unwrap().map((e) => (e as Lazy).singleton).merge().trans<T>();
    return Some(resolvable);
  }

  @pragma('vm:prefer-inline')
  FutureOr<Object> getFactoryUnsafeK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getFactoryK(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap();
  }

  ResolvableOption getFactoryK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getK(
      TypeEntity(Lazy, [typeEntity]),
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.map((e) => (e as Lazy).factory)).reduce<Object>();
  }

  Resolvable<Object> untilK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final test = getK(typeEntity, groupEntity: g);
    if (test.isSome()) {
      return test.unwrap();
    }
    ReservedSafeFinisher finisher;
    final option = getSyncOrNone<ReservedSafeFinisher>(groupEntity: g);
    if (option.isSome()) {
      finisher = option.unwrap();
    } else {
      finisher = ReservedSafeFinisher(typeEntity);
      register<ReservedSafeFinisher>(finisher, groupEntity: g);
    }
    return finisher.resolvable().map((e) {
      registry.removeDependencyK(
        TypeEntity(ReservedSafeFinisher, [typeEntity]),
        groupEntity: g,
      );
      return e;
    });
  }
}
