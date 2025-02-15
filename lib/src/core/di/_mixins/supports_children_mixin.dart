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
// ignore_for_file: invalid_use_of_visible_for_testing_member

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base mixin SupportsChildrenMixin<H extends Object>
    on SupportsConstructorsMixin<H> {
  @protected
  Option<DI> children = const None();

  Result<void> registerChild<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    if (children.isNone()) {
      children = Some(DI());
    }
    return children.unwrap().registerLazy<DI<T>>(
      () => Sync(Ok(DI<T>()..parents.add(this as DI<H>))),
      groupEntity: groupEntity,
    );
  }

  Option<DI<T>> getChildOrNone<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final option = getChild<T>(groupEntity: groupEntity);
    if (option.isNone()) {
      return const None();
    }
    final result = option.unwrap();
    if (result.isErr()) {
      return const None();
    }
    return Some(result.unwrap());
  }

  OptionResult<DI<T>> getChild<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (children.isNone()) {
      return const None();
    }
    final option = children.unwrap().getSingleton<DI<T>>(groupEntity: g);
    if (option.isNone()) {
      return const None();
    }
    final result = option.unwrap().sync();
    if (result.isErr()) {
      return Some(result.err().castErr());
    }
    final value = result.unwrap().value;
    return Some(value);
  }

  OptionResult<DI> getChildT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (children.isNone()) {
      return const None();
    }
    final option = children.unwrap().getSingletonT(type, groupEntity: g);
    if (option.isNone()) {
      return const None();
    }
    final result = option.unwrap().sync();
    if (result.isErr()) {
      return Some(result.err().castErr());
    }
    final value = result.unwrap().value.cast<DI>();
    return Some(value);
  }

  Option<Resolvable<Object>> unregisterChild<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool skipOnUnregisterCallback = false,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (children.isNone()) {
      return const None();
    }
    return children.unwrap().unregister<DI<T>>(
      groupEntity: g,
      skipOnUnregisterCallback: skipOnUnregisterCallback,
    );
  }

  Option<Resolvable<Object>> unregisterChildT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool skipOnUnregisterCallback = false,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (children.isNone()) {
      return const None();
    }
    return children.unwrap().unregisterT(
      type,
      groupEntity: g,
      skipOnUnregisterCallback: skipOnUnregisterCallback,
    );
  }

  bool isChildRegistered<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (children.isNone()) {
      return false;
    }
    return children.unwrap().isRegistered<DI<T>>(groupEntity: g);
  }

  bool isChildRegisteredT<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (children.isNone()) {
      return false;
    }
    return children.unwrap().isRegisteredT(DI<T>, groupEntity: g);
  }

  DI<T> child<T extends Object>({Entity groupEntity = const DefaultEntity()}) {
    if (isChildRegistered<T>(groupEntity: groupEntity)) {
      return getChild<T>(groupEntity: groupEntity).unwrap().unwrap();
    }
    registerChild<T>(groupEntity: groupEntity);
    return getChild<T>(groupEntity: groupEntity).unwrap().unwrap();
  }
}
