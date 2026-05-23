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
import '../../_callback_result.dart';
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
  ///
  /// [visited] is for internal cycle-detection on misconfigured hierarchies
  /// (e.g. `a.parents.add(b)` and `b.parents.add(a)`). Callers should leave
  /// it null.
  Option<Result<Dependency<T>>> getDependencyK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    Set<DI>? visited,
  }) {
    final v = visited ?? <DI>{};
    if (!v.add(this as DI)) return const None();
    final g = groupEntity.preferOverDefault(focusGroup);
    final option = registry.getDependencyK(typeEntity, groupEntity: g);
    var temp = option.map((e) => Ok(e).transf<Dependency<T>>());
    if (option.isNone() && traverse) {
      for (final parent in parents) {
        temp = (parent as SupportsMixinK).getDependencyK(
          typeEntity,
          groupEntity: g,
          visited: v,
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

    // Walk the FULL ancestor chain (with cycle detection), matching the
    // depth of `isRegisteredK(traverse: true)`. See the corresponding fix
    // in [DIBase.unregister] for the symmetry rationale.
    final containers =
        traverse ? _allAncestorsK() : <DI>[this as DI];
    for (final di in containers) {
      final dependencyOption = di.removeDependencyK(typeEntity, groupEntity: g);
      if (dependencyOption.isNone()) {
        if (!removeAll) break;
        continue;
      }
      UNSAFE:
      removed.add(dependencyOption.unwrap());
      // Clean up matching completers on this container
      (di as SupportsMixinK).cleanupCompleters(typeEntity, groupEntity: g);
      if (!removeAll) break;
    }

    if (removed.isEmpty) return syncNone();

    // See `_di_base.dart::_runOnUnregisterChain` for why we can't use a plain
    // `firstResolvable.then(...)` outer wrapper here — `.then` short-circuits
    // on Err and would silently skip every onUnregister callback when the
    // dep's Resolvable resolved to Err.
    var chain = _firstResolvedToOptionK(removed.first);
    if (!triggerOnUnregisterCallbacks) return chain;
    for (final dep in removed) {
      final metaOpt = dep.metadata;
      if (metaOpt.isNone()) continue;
      UNSAFE:
      final cbOpt = metaOpt.unwrap().onUnregister;
      if (cbOpt.isNone()) continue;
      UNSAFE:
      final cb = cbOpt.unwrap();
      chain = _chainOnUnregisterStepK(chain, dep, cb);
    }
    return chain;
  }

  /// Sync/Async-aware adaptation of `_di_base::_firstResolvedToOption` for
  /// the un-typed K chain.
  Resolvable<Option> _firstResolvedToOptionK(Dependency dep) {
    final resolvable = dep.value;
    if (resolvable is Sync) {
      UNSAFE:
      final result = resolvable.value;
      if (result.isErr()) {
        return Sync<Option>.okValue(const None());
      }
      UNSAFE:
      return Sync<Option>.okValue(Some(result.unwrap()));
    }
    return Async<Option>(() async {
      final result = await resolvable.value;
      if (result.isErr()) return const None();
      UNSAFE:
      return Some(result.unwrap());
    });
  }

  /// Sync/Async-aware adaptation of `_di_base::_chainOnUnregisterStep` for
  /// the un-typed K chain.
  Resolvable<Option> _chainOnUnregisterStepK(
    Resolvable<Option> chain,
    Dependency dep,
    TOnUnregisterCallback<Object> cb,
  ) {
    if (chain is Sync<Option> && dep.value is Sync<Object>) {
      UNSAFE:
      final accResult = chain.value;
      if (accResult.isErr()) {
        return chain;
      }
      UNSAFE:
      final acc = accResult.unwrap();
      UNSAFE:
      final depResult = (dep.value as Sync<Object>).value;
      return _fireOnUnregisterK(cb, depResult, dep, acc);
    }
    return Async<Option>(() async {
      final accResult = await chain.value;
      if (accResult.isErr()) {
        UNSAFE:
        throw accResult.err().unwrap();
      }
      UNSAFE:
      final acc = accResult.unwrap();
      final depResult = await dep.value.value;
      final fireResult = await _fireOnUnregisterK(
        cb,
        depResult,
        dep,
        acc,
      ).value;
      if (fireResult.isErr()) {
        UNSAFE:
        throw fireResult.err().unwrap();
      }
      UNSAFE:
      return fireResult.unwrap();
    });
  }

  /// Same pattern as `_di_base.dart`'s `_fireOnUnregister`, specialised for
  /// the un-typed `Option` chain used by `unregisterK`. Sync throws are
  /// logged and the chain continues with [acc]; async errors propagate.
  Resolvable<Option> _fireOnUnregisterK(
    TOnUnregisterCallback<Object> cb,
    Result<Object> depResult,
    Dependency dep,
    Option acc,
  ) {
    final Object? cbResult;
    try {
      cbResult = cb(depResult);
    } catch (e) {
      Log.err(
        'onUnregister for ${dep.runtimeType} threw synchronously: $e',
      );
      return Sync<Option>.okValue(acc);
    }
    final FutureOr<void> awaited;
    try {
      awaited = awaitCallbackResult(
        cbResult,
        logAndSwallowSyncErr: true,
        logContext: 'onUnregister for ${dep.runtimeType}',
      );
    } catch (e) {
      Log.err('onUnregister for ${dep.runtimeType} surfaced sync error: $e');
      return Sync<Option>.okValue(acc);
    }
    if (awaited is Future) {
      final fut = awaited;
      return Async<Option>(() async {
        await fut;
        return acc;
      });
    }
    return Sync<Option>.okValue(acc);
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

  /// BFS walk of this container + every reachable ancestor through
  /// `.parents`, with cycle detection. Used by [unregisterK] to mirror the
  /// depth of [isRegisteredK].
  List<DI> _allAncestorsK() {
    final result = <DI>[this as DI];
    final visited = <DI>{this as DI};
    var i = 0;
    while (i < result.length) {
      final di = result[i];
      for (final parent in di.parents) {
        if (visited.add(parent)) {
          result.add(parent);
        }
      }
      i++;
    }
    return result;
  }

  /// Returns whether a dependency keyed under exact [typeEntity] is
  /// registered. Strict: a `Lazy<...>` variant is NOT matched — pass
  /// `TypeEntity(Lazy, [typeEntity])` explicitly to check for that.
  ///
  /// [visited] is for internal cycle-detection on misconfigured hierarchies.
  bool isRegisteredK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    Set<DI>? visited,
  }) {
    final v = visited ?? <DI>{};
    if (!v.add(this as DI)) return false;
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
          visited: v,
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
      // Look for an existing completer in THIS container OR any ancestor
      // (so concurrent waiters from different containers share one).
      ReservedSafeCompleter? completer;
      final searchScope = traverse ? _allAncestorsK() : <DI>[this as DI];
      for (final di in searchScope) {
        final found = (di as SupportsMixinK).completersK[g]?.firstWhereOrNull(
          (e) => e.typeEntity == typeEntity,
        );
        if (found != null) {
          completer = found;
          break;
        }
      }
      if (completer == null) {
        completer = ReservedSafeCompleter(typeEntity);
        (completersK[g] ??= []).add(completer);
        // Seed the completer into every ancestor so an ancestor's
        // `register<...>(..., enableUntilExactlyK: true)` (which only walks
        // its OWN `completersK`, not transitively into children) still
        // fires this waiter. Mirrors the `until` directional-asymmetry fix.
        if (traverse) {
          for (final ancestor in _allAncestorsK().skip(1)) {
            final mixinAncestor = ancestor as SupportsMixinK;
            (mixinAncestor.completersK[g] ??= []).add(completer);
          }
        }
      }
      return completer.resolvable().then((_) {
        // Remove the completer from THIS container AND every ancestor we
        // seeded above. Use identity-comparison so we don't accidentally
        // drop a different waiter that happens to share the same
        // typeEntity (e.g. a sibling waiter).
        final cleanupScope = traverse ? _allAncestorsK() : <DI>[this as DI];
        for (final di in cleanupScope) {
          (di as SupportsMixinK)
              .completersK[g]
              ?.removeWhere((e) => identical(e, completer));
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

  /// Alias for [untilExactlyK] that exists for naming-symmetry with the plain
  /// `untilSuper<T>` track. On the K (Entity-keyed) track there is no
  /// subtype-matching — Entities are looked up by equality — so "Super" here
  /// is purely an API-naming convenience: the registered dependency's
  /// `typeEntity` must equal the one passed in. Still requires
  /// `enableUntilExactlyK: true` at registration time.
  @pragma('vm:prefer-inline')
  Resolvable<T> untilSuperK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilExactlyK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Counterpart to `until<TSuper, TSub>` on the K (Entity-keyed) track.
  /// Waits exact-match on [typeEntity] (K is exact-only by design — see
  /// [untilSuperK]) and casts the resolved value to [TSub]. The compile-time
  /// `TSub extends TSuper` bound mirrors the plain API; at runtime it is a
  /// straight downcast through `.transf<TSub>()`. Requires
  /// `enableUntilExactlyK: true` at registration time.
  @pragma('vm:prefer-inline')
  Resolvable<TSub> untilK<TSuper extends Object, TSub extends TSuper>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilExactlyK<TSuper>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).transf<TSub>();
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
