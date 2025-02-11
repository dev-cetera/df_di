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

import 'dart:async';

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base mixin SupportsMixinK on DIBase {
  Option<Sync<Object>> getSyncK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getK(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).map(
      (e) => e.isSync()
          ? e.sync().unwrap()
          : const Sync(
              Err(
                stack: ['SupportsMixinK', 'getSyncK'],
                error: 'Called getSyncK() an async dependency.',
              ),
            ),
    );
  }

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

  // TODO: NEW NEW NEW
  @protected
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
        // ignore: invalid_use_of_visible_for_testing_member
      ).unwrap().value,
      (e) => e.unwrap(),
    );
  }

  @protected
  Option<Resolvable<Object>> getK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final option = getDependencyK(
      typeEntity,
      groupEntity: g,
      traverse: traverse,
    );
    if (option.isNone()) {
      return const None();
    }
    final result = option.unwrap();
    if (result.isErr()) {
      return Some(Sync(result.err().castErr()));
    }
    final value = result.unwrap().value;
    if (value.isSync()) {
      return Some(value);
    }

    return Some(
      Async.unsafe(
        // ignore: invalid_use_of_visible_for_testing_member
        () => value.async().unwrap().value.then((e) {
          final value = e.unwrap();
          registry.removeDependencyK(typeEntity, groupEntity: g);
          final metadata = option.unwrap().unwrap().metadata.map(
                (e) => e.copyWith(
                  preemptivetypeEntity: TypeEntity(Sync, [typeEntity]),
                ),
              );
          _registerDependencyK(
            dependency: Dependency(
              Sync(Ok(value)),
              metadata: metadata,
            ),
            checkExisting: false,
          );
          return value;
        }),
      ),
    );
  }

  Result<Dependency<Object>> _registerDependencyK({
    required Dependency<Object> dependency,
    bool checkExisting = false,
  }) {
    // ignore: invalid_use_of_visible_for_testing_member
    final g = dependency.metadata.isSome() ? dependency.metadata.unwrap().groupEntity : focusGroup;
    if (checkExisting) {
      final option = getDependencyK(
        dependency.typeEntity,
        groupEntity: g,
        traverse: false,
        validate: false,
      );
      if (option.isSome()) {
        return const Err(
          stack: ['DIBase', '_registerDependency'],
          error: 'Dependency already registered.',
        );
      }
    }
    registry.setDependency(dependency);
    return Ok(dependency);
  }

  @protected
  Option<Result<Dependency<Object>>> getDependencyK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    bool validate = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final option = registry.getDependencyK(typeEntity, groupEntity: g);
    var temp = option.map((e) => Ok(e).result());
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

    if (temp.isSome()) {
      if (validate) {
        final result = temp.unwrap();
        if (result.isErr()) {
          return Some(result);
        }
        final dependency = result.unwrap();
        final metadata = dependency.metadata;
        if (metadata.isSome()) {
          final valid = metadata.unwrap().validator.map((e) => e(dependency));
          if (valid.isSome() && !valid.unwrap()) {
            return const Some(
              Err(
                stack: ['SupportsMixinK', 'getDependencyK'],
                error: 'Dependency validation failed.',
              ),
            );
          }
        }
      }
    }
    return temp;
  }

  Option<Resolvable<Object>> unregisterK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool skipOnUnregisterCallback = false,
  }) {
    final removed = removeDependencyK(typeEntity, groupEntity: groupEntity);
    if (removed.isNone()) {
      return const None();
    }
    final removedDependency = removed.unwrap() as Dependency;
    if (skipOnUnregisterCallback) {
      return Some(Sync(Ok(removedDependency.value)));
    }
    final metadata = removedDependency.metadata;
    if (metadata.isSome()) {
      final onUnregister = metadata.unwrap().onUnregister;
      if (onUnregister.isSome()) {
        return Some(
          onUnregister.unwrap()(removedDependency).map((_) => removedDependency),
        );
      }
    }
    return Some(Sync(Ok(removedDependency.value)));
  }

  @protected
  @pragma('vm:prefer-inline')
  Option<Object> removeDependencyK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    return registry
        .removeDependencyK(typeEntity, groupEntity: g)
        .or(registry.removeDependencyK(TypeEntity(Lazy, [typeEntity]), groupEntity: g));
  }

  @protected
  bool isRegisteredK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (registry.containsDependencyK(typeEntity, groupEntity: g) ||
        registry.containsDependencyK(TypeEntity(Lazy, [typeEntity]), groupEntity: g)) {
      return true;
    }
    if (traverse) {
      for (final parent in parents) {
        if ((parent as SupportsMixinK).isRegisteredK(typeEntity, groupEntity: g, traverse: true)) {
          return true;
        }
      }
    }
    return false;
  }

  Resolvable<Object> untilK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final option = getK(typeEntity, groupEntity: g);
    if (option.isSome()) {
      return option.some().unwrap().value;
    }
    if (completers.isSome()) {
      final option = completers.unwrap().registry.getDependencyK(
            TypeEntity(SafeCompleter, [typeEntity]),
            groupEntity: g,
          );

      if (option.isSome()) {
        final some = option.unwrap();
        // ignore: invalid_use_of_visible_for_testing_member
        final completer = some.value.sync().unwrap().value.unwrap();
        return (completer as SafeCompleter).resolvable;
      }
    } else {
      completers = Some(DIBase());
    }
    final completer = SafeCompleter();
    completers.unwrap().registry.setDependency(
          Dependency<SafeCompleter>(
            Sync(Ok(completer)),
            metadata: Some(
              DependencyMetadata(
                groupEntity: g,
              ),
            ),
          ),
        );
    return completer.resolvable.map((e) {
      completers.unwrap().registry.removeDependencyK(
            TypeEntity(SafeCompleter, [typeEntity]),
            groupEntity: g,
          );
      return e;
      //return get<T>();
    });
  }
}
