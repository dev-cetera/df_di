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
  Option<SupportsConstructorsMixin> _children = const None();

  Result<void> registerChild({
    Entity groupEntity = const DefaultEntity(),
  }) {
    if (_children.isNone()) {
      _children = Some(DI() as SupportsChildrenMixin);
    }
    return _children.unwrap().registerLazy<DI>(
          () => Sync(Ok(DI()..parents.add(this as DI))),
          groupEntity: groupEntity,
        );
  }

  Option<Result<T>> getChildOrNone<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (_children.isNone()) {
      return const None();
    }
    final raw = _children.unwrap().get<T>(groupEntity: g);
    // ignore: invalid_use_of_visible_for_testing_member
    return raw.map((e) => e.sync().unwrap().value);
  }

  Option<Result<T>> getChild<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (_children.isNone()) {
      return const None();
    }
    final raw = _children.unwrap().get<T>(groupEntity: g);
    // ignore: invalid_use_of_visible_for_testing_member
    return raw.map((e) => e.sync().unwrap().value);
  }

  Option<Resolvable<Object>> unregisterChild({
    Entity groupEntity = const DefaultEntity(),
    bool skipOnUnregisterCallback = false,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (_children.isNone()) {
      return const None();
    }
    return _children.unwrap().unregister<DI>(
          groupEntity: g,
          skipOnUnregisterCallback: skipOnUnregisterCallback,
        );
  }

  bool isChildRegistered({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (_children.isNone()) {
      return false;
    }
    return _children.unwrap().isRegistered(groupEntity: g);
  }

  DI child({
    Entity groupEntity = const DefaultEntity(),
    bool Function(FutureOr<DI>)? validator,
    OnUnregisterCallback<FutureOr<DI>>? onUnregister,
  }) {
    final existingChild = getOrNone<DI>(groupEntity: groupEntity);
    if (existingChild.isSome()) {
      return existingChild.unwrap();
    }
    registerChild(groupEntity: groupEntity);
    return getSingleton<DI>(groupEntity: groupEntity).unwrapSync();
  }
}
