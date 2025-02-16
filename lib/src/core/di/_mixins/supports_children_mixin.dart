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

// ignore_for_file: invalid_use_of_visible_for_testing_member

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base mixin SupportsChildrenMixin on SupportsConstructorsMixin {
  Result<void> registerChild<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    if (childrenContainer.isNone()) {
      childrenContainer = Some(DI());
    }
    return childrenContainer.unwrap().registerLazy<DI>(
          () => Sync(Ok(DI()..parents.add(this as DI))),
          groupEntity: groupEntity,
        );
  }

  Option<DI> getChildOrNone<T extends Object>({
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

  OptionResult<DI> getChild<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (childrenContainer.isNone()) {
      return const None();
    }
    final option = childrenContainer.unwrap().getSingleton<DI>(groupEntity: g);
    if (option.isNone()) {
      return const None();
    }
    final result = option.unwrap().sync();
    if (result.isErr()) {
      return Some(result.err().transErr());
    }
    final value = result.unwrap().value;
    return Some(value);
  }

  OptionResult<DI> getChildT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (childrenContainer.isNone()) {
      return const None();
    }
    final option = childrenContainer.unwrap().getSingletonT(type, groupEntity: g);
    if (option.isNone()) {
      return const None();
    }
    final result = option.unwrap().sync();
    if (result.isErr()) {
      return Some(result.err().transErr());
    }
    final value = result.unwrap().value.trans<DI>();
    return Some(value);
  }

  Result<void> unregisterChild({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (childrenContainer.isNone()) {
      return childrenContainer.asResult();
    }
    return childrenContainer.unwrap().unregister<DI>(
          groupEntity: g,
        );
  }

  Result<void> unregisterChildT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (childrenContainer.isNone()) {
      return childrenContainer.asResult();
    }
    return childrenContainer.unwrap().unregisterT<DI>(
          type,
          groupEntity: g,
        );
  }

  bool isChildRegistered<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (childrenContainer.isNone()) {
      return false;
    }
    return childrenContainer.unwrap().isRegistered<DI>(groupEntity: g);
  }

  bool isChildRegisteredT<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (childrenContainer.isNone()) {
      return false;
    }
    return childrenContainer.unwrap().isRegisteredT(DI, groupEntity: g);
  }

  DI child<T extends Object>({Entity groupEntity = const DefaultEntity()}) {
    if (isChildRegistered<T>(groupEntity: groupEntity)) {
      return getChild<T>(groupEntity: groupEntity).unwrap().unwrap();
    }
    registerChild<T>(groupEntity: groupEntity);
    return getChild<T>(groupEntity: groupEntity).unwrap().unwrap();
  }
}
