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

base mixin SupportsConstructorsMixin on SupportsMixinT {
  Result<void> registerLazy<T extends Object>(
    LazyConstructor<T> constructor, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    return registerValue<Lazy<T>>(
      Lazy<T>(constructor),
      groupEntity: groupEntity,
    );
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

  Resolvable<Option<T>> getSingleton<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return get<Lazy<T>>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.map((e) => e.singleton)).reduce<T>();
  }

  FutureOr<T> getSingletonUnsafe<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return consec(
      getUnsafe<Lazy<T>>(
        groupEntity: groupEntity,
        traverse: traverse,
      ),
      (e) => consec(
        // ignore: invalid_use_of_visible_for_testing_member
        e.singleton.value,
        (e) => e.unwrap(),
      ),
    );
  }

  Resolvable<Option<T>> getFactory<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return get<Lazy<T>>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.map((e) => e.factory)).reduce<T>();
  }
}
