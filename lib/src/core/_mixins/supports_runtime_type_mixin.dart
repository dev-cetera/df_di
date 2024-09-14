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

  FutureOr<Object> registerT(
    FutureOr<Object> value, {
    DIKey? groupKey,
    DependencyValidator<FutureOr<Object>>? validator,
    OnUnregisterCallback<FutureOr<Object>>? onUnregister,
  }) {
    return registerK(
      value,
      groupKey: groupKey,
      validator: validator,
      onUnregister: onUnregister,
    );
  }

  //
  //
  //

  FutureOr<Object> unregisterT(
    Type runtimeType, {
    DIKey? groupKey,
    bool skipOnUnregisterCallback = false,
  }) {
    return unregisterK(
      DIKey(runtimeType),
      groupKey: groupKey,
      skipOnUnregisterCallback: skipOnUnregisterCallback,
    );
  }

  //
  //
  //

  FutureOr<Object>? getOrNullT(
    Type runtimeType, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    return getOrNullK(
      DIKey(runtimeType),
      groupKey: groupKey,
      traverse: traverse,
    );
  }

  //
  //
  //

  FutureOr<Object> untilT(
    Type runtimeType, {
    DIKey? groupKey,
    bool traverse = true,
  }) {
    return untilK(
      DIKey(runtimeType),
      groupKey: groupKey,
      traverse: traverse,
    );
  }
}
