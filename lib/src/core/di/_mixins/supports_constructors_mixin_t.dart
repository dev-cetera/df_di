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

base mixin SupportsConstructorsMixinT on SupportsConstructorsMixinK {
  @pragma('vm:prefer-inline')
  Resolvable<void> resetSingletonT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    return resetSingletonK(
      TypeEntity(type),
      groupEntity: groupEntity,
    );
  }

  @pragma('vm:prefer-inline')
  Resolvable<Option<Object>> getSingletonT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getSingletonT(
      type,
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  @pragma('vm:prefer-inline')
  FutureOr<Object> getSingletonUnsafeT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getSingletonUnsafeK(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  @pragma('vm:prefer-inline')
  Resolvable<Option<Object>> getFactoryT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getFactoryK(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }
}
