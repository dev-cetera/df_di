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

  // Option<T> getSingletonSyncOrNone<T extends Object>({
  //   Entity groupEntity = const DefaultEntity(),
  //   bool traverse = true,
  // }) {
  //   final a = getSingleton<T>(
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  //   if (a.isAsync()) {
  //     return const None();
  //   }
  //   final b = a.sync();
  //   if (b.isErr()) {
  //     return const None();
  //   }
  //
  //   final c = b.unwrap().value;
  //   if (c.isErr()) {
  //     return const None();
  //   }
  //   return c.unwrap();
  // }

  @pragma('vm:prefer-inline')
  FutureOr<T> getSingletonUnsafe<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return consec(
      getSingleton<T>(
        groupEntity: groupEntity,
        traverse: traverse,
      ).unwrap(),
      (e) => e.unwrap(),
    );
  }

  ResolvableOption<T> getSingleton<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return get<Lazy<T>>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.map((e) => e.singleton)).reduce<T>();
  }

  @pragma('vm:prefer-inline')
  FutureOr<T> getFactoryUnsafe<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return consec(
      getFactory<T>(
        groupEntity: groupEntity,
        traverse: traverse,
      ).unwrap(),
      (e) => e.unwrap(),
    );
  }

  ResolvableOption<T> getFactory<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return get<Lazy<T>>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.map((e) => e.factory)).reduce<T>();
  }
}
