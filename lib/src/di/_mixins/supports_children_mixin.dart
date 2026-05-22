//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base mixin SupportsChildrenMixin on SupportsConstructorsMixin {
  Resolvable<Lazy<DI>> registerChild({
    Entity groupEntity = const DefaultEntity(),
  }) {
    if (childrenContainer.isNone()) {
      childrenContainer = Some(DI());
    }
    UNSAFE:
    return childrenContainer.unwrap().registerLazy<DI>(
      () => Sync.okValue(DI()..parents.add(this as DI)),
      groupEntity: groupEntity,
    );
  }

  Option<DI> getChildOrNone({Entity groupEntity = const DefaultEntity()}) {
    final option = getChild(groupEntity: groupEntity);
    if (option.isNone()) {
      return const None();
    }
    UNSAFE:
    {
      final result = option.unwrap();
      if (result.isErr()) {
        return const None();
      }
      return Some(result.unwrap());
    }
  }

  Option<Result<DI>> getChild({Entity groupEntity = const DefaultEntity()}) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (childrenContainer.isNone()) {
      return const None();
    }
    UNSAFE:
    {
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
  }

  Option<Result<DI>> getChildT({Entity groupEntity = const DefaultEntity()}) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (childrenContainer.isNone()) {
      return const None();
    }
    UNSAFE:
    {
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
  }

  /// Children are registered as `Lazy<DI>`, so unregister must remove the
  /// lazy key — `unregister<DI>` would not match under the strict-keying
  /// contract.
  Result<Option<DI>> unregisterChild({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (childrenContainer.isNone()) {
      return Err('No child container registered.');
    }
    UNSAFE:
    {
      final result = childrenContainer
          .unwrap()
          .unregister<Lazy<DI>>(groupEntity: g)
          .sync()
          .unwrap()
          .value;
      if (result.isErr()) {
        return result.err().unwrap().transfErr<Option<DI>>();
      }
      final option = result.unwrap();
      if (option.isNone()) {
        return const Ok(None());
      }
      final lazy = option.unwrap();
      final di = lazy.singleton.sync().unwrap().unwrap();
      return Ok(Some(di));
    }
  }

  Result<Option<DI>> unregisterChildT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (childrenContainer.isNone()) {
      return Err('No child container registered.');
    }
    UNSAFE:
    {
      final result = childrenContainer
          .unwrap()
          .unregisterK(TypeEntity(Lazy, [type]), groupEntity: g)
          .sync()
          .unwrap()
          .value;
      if (result.isErr()) {
        return result.err().unwrap().transfErr<Option<DI>>();
      }
      final option = result.unwrap();
      if (option.isNone()) {
        return const Ok(None());
      }
      final lazy = option.unwrap() as Lazy<DI>;
      final di = lazy.singleton.sync().unwrap().unwrap();
      return Ok(Some(di));
    }
  }

  /// Children are registered as `Lazy<DI>` (see [registerChild]), so probe
  /// for that exact key — `isRegistered<DI>` would not match under the
  /// strict-keying contract.
  bool isChildRegistered<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (childrenContainer.isNone()) {
      return false;
    }
    UNSAFE:
    return childrenContainer.unwrap().isRegistered<Lazy<DI>>(groupEntity: g);
  }

  bool isChildRegisteredT<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (childrenContainer.isNone()) {
      return false;
    }
    UNSAFE:
    return childrenContainer.unwrap().isRegisteredK(
      TypeEntity(Lazy, [DI]),
      groupEntity: g,
    );
  }

  DI child({Entity groupEntity = const DefaultEntity()}) {
    UNSAFE:
    {
      if (isChildRegistered(groupEntity: groupEntity)) {
        return getChild(groupEntity: groupEntity).unwrap().unwrap();
      }
      registerChild(groupEntity: groupEntity).end();
      return getChild(groupEntity: groupEntity).unwrap().unwrap();
    }
  }
}
