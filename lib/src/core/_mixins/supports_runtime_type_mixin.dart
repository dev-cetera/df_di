//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// ignore_for_file: invalid_use_of_protected_member

import '/src/_internal.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base mixin SupportsRuntimeTypeMixin on SupportsTypeKeyMixin {
  //
  //
  //

  Future<Object> getAsyncT(
    Type type, {
    DIKey? groupKey,
    bool traverse = true,
  }) async {
    return getT(
      type,
      groupKey: groupKey,
      traverse: traverse,
    );
  }

  //
  //
  //

  Object getSyncT(
    Type type, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final value = getT(
      type,
      groupKey: groupKey,
      traverse: traverse,
    );
    if (value is Future) {
      throw DependencyIsFutureException(
        type: type,
        groupKey: groupKey,
      );
    } else {
      return value;
    }
  }

  //
  //
  //

  Object? getSyncOrNullT(
    Type type, {
    DIKey? groupKey,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getOrNullT(
      type,
      groupKey: groupKey,
      traverse: traverse,
    );
    if (throwIfAsync && value is Future) {
      throw DependencyIsFutureException(
        type: type,
        groupKey: groupKey,
      );
    }
    return value?.asSyncOrNull;
  }

  //
  //
  //

  @protected
  FutureOr<Object> getT(
    Type type, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    return getK(
      DIKey(type),
      groupKey: groupKey,
      traverse: traverse,
    );
  }

  //
  //
  //

  FutureOr<Object> unregisterT(
    Type type, {
    DIKey? groupKey,
    bool skipOnUnregisterCallback = false,
  }) {
    return unregisterK(
      DIKey(type),
      groupKey: groupKey,
      skipOnUnregisterCallback: skipOnUnregisterCallback,
    );
  }

  //
  //
  //

  bool isRegisteredT(
    Type type, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    return isRegisteredK(
      DIKey(type),
      groupKey: groupKey,
      traverse: traverse,
    );
  }

  //
  //
  //

  FutureOr<Object>? getOrNullT(
    Type type, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    return getOrNullK(
      DIKey(type),
      groupKey: groupKey,
      traverse: traverse,
    );
  }

  //
  //
  //

  FutureOr<Object> untilT(
    Type type, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    return untilK(
      DIKey(type),
      groupKey: groupKey,
      traverse: traverse,
    );
  }
}
