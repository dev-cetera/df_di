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

base mixin SupportsChildrenMixin on SupportsConstructorsMixin {
  // /// A container for storing children.
  // late SupportsChildrenMixin? _children = this;

  // /// Child containers.
  // List<DI> get children => List.unmodifiable(registry.dependencies.where((e) => e.value is DI));

  // /// Registers a new child container under the specified [groupEntity] in the
  // /// [registry].
  // ///
  // /// You can provide a [validator] function to validate the dependency before
  // /// it gets retrieved. If the validation fails [DependencyInvalidException]
  // /// will be throw upon retrieval.
  // ///
  // /// Additionally, an [onUnregister] callback can be specified to execute when
  // /// the dependency is unregistered via [unregister].
  // void registerChild({
  //   Entity? groupEntity,
  //   bool Function(FutureOr<DI>)? validator,
  //   OnUnregisterCallback<FutureOr<DI>>? onUnregister,
  // }) {
  //   _children ??= DI() as SupportsChildrenMixin;
  //   _children!.registerLazy<DI>(
  //     () => DI()..parents.add(this as DI),
  //     groupEntity: groupEntity,
  //     validator: validator,
  //     onUnregister: (e) => consec(
  //       onUnregister?.call(e),
  //       (_) => e.asSync.unregisterAll(),
  //     ),
  //   );
  // }

  // /// Retrieves the child container registered under the specified
  // /// [groupEntity] from the [registry].
  // ///
  // /// If the child exists, it is returned; otherwise, a
  // /// [DependencyNotFoundException] is thrown.
  // DI getChild({
  //   Entity? groupEntity,
  // }) {
  //   final groupEntity1 = groupEntity ?? focusGroup;
  //   final value = getChildOrNull(
  //     groupEntity: groupEntity1,
  //   );

  //   if (value == null) {
  //     throw DependencyNotFoundException(
  //       type: DI,
  //       groupEntity: groupEntity1,
  //     );
  //   }
  //   return value;
  // }

  // /// Retrieves the child container registered under the specified
  // /// [groupEntity] from the [registry].
  // ///
  // /// If the dependency does not exist, `null` is returned.
  // DI? getChildOrNull({
  //   Entity? groupEntity,
  // }) {
  //   return _children
  //       ?.getSingletonOrNull<DI>(
  //         groupEntity: groupEntity,
  //         traverse: false,
  //       )
  //       ?.asSyncOrNull;
  // }

  // /// Unregisters the child container registered under the specified
  // /// [groupEntity] in the [registry].
  // ///
  // /// If [skipOnUnregisterCallback] is true,
  // /// the [DependencyMetadata.onUnregister] callback will be skipped.
  // ///
  // /// Throws a [DependencyNotFoundException] if the dependency is not found.
  // FutureOr<Object> unregisterChild({
  //   Entity? groupEntity,
  //   bool skipOnUnregisterCallback = false,
  // }) {
  //   final groupEntity1 = groupEntity ?? focusGroup;
  //   if (_children == null) {
  //     throw DependencyNotFoundException(
  //       type: DI,
  //       groupEntity: groupEntity1,
  //     );
  //   }
  //   return _children!.unregister<DI>(
  //     groupEntity: groupEntity1,
  //     skipOnUnregisterCallback: skipOnUnregisterCallback,
  //   );
  // }

  // /// Checks whether a child container is registered under the specified
  // /// [groupEntity] in the [registry].
  // bool isChildRegistered({
  //   Entity? groupEntity,
  // }) {
  //   final groupEntity1 = groupEntity ?? focusGroup;
  //   if (registry.containsDependency<DI>(groupEntity: groupEntity1)) {
  //     return true;
  //   }
  //   return false;
  // }

  // /// Registers a new child container under the specified [groupEntity] in the
  // /// registry, and returns it.
  // ///
  // /// You can provide a [validator] function to validate the dependency before
  // /// it gets retrieved. If the validation fails [DependencyInvalidException]
  // /// will be throw upon retrieval.
  // ///
  // /// You can provide an [onUnregister] callback can be specified to execute
  // /// when the dependency is unregistered via [unregister].
  // DI child({
  //   Entity? groupEntity,
  //   bool Function(FutureOr<DI>)? validator,
  //   OnUnregisterCallback<FutureOr<DI>>? onUnregister,
  // }) {
  //   final existingChild = getChildOrNull(groupEntity: groupEntity);
  //   if (existingChild != null) {
  //     return existingChild;
  //   }
  //   registerChild(
  //     groupEntity: groupEntity,
  //     validator: validator,
  //     onUnregister: onUnregister,
  //   );
  //   return getChildOrNull(groupEntity: groupEntity)!;
  // }
}
