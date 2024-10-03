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

import '/src/_common.dart';

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

  /// Retrieves a dependency of the exact runtime [type] registered under the
  /// specified [groupKey].
  ///
  /// Note that this method will not return instances of subtypes. For example,
  /// if [type] is `List<dynamic>` and `List<String>` is actually registered,
  /// this method will not return that registered dependency. This limitation
  /// arises from the use of runtime types. If you need to retrieve subtypes,
  /// consider using the standard [get] method that employs generics and will
  /// return subtypes.
  ///
  /// If the dependency exists, it is returned; otherwise,
  /// a [DependencyNotFoundException] is thrown.
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  ///
  /// The return type is a [FutureOr], which means it can either be a
  /// [Future] or a resolved value.
  ///
  /// If the dependency is registered as a non-future, the returned value will
  /// always be non-future. If it is registered as a future, the returned value
  /// will initially be a future. Once that future completes, its resolved value
  /// is re-registered as a non-future, allowing future calls to this method
  /// to return the resolved value directly.
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

  /// Retrieves a dependency of the exact runtime [type] registered under the
  /// specified [groupKey].
  ///
  /// Note that this method will not return instances of subtypes. For example,
  /// if [type] is `List<dynamic>` and `List<String>` is actually registered,
  /// this method will not return that registered dependency. This limitation
  /// arises from the use of runtime types. If you need to retrieve subtypes,
  /// consider using the standard [get] method that employs generics and will
  /// return subtypes.
  ///
  /// If the dependency exists, it is returned; otherwise, `null` is returned.
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  ///
  /// The return type is a [FutureOr], which means it can either be a
  /// [Future] or a resolved value.
  ///
  /// If the dependency is registered as a non-future, the returned value will
  /// always be non-future. If it is registered as a future, the returned value
  /// will initially be a future. Once that future completes, its resolved value
  /// is re-registered as a non-future, allowing future calls to this method
  /// to return the resolved value directly.
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
