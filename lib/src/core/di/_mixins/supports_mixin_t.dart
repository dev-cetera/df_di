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
  /// Retrieves a dependency of the exact runtime [type] registered under the
  /// specified [groupEntity] in the [registry].
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  ///
  /// If the dependency does not exist, a [DependencyNotFoundException] is
  /// thrown.
  ///
  /// This method always returns a [Future], ensuring compatibility. This
  /// provides a safe and consistent way to retrieve dependencies, even if the
  /// registered dependency is not a [Future].
  // Result<Option<Future<Object>>> getAsyncT(
  //   Type type, {
  //   Entity groupEntity = const Entity.defaultEntity(),
  //   bool traverse = true,
  // }) {
  //   return getT(
  //     type,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   ).map((e) => e.map((e) async => e));
  // }

  /// Retrieves a dependency of the exact runtime [type] registered under the
  /// specified [groupEntity] from the [registry].
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  ///
  /// If the dependency is a [Future], a [DependencyIsFutureException] is
  /// thrown.
  ///
  /// If the dependency does not exist, a [DependencyNotFoundException] is
  /// thrown.
  // Object getSyncT(
  //   Type type, {
  //   Entity groupEntity = const Entity.defaultEntity(),
  //   bool traverse = true,
  // }) {
  //   final value = getT(
  //     type,
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  //   if (value.isErr) {
  //     return value.err;
  //   }
  //   return Result(
  //     () {
  //       PanicIf(
  //         value.unwrap().isSome && value.unwrap() is Future,
  //         'getSyncT cannot return a Future.',
  //       );
  //       return value.unwrap();
  //     },
  //   );
  // }

  // /// Retrieves a dependency of the exact runtime [type] registered under the
  /// specified [groupEntity] from the [registry].
  ///
  /// Note that this method will not return instances of subtypes. For example,
  /// if [type] is `List<dynamic>` and `List<String>` is actually registered,
  /// this method will not return that registered dependency. This limitation
  /// arises from the use of runtime types. If you need to retrieve subtypes,
  /// consider using the standard [get] method that employs generics and will
  /// return subtypes.
  ///
  /// If the dependency does not exist, a [DependencyNotFoundException] is
  /// thrown.
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  ///
  /// If the dependency is registered as a non-future, the returned value will
  /// always be non-future. If it is registered as a future, the returned value
  /// will initially be a future. Once that future completes, its resolved value
  /// is re-registered as a non-future, allowing future calls to this method
  /// to return the resolved value directly.
  @protected
  // Result<Option<Resolvable<Object>>> getT(
  //   Type type, {
  //   Entity groupEntity = const Entity.defaultEntity(),
  //   bool traverse = true,
  // }) {
  //   return getK(
  //     Entity.obj(type),
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  // }

  /// Unregisters a dependency of the exact runtime [type] registered under the
  /// specified [groupEntity] from the [registry], if it exists.
  ///
  /// If [skipOnUnregisterCallback] is true, the
  /// [DependencyMetadata.onUnregister] callback will be skipped.
  ///
  /// Throws a [DependencyNotFoundException] if the dependency is not found.
  // Option<Resolvable<Object>> unregisterT(
  //   Type type, {
  //   Entity groupEntity = const Entity.defaultEntity(),
  //   bool skipOnUnregisterCallback = false,
  // }) {
  //   return unregisterK(
  //     Entity.obj(type),
  //     groupEntity: groupEntity,
  //     skipOnUnregisterCallback: skipOnUnregisterCallback,
  //   );
  // }

  /// Checks whether a dependency of the exact runtime [type] is registered
  /// under the specified [groupEntity] in the [registry].
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  bool isRegisteredT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return isRegisteredK(
      Entity.obj(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Retrieves a dependency of the exact runtime [type] registered under the
  /// specified [groupEntity] from the [registry].
  ///
  /// If the dependency is found, it is returned; otherwise, this method waits
  /// until the dependency is registered before returning it.
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  // Result<Option<Resolvable<Object>>> untilT(
  //   Type type, {
  //   Entity groupEntity = const Entity.defaultEntity(),
  //   bool traverse = true,
  // }) {
  //   return untilK(
  //     Entity.obj(type),
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  // }
}
