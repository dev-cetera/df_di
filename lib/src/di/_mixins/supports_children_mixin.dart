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

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base mixin SupportsChildrenMixin on SupportsConstructorsMixin {
  Resolvable<Lazy<DI>> registerChild({Entity groupEntity = const DefaultEntity()}) {
    if (childrenContainer.isNone()) {
      childrenContainer = Some(DI());
    }
    return childrenContainer.unwrap().registerLazy<DI>(
          () => Sync.value(Ok(DI()..parents.add(this as DI))),
          groupEntity: groupEntity,
        );
  }

  Option<DI> getChildOrNone({Entity groupEntity = const DefaultEntity()}) {
    final option = getChild(groupEntity: groupEntity);
    if (option.isNone()) {
      return const None();
    }
    final result = option.unwrap();
    if (result.isErr()) {
      return const None();
    }
    return Some(result.unwrap());
  }

  Option<Result<DI>> getChild({Entity groupEntity = const DefaultEntity()}) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (childrenContainer.isNone()) {
      return const None();
    }
    final option = childrenContainer.unwrap().getLazySingleton<DI>(
          groupEntity: g,
        );
    if (option.isNone()) {
      return const None();
    }
    final result = option.unwrap().sync();
    if (result.isErr()) {
      return Some(result.err().unwrap().transfErr());
    }
    final value = result.unwrap().value;
    return Some(value);
  }

  Option<Result<DI>> getChildT({Entity groupEntity = const DefaultEntity()}) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (childrenContainer.isNone()) {
      return const None();
    }
    final option = childrenContainer.unwrap().getLazySingletonT<DI>(
          DI,
          groupEntity: g,
        );
    if (option.isNone()) {
      return const None();
    }
    final result = option.unwrap().sync();
    if (result.isErr()) {
      return Some(result.err().unwrap().transfErr());
    }
    final value = result.unwrap().value.transf<DI>();
    return Some(value);
  }

  Result<Option<DI>> unregisterChild({Entity groupEntity = const DefaultEntity()}) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (childrenContainer.isNone()) {
      return Err('No child container registered.');
    }
    return childrenContainer.unwrap().unregister<DI>(groupEntity: g).sync().unwrap().value;
  }

  Result<Option<DI>> unregisterChildT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (childrenContainer.isNone()) {
      return Err('No child container registered.');
    }
    return childrenContainer
        .unwrap()
        .unregisterT(type, groupEntity: g)
        .sync()
        .unwrap()
        .value
        .map((e) => e.transf<DI>())
        .flatten();
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

  DI child({Entity groupEntity = const DefaultEntity()}) {
    if (isChildRegistered(groupEntity: groupEntity)) {
      return getChild(groupEntity: groupEntity).unwrap().unwrap();
    }
    registerChild(groupEntity: groupEntity).end();
    return getChild(groupEntity: groupEntity).unwrap().unwrap();
  }
}
