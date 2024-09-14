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

base mixin SupportsChildrenMixin on SupportsConstructorsMixin {
  /// A container for storing children.
  late SupportsChildrenMixin? _children = this;

  /// Child containers.
  List<DI> get children =>
      List.unmodifiable(registry.dependencies.where((e) => e.value is DI));

  void registerChild({
    DIKey? groupKey,
    bool Function(FutureOr<DI>)? validator,
    OnUnregisterCallback<FutureOr<DI>>? onUnregister,
  }) {
    _children ??= DI() as SupportsChildrenMixin;
    _children!.registerConstructor<DI>(
      () => DI()..parents.add(this as DI),
      groupKey: groupKey,
      validator: validator,
      onUnregister: (e) =>
          mapFutureOr(onUnregister?.call(e), (_) => e.asResolved.unregisterAll()),
    );
  }

  DI getChild({
    DIKey? groupKey,
  }) {
    final value = getChildOrNull(
      groupKey: groupKey,
    );

    if (value == null) {
      throw DependencyNotFoundException(
        type: DI,
        groupKey: groupKey,
      );
    }
    return value;
  }

  DI? getChildOrNull({
    DIKey? groupKey,
  }) {
    return _children
        ?.getSingletonOrNull<DI>(
          groupKey: groupKey,
          traverse: false,
        )
        ?.asResolvedOrNull;
  }

  FutureOr<Object> unregisterChild({
    DIKey<Object>? groupKey,
    bool skipOnUnregisterCallback = false,
  }) {
    if (_children == null) {
      throw DependencyNotFoundException(
        type: DI,
        groupKey: groupKey,
      );
    }
    return _children!.unregister<DI>(
      groupKey: groupKey,
      skipOnUnregisterCallback: skipOnUnregisterCallback,
    );
  }

  DI child({
    DIKey? groupKey,
    bool Function(FutureOr<DI>)? validator,
    OnUnregisterCallback<FutureOr<DI>>? onUnregister,
  }) {
    final existingChild = getChildOrNull(groupKey: groupKey);
    if (existingChild != null) {
      return existingChild;
    }
    registerChild(
      groupKey: groupKey,
      validator: validator,
      onUnregister: onUnregister,
    );
    return getChildOrNull(groupKey: groupKey)!;
  }
}
