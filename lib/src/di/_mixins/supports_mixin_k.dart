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
import '../../_reserved_safe_completer.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A mixin that provides methods for working with dependencies,
/// using `Entity` for type resolution.
base mixin SupportsMixinK on DIBase {
  /// Retrieves the synchronous dependency unsafely, returning the instance
  /// directly.
  @pragma('vm:prefer-inline')
  T getSyncUnsafeK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    UNSAFE:
    return getSyncK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().value.unwrap();
  }

  /// Retrieves the synchronous dependency.
  Option<Sync<T>> getSyncK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    UNSAFE:
    return getK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).map(
      (e) => e.isSync()
          ? e.sync().unwrap()
          : Sync.err(Err('Called getSyncK() for an async dependency.')),
    );
  }

  /// Retrieves an asynchronous dependency unsafely, returning a future of the
  /// instance, directly or throwing an error if not found.
  @pragma('vm:prefer-inline')
  Future<T> getAsyncUnsafeK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    UNSAFE:
    return Future.sync(() async {
      final result = await getAsyncK<T>(
        typeEntity,
        groupEntity: groupEntity,
        traverse: traverse,
      ).unwrap().value;
      return result.unwrap();
    });
  }

  /// Retrieves an asynchronous dependency.
  @pragma('vm:prefer-inline')
  Option<Async<T>> getAsyncK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.toAsync());
  }

  /// Retrieves a dependency unsafely, returning it directly or throwing an
  /// error if not found.
  @pragma('vm:prefer-inline')
  FutureOr<T> getUnsafeK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    UNSAFE:
    return getK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().unwrap();
  }

  /// Retrieves the synchronous dependency or `None` if not found or async.
  Option<T> getSyncOrNoneK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final option = getK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (option.isNone()) {
      return const None();
    }
    UNSAFE:
    {
      final resolvable = option.unwrap();
      if (resolvable.isAsync()) {
        return const None();
      }
      final result = resolvable.sync().unwrap().value;
      if (result.isErr()) {
        return const None();
      }
      final value = result.transf<T>().unwrap();
      return Some(value);
    }
  }

  /// Retrieves the dependency.
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
    UNSAFE:
    {
      final result = option.unwrap();
      if (result.isErr()) {
        return Some(Sync.err(result.err().unwrap().transfErr()));
      }
      final value = result.unwrap().value;
      if (value.isSync()) {
        return Some(value);
      }
      return Some(
        Async(
          () => value.async().unwrap().value.then((e) {
            final value = e.unwrap();
            registry.removeDependencyK(typeEntity, groupEntity: g).end();
            final metadata = option.unwrap().unwrap().metadata.map(
                  (e) => e.copyWith(
                    preemptivetypeEntity: TypeEntity(Sync, [typeEntity]),
                  ),
                );
            registerDependencyK(
              dependency: Dependency(Sync.okValue(value), metadata: metadata),
              checkExisting: false,
            ).end();
            return value;
          }),
        ),
      );
    }
  }

  /// Retrieves the underlying `Dependency` object.
  Result<Dependency<T>> registerDependencyK<T extends Object>({
    required Dependency<T> dependency,
    bool checkExisting = false,
  }) {
    UNSAFE:
    final g = dependency.metadata.isSome()
        ? dependency.metadata.unwrap().groupEntity
        : focusGroup;
    if (checkExisting) {
      final option = getDependencyK(
        dependency.typeEntity,
        groupEntity: g,
        traverse: false,
      );
      if (option.isSome()) {
        return Err('Dependency already registered.');
      }
    }
    registry.setDependency(dependency);
    return Ok(dependency);
  }

  /// Retrieves the underlying `Dependency` object.
  Option<Result<Dependency<T>>> getDependencyK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final option = registry.getDependencyK(typeEntity, groupEntity: g);
    var temp = option.map((e) => Ok(e).transf<Dependency<T>>());
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

  /// Unregisters a dependency.
  ///
  /// Honors the same contract as [DIBase.unregister]: `traverse: false`
  /// limits to this container, `removeAll: true` walks every matching
  /// registration, and `triggerOnUnregisterCallbacks: true` fires the
  /// `onUnregister` of **every** removed dependency.
  Resolvable<Option> unregisterK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    bool removeAll = true,
    bool triggerOnUnregisterCallbacks = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final removed = <Dependency>[];

    final containers = traverse ? [this as DI, ...parents] : [this as DI];
    for (final di in containers) {
      final dependencyOption = di.removeDependencyK(typeEntity, groupEntity: g);
      if (dependencyOption.isNone()) {
        if (!removeAll) break;
        continue;
      }
      UNSAFE:
      removed.add(dependencyOption.unwrap());
      // Clean up matching completers on this container
      cleanupCompleters(typeEntity, groupEntity: g);
      if (!removeAll) break;
    }

    if (removed.isEmpty) return syncNone();

    UNSAFE:
    {
      final firstValue = removed.first.value;
      return Resolvable<Option>(() {
        return consec<Object, Option>(firstValue.unwrap(), (first) {
          if (!triggerOnUnregisterCallbacks) return Some(first);
          FutureOr<Option> chain = Some(first);
          for (final dep in removed) {
            final metaOpt = dep.metadata;
            if (metaOpt.isNone()) continue;
            final cbOpt = metaOpt.unwrap().onUnregister;
            if (cbOpt.isNone()) continue;
            final cb = cbOpt.unwrap();
            final depValue = dep.value;
            chain = consec(chain, (acc) {
              return consec(depValue.unwrap(), (resolvedDepValue) {
                FutureOr<void> cbResult;
                try {
                  cbResult = cb(Ok(resolvedDepValue));
                } catch (e) {
                  Log.err(
                    'onUnregister for ${dep.runtimeType} threw '
                    'synchronously: $e',
                  );
                  return acc;
                }
                return consec<void, Option>(cbResult, (_) => acc);
              });
            });
          }
          return chain;
        });
      });
    }
  }

  /// Removes the dependency keyed under exact [typeEntity] from the registry.
  /// Strict: a `Lazy<...>` variant is NOT matched here — callers wanting that
  /// must pass `TypeEntity(Lazy, [typeEntity])` explicitly. Mirrors the
  /// keying contract of `setDependency`.
  @pragma('vm:prefer-inline')
  Option<Dependency> removeDependencyK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final result = registry.removeDependencyK(typeEntity, groupEntity: g);
    if (result.isSome()) {
      cleanupCompleters(typeEntity, groupEntity: g);
    }
    return result;
  }

  /// Returns whether a dependency keyed under exact [typeEntity] is
  /// registered. Strict: a `Lazy<...>` variant is NOT matched — pass
  /// `TypeEntity(Lazy, [typeEntity])` explicitly to check for that.
  bool isRegisteredK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (registry.containsDependencyK(typeEntity, groupEntity: g)) {
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

  /// Waits until a dependency with the exact `typeEntity` is registered.
  /// The result is cast to `T`.
  ///
  /// **Note:** Requires `enableUntilExactlyK: true` during registration.
  /// If `typeEntity` doesn't match an existing or future registration exactly,
  /// this will not resolve.
  ///
  /// The completer captures a registration epoch at creation. If the
  /// dependency is unregistered between the time this caller starts waiting
  /// and the time its continuation runs, the epoch advances and the
  /// continuation re-waits for the next registration rather than returning a
  /// stale value (or `unwrap`-ping a now-missing dependency).
  Resolvable<T> untilExactlyK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final test = getK<T>(typeEntity, groupEntity: g, traverse: traverse);
    UNSAFE:
    {
      if (test.isSome()) {
        return test.unwrap();
      }
      final myEpoch = _epochForK(g, typeEntity);
      var completer = completersK[g]?.firstWhereOrNull(
        (e) => e.typeEntity == typeEntity,
      );
      if (completer == null) {
        completer = ReservedSafeCompleter(typeEntity);
        (completersK[g] ??= []).add(completer);
      }
      return completer.resolvable().then((_) {
        final temp = completersK[g] ?? [];
        for (var n = 0; n < temp.length; n++) {
          final e = temp[n];
          if (e.typeEntity == typeEntity) {
            temp.removeAt(n);
            break;
          }
        }
        if (_epochForK(g, typeEntity) != myEpoch) {
          return untilExactlyK<T>(
            typeEntity,
            groupEntity: g,
            traverse: traverse,
          );
        }
        return getK<T>(typeEntity, groupEntity: g, traverse: traverse).unwrap();
      }).flatten();
    }
  }

  /// Stores completers for [untilExactlyK].
  final completersK = <Entity, List<ReservedSafeCompleter>>{};

  /// Tracks a per-(group, typeEntity) registration epoch. Bumped whenever a
  /// matching dependency is unregistered, used by [untilExactlyK] to detect
  /// stale completions across unregister/re-register cycles.
  final _epochsK = <Entity, Map<Entity, int>>{};

  int _epochForK(Entity groupEntity, Entity typeEntity) {
    return _epochsK[groupEntity]?[typeEntity] ?? 0;
  }

  /// Removes matching completers for [typeEntity] in [groupEntity] and bumps
  /// the registration epoch so any in-flight continuations re-wait instead of
  /// resolving against the now-gone registration.
  void cleanupCompleters(Entity typeEntity, {required Entity groupEntity}) {
    completersK[groupEntity]?.removeWhere((e) => e.typeEntity == typeEntity);
    final group = _epochsK[groupEntity] ??= {};
    group[typeEntity] = (group[typeEntity] ?? 0) + 1;
  }

  /// Attempts to finish any pending [untilExactlyK] calls for the given
  /// type and group.
  ///
  /// Matching is by `typeEntity` ONLY. An earlier version also OR-ed in
  /// `e is ReservedSafeCompleter<T>`, but under dart2js release that check
  /// can falsely match a completer of any type (generic-parameter erasure
  /// makes `is Foo<T>` collapse to `is Foo<dynamic>`), and as the first arm
  /// of the OR it would short-circuit `firstWhereOrNull` to the wrong
  /// completer. `typeEntity` is the canonical, minification-safe identifier
  /// — it's an integer hash of a string, not a reified generic.
  void maybeFinishK<T extends Object>({required Entity g}) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final typeEntity = TypeEntity(T);
    for (final di in [this as DI, ...children().unwrapOr([])]) {
      final test = di.completersK[g]?.firstWhereOrNull(
        (e) => e.typeEntity == typeEntity,
      );
      if (test != null) {
        test.complete(const None()).end();
        break;
      }
    }
  }
}
