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

base mixin SupportsConstructorsMixin<H extends Object> on SupportsMixinT<H> {
  //
  //
  //

  Result<void> registerLazy<T extends Object>(
    LazyConstructor<T> constructor, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    return register<Lazy<T>>(Lazy<T>(constructor), groupEntity: groupEntity);
  }

  Resolvable<void> resetSingleton<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final temp = get<Lazy<T>>(groupEntity: groupEntity);
    if (temp.isSome()) {
      return temp.unwrap().map((e) => e..resetSingleton());
    }
    return const Sync(Ok(Object()));
  }

  @pragma('vm:prefer-inline')
  FutureOr<T> getSingletonUnsafe<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return consec(
      getSingleton<T>(groupEntity: groupEntity, traverse: traverse).unwrap(),
      (e) => e.unwrap(),
    );
  }

  OptionResolvable<T> getSingleton<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final option = get<Lazy<T>>(groupEntity: groupEntity, traverse: traverse);
    if (option.isNone()) {
      return const None();
    }
    final resolvable = option.unwrap().map((e) => e.singleton).merge();
    return Some(resolvable);
  }

  @pragma('vm:prefer-inline')
  FutureOr<T> getFactoryUnsafe<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return consec(
      getFactory<T>(groupEntity: groupEntity, traverse: traverse).unwrap(),
      (e) => e.unwrap(),
    );
  }

  OptionResolvable<T> getFactory<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final option = get<Lazy<T>>(groupEntity: groupEntity, traverse: traverse);
    if (option.isNone()) {
      return const None();
    }
    final resolvable = option.unwrap().map((e) => e.factory).merge();
    return Some(resolvable);
  }
}
