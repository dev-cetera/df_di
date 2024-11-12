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

base mixin SupportsRuntimeTypeMixin on SupportstypeEntityMixin {
  //
  //
  //

  Future<Object> getAsyncT(
    Type type, {
    Entity? groupEntity,
    bool traverse = true,
  }) async {
    return getT(
      type,
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  //
  //
  //

  Object getSyncT(
    Type type, {
    Entity? groupEntity,
    bool traverse = true,
  }) {
    final value = getT(
      type,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (value is Future) {
      throw DependencyIsFutureException(
        type: type,
        groupEntity: groupEntity,
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
    Entity? groupEntity,
    bool traverse = true,
    bool throwIfAsync = false,
  }) {
    final value = getOrNullT(
      type,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (throwIfAsync && value is Future) {
      throw DependencyIsFutureException(
        type: type,
        groupEntity: groupEntity,
      );
    }
    return value?.asSyncOrNull;
  }

  //
  //
  //

  /// Retrieves a dependency of the exact runtime [type] registered under the
  /// specified [groupEntity].
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
    Entity? groupEntity,
    bool traverse = true,
  }) {
    return getK(
      Entity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  //
  //
  //

  FutureOr<Object> unregisterT(
    Type type, {
    Entity? groupEntity,
    bool skipOnUnregisterCallback = false,
  }) {
    return unregisterK(
      Entity(type),
      groupEntity: groupEntity,
      skipOnUnregisterCallback: skipOnUnregisterCallback,
    );
  }

  //
  //
  //

  bool isRegisteredT(
    Type type, {
    Entity? groupEntity,
    bool traverse = true,
  }) {
    return isRegisteredK(
      Entity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  //
  //
  //

  /// Retrieves a dependency of the exact runtime [type] registered under the
  /// specified [groupEntity].
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
    Entity? groupEntity,
    bool traverse = true,
  }) {
    return getOrNullK(
      Entity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  //
  //
  //

  FutureOr<Object> untilT(
    Type type, {
    Entity? groupEntity,
    bool traverse = true,
  }) {
    return untilK(
      Entity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }
}
