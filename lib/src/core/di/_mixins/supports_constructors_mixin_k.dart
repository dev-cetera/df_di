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

import 'dart:async';

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base mixin SupportsConstructorsMixinK on SupportsMixinK {
  Resolvable<void> resetSingletonK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final temp = getK(
      TypeEntity(Lazy, [typeEntity]),
      groupEntity: groupEntity,
    );
    if (temp.isSome()) {
      return temp.unwrap().map((e) => (e as Lazy)..resetSingleton());
    }
    return const Sync(Ok(Object()));
  }

  Resolvable<Option<Object>> getSingletonK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getK(
      TypeEntity(Lazy, [typeEntity]),
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.map((e) => (e as Lazy).singleton)).reduce<Object>();
  }

  FutureOr<Object> getSingletonUnsafeK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return consec(
      getUnsafeK(
        TypeEntity(Lazy, [typeEntity]),
        groupEntity: groupEntity,
        traverse: traverse,
      ),
      (e) => consec(
        // ignore: invalid_use_of_visible_for_testing_member
        (e as Lazy).singleton.value,
        (e) => e.unwrap(),
      ),
    );
  }

  Resolvable<Option<Object>> getFactoryK(
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
}
