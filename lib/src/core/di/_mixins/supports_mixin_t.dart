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

base mixin SupportsMixinT on SupportsMixinK {
  @pragma('vm:prefer-inline')
  Option<Sync<Object>> getSyncT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getSyncK(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  @pragma('vm:prefer-inline')
  Option<Async<Object>> getAsyncT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getAsyncK(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  // TODO: NEW NEW NEW
  @pragma('vm:prefer-inline')
  FutureOr<Object> getUnsafeT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getUnsafeK(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  @pragma('vm:prefer-inline')
  Option<Resolvable<Object>> getT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getK(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  @pragma('vm:prefer-inline')
  OptionResult<Dependency<Object>> getDependencyT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    bool validate = true,
  }) {
    return getDependencyK(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
      validate: validate,
    );
  }

  @pragma('vm:prefer-inline')
  Option<Resolvable<Object>> unregisterT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool skipOnUnregisterCallback = false,
  }) {
    return unregisterK(
      TypeEntity(type),
      groupEntity: groupEntity,
      skipOnUnregisterCallback: skipOnUnregisterCallback,
    );
  }

  @pragma('vm:prefer-inline')
  Option<Object> removeDependencyT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    return removeDependencyK(
      TypeEntity(type),
      groupEntity: groupEntity,
    );
  }

  @pragma('vm:prefer-inline')
  bool isRegisteredT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return isRegisteredK(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  @pragma('vm:prefer-inline')
  Resolvable<Object> untilT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilK(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }
}
