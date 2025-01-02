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
  /// A container for storing children.
  late SupportsChildrenMixin? _children = this;

  /// Child containers.
  List<DI> get children => List.unmodifiable(registry.dependencies.where((e) => e.value is DI));

  void registerChild({
    Entity? groupEntity,
    bool Function(FutureOr<DI>)? validator,
    OnUnregisterCallback<FutureOr<DI>>? onUnregister,
  }) {
    _children ??= DI() as SupportsChildrenMixin;
    _children!.registerLazy<DI>(
      () => DI()..parents.add(this as DI),
      groupEntity: groupEntity,
      validator: validator,
      onUnregister: (e) => consec(
        onUnregister?.call(e),
        (_) => e.asSync.unregisterAll(),
      ),
    );
  }

  DI getChild({
    Entity? groupEntity,
  }) {
    final groupEntity1 = groupEntity ?? focusGroup;
    final value = getChildOrNull(
      groupEntity: groupEntity1,
    );

    if (value == null) {
      throw DependencyNotFoundException(
        type: DI,
        groupEntity: groupEntity1,
      );
    }
    return value;
  }

  DI? getChildOrNull({
    Entity? groupEntity,
  }) {
    return _children
        ?.getSingletonOrNull<DI>(
          groupEntity: groupEntity,
          traverse: false,
        )
        ?.asSyncOrNull;
  }

  FutureOr<Object> unregisterChild({
    Entity? groupEntity,
    bool skipOnUnregisterCallback = false,
  }) {
    final groupEntity1 = groupEntity ?? focusGroup;
    if (_children == null) {
      throw DependencyNotFoundException(
        type: DI,
        groupEntity: groupEntity1,
      );
    }
    return _children!.unregister<DI>(
      groupEntity: groupEntity1,
      skipOnUnregisterCallback: skipOnUnregisterCallback,
    );
  }

  DI child({
    Entity? groupEntity,
    bool Function(FutureOr<DI>)? validator,
    OnUnregisterCallback<FutureOr<DI>>? onUnregister,
  }) {
    final existingChild = getChildOrNull(groupEntity: groupEntity);
    if (existingChild != null) {
      return existingChild;
    }
    registerChild(
      groupEntity: groupEntity,
      validator: validator,
      onUnregister: onUnregister,
    );
    return getChildOrNull(groupEntity: groupEntity)!;
  }
}
