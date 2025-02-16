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

base mixin SupportsMixinK on DIBase {
  //
  //
  //

  @protected
  @pragma('vm:prefer-inline')
  Object getSyncUnsafeK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getSyncK(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().value.unwrap();
  }

  @protected
  Option<Sync<Object>> getSyncK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getK(typeEntity, groupEntity: groupEntity, traverse: traverse).map(
      (e) => e.isSync()
          ? e.sync().unwrap()
          : Sync(
              Err(
                debugPath: ['SupportsMixinK', 'getSyncK'],
                error: 'Called getSyncK() an async dependency.',
              ),
            ),
    );
  }

  @protected
  @pragma('vm:prefer-inline')
  Future<Object> getAsyncUnsafeK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return Future.sync(() async {
      final result = await getAsyncK(
        typeEntity,
        groupEntity: groupEntity,
        traverse: traverse,
      ).unwrap().value;
      return result.unwrap();
    });
  }

  @protected
  @pragma('vm:prefer-inline')
  Option<Async<Object>> getAsyncK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getK(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.toAsync());
  }

  @protected
  @pragma('vm:prefer-inline')
  FutureOr<Object> getUnsafeK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return consec(
      getK(
        typeEntity,
        groupEntity: groupEntity,
        traverse: traverse,
      ).unwrap().value,
      (e) => e.unwrap(),
    );
  }

  @protected
  Option<Object> getSyncOrNoneK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final option = getK(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (option.isNone()) {
      return const None();
    }
    final resolvable = option.unwrap();
    if (resolvable.isAsync()) {
      return const None();
    }
    final result = resolvable.sync().unwrap().value;
    if (result.isErr()) {
      return const None();
    }
    final value = result.unwrap();
    return Some(value);
  }

  @protected
  Option<Resolvable<T>> getK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final option = getDependencyK<T>(
      typeEntity,
      groupEntity: g,
      traverse: traverse,
    );
    if (option.isNone()) {
      return const None();
    }
    final result = option.unwrap();
    if (result.isErr()) {
      return Some(Sync(result.err().transErr()));
    }
    final value = result.unwrap().value;
    if (value.isSync()) {
      return Some(value);
    }

    return Some(
      Async.unsafe(
        () => value.async().unwrap().value.then((e) {
          final value = e.unwrap();
          registry.removeDependencyK(typeEntity, groupEntity: g);
          final metadata = option.unwrap().unwrap().metadata.map(
                (e) => e.copyWith(
                  preemptivetypeEntity: TypeEntity(Sync, [typeEntity]),
                ),
              );
          registerDependencyK(
            dependency: Dependency(Sync(Ok(value)), metadata: metadata),
            checkExisting: false,
          );
          return value;
        }),
      ),
    );
  }

  @protected
  Result<Dependency<Object>> registerDependencyK({
    required Dependency<Object> dependency,
    bool checkExisting = false,
  }) {
    final g = dependency.metadata.isSome() ? dependency.metadata.unwrap().groupEntity : focusGroup;
    if (checkExisting) {
      final option = getDependencyK(
        dependency.typeEntity,
        groupEntity: g,
        traverse: false,
      );
      if (option.isSome()) {
        return Err(
          debugPath: ['DIBase', '_registerDependency'],
          error: 'Dependency already registered.',
        );
      }
    }
    registry.setDependency(dependency);
    return Ok(dependency);
  }

  @protected
  OptionResult<Dependency<T>> getDependencyK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final option = registry.getDependencyK(typeEntity, groupEntity: g);
    var temp = option.map((e) => Ok(e).asResult().trans<Dependency<T>>());
    if (option.isNone() && traverse) {
      for (final parent in parents) {
        temp = (parent as SupportsMixinK).getDependencyK(
          typeEntity,
          groupEntity: g,
        );
        if (temp.isSome()) {
          break;
        }
      }
    }
    return temp;
  }

  Result<void> unregisterK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool skipOnUnregisterCallback = false,
  }) {
    final removed = removeDependencyK<T>(typeEntity, groupEntity: groupEntity);
    if (removed.isErr()) {
      return removed.err().transErr();
    }
    return const Ok(Object());
  }

  @protected
  @pragma('vm:prefer-inline')
  ResultOption<T> removeDependencyK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    return registry
        .removeDependencyK<T>(typeEntity, groupEntity: g)
        .or(registry.removeDependencyK<Lazy<T>>(typeEntity, groupEntity: g))
        .trans();
  }

  @protected
  bool isRegisteredK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (registry.containsDependencyK(typeEntity, groupEntity: g) ||
        registry.containsDependencyK(
          TypeEntity(Lazy, [typeEntity]),
          groupEntity: g,
        )) {
      return true;
    }
    if (traverse) {
      for (final parent in parents) {
        if ((parent as SupportsMixinK).isRegisteredK(
          typeEntity,
          groupEntity: g,
          traverse: true,
        )) {
          return true;
        }
      }
    }
    return false;
  }
}
