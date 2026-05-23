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
import '../_callback_result.dart';
import '../_reserved_safe_completer.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Base class for the dependency injection container
base class DIBase {
  //
  //
  //

  /// Internal registry that stores dependencies.
  final registry = DIRegistry();

  /// Parent containers.
  final parents = <DI>{};

  /// A key that identifies the current group in focus for dependency management.
  Entity focusGroup = const DefaultEntity();

  int _indexIncrementer = 0;

  /// Container for child DI instances.
  Option<DI> childrenContainer = const None();

  /// Retrieves an iterable of child [DI] instances.
  ///
  /// Only returns **already-materialised** children. A `Lazy<DI>` whose
  /// `singleton` has never been read is skipped — otherwise iterating
  /// `children()` (called from `_maybeFinish` on every `register`) would
  /// force-construct every registered child container on every parent
  /// registration, defeating laziness and running child constructors at
  /// the wrong time.
  Option<Iterable<DI>> children() {
    UNSAFE:
    return childrenContainer.map(
      (e) => e.registry.unsortedDependencies.map((e) {
        try {
          final value = e.transf<Lazy<DI>>().value;
          if (value.isAsync()) return null;
          final lazyResult = value.sync().unwrap().value;
          if (lazyResult.isErr()) return null;
          final lazy = lazyResult.unwrap();
          // Skip lazies that haven't been materialised yet.
          // `currentInstance` is @protected because Lazy expects subclass-only
          // access for mutation; we only read it (no force-construct) to honor
          // the C7 contract that registering at a parent must not materialise
          // unrelated children. No public probe API exists.
          // ignore: invalid_use_of_protected_member
          if (lazy.currentInstance.isNone()) return null;
          // ignore: invalid_use_of_protected_member
          final resolvable = lazy.currentInstance.unwrap();
          if (resolvable.isAsync()) return null;
          final result = resolvable.sync().unwrap().value;
          if (result.isErr()) return null;
          return result.unwrap();
        } catch (_) {
          return null;
        }
      }).nonNulls,
    );
  }

  //
  //
  //

  /// Registers a dependency with the container.
  Resolvable<T> register<T extends Object>(
    FutureOr<T> value, {
    Option<TOnRegisterCallback<T>> onRegister = const None(),
    Option<TOnUnregisterCallback<T>> onUnregister = const None(),
    Entity groupEntity = const DefaultEntity(),
    bool enableUntilExactlyK = false,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final g = groupEntity.preferOverDefault(focusGroup);
    final metadata = DependencyMetadata(
      index: Some(_indexIncrementer++),
      groupEntity: g,
      onUnregister: onUnregister.map((cb) => (e) => cb(e.transf())),
    );
    // Wrap the onRegister invocation so that a synchronous throw is
    // captured into the Resolvable instead of escaping out of `register()`.
    // Without this, a sync-throwing onRegister blows the call stack
    // mid-`register` and the caller has no Resolvable-shaped handle to the
    // failure — unacceptable for medical-grade code where every callback
    // site must be uniformly catchable.
    final a = Resolvable(
      () => consec(value, (e) {
        return consec(_safeOnRegister<T>(onRegister, e), (_) => e);
      }),
    );
    final b = registerDependency<T>(
      dependency: Dependency(a, metadata: Some(metadata)),
      checkExisting: true,
    );
    UNSAFE:
    {
      if (b.isErr()) {
        return Sync.err(b.err().unwrap().transfErr<T>());
      }
      if (value is! ReservedSafeCompleter<T>) {
        // Used for until.
        // NOTE: CHANGED FROM T TO Object so that it attems to finish ANY ReservedSafeFinisher!
        _maybeFinish<Object>(value: value, g: g);

        // Used for untilT and untilK. Disabled by default to improve performance.
        if (enableUntilExactlyK) {
          (this as SupportsMixinK).maybeFinishK<T>(g: g);
        }
      }
      return get<T>(groupEntity: groupEntity).unwrap();
    }
  }

  /// Invokes [onRegister] (if present) on [value], converting any synchronous
  /// throw into a `Future.error` so the surrounding Resolvable/consec chain
  /// routes it through the standard error path. Extracted from `register()`
  /// so the FutureOr-assignment plumbing sits outside the `@mustAwaitAllFutures`
  /// Resolvable callback.
  ///
  /// The callback signature is `FutureOr<void> Function(T)`, but it is
  /// ergonomic in practice to write `(s) => s.init()` where `init()` returns
  /// a `Resolvable<Unit>`. `Resolvable` is neither a `Future` nor `void` — if
  /// we treated such a return as sync, the `untilSuper` waiter would resolve
  /// against a half-initialized service, defeating the C6 contract for the
  /// ergonomic form. To close that hole we explicitly detect a `Resolvable`
  /// return and unwrap its `.value`.
  FutureOr<void> _safeOnRegister<T extends Object>(
    Option<TOnRegisterCallback<T>> onRegister,
    T value,
  ) {
    try {
      // Capture the callback's return as `Object?` (NOT `FutureOr<void>`) so
      // `awaitCallbackResult` can dispatch on the runtime type (a `void`
      // static type would reject further use).
      final Object? result = switch (onRegister) {
        Some(value: final cb) => cb(value),
        None() => null,
      };
      // For onRegister, ANY failure must surface as Err on the resulting
      // Resolvable — a half-registered service is unacceptable for
      // medical-grade callers — so do NOT log-and-swallow sync errors here.
      return awaitCallbackResult(
        result,
        logAndSwallowSyncErr: false,
        logContext: 'onRegister<$T>',
      );
    } catch (err, st) {
      return Future<void>.error(err, st);
    }
  }

  /// Attempts to finish any pending [until] calls for the given type and
  /// group when a new dependency is registered.
  ///
  /// Previously this relied on `.whereType<ReservedSafeCompleter<T>>()` and a
  /// `value as FutureOr<T>` cast to filter to the correct completer. Both of
  /// those generic-reification-dependent checks are silently weakened in
  /// dart2js release mode on Flutter Web: a completer of the *wrong* type is
  /// matched, `.complete(value)` silently succeeds (passing a garbage-typed
  /// value), `break` exits, and the correct completer is never reached. The
  /// original `until*` call hangs forever. See
  /// `ReservedSafeCompleter.typeCheck` for the design trade-off.
  ///
  /// The fix: iterate every `ReservedSafeCompleter` regardless of its type
  /// parameter, then use the completer's `typeCheck` closure (captured when
  /// the completer was constructed and `T` was lexically in scope) to
  /// decide whether `value` is assignable to it. That closure is compiled
  /// into a real type predicate by dart2js and survives release-mode
  /// optimisation.
  void _maybeFinish<T extends Object>({
    required FutureOr<Object> value, // General "Object"
    required Entity g,
  }) {
    // The typeCheck predicate needs a non-Future Object to evaluate. If the
    // registered value is itself a Future, we fall back to the original
    // try/cast dance — that path works correctly on the VM and in debug
    // web, and it's vanishingly rare in practice (registering a Future as
    // a dependency value, not wrapping it in a completer).
    //
    // NOTE: under dart2js release, this Future-fallback path can mis-match
    // due to generic erasure of `T`. Callers who register a Future-valued
    // dependency and rely on `until*` on Web release should wrap the value
    // in a non-Future container (or use a completer) until this fallback
    // is replaced with a deferred-resolution scheme.
    final checkValue = value is Future ? null : value;

    for (final di in [this as DI, ...children().unwrapOr([])]) {
      UNSAFE:
      final completers = di.registry.state[g]?.values
          .map((e) => e.value)
          .where((e) => e.isSync())
          .map((e) => e.sync().unwrap().value)
          .where((e) => e.isOk())
          .map((e) => e.unwrap())
          // Match ANY ReservedSafeCompleter — we intentionally DON'T filter
          // on `<T>` here because dart2js release makes generic parameter
          // matching unreliable. The typeCheck below does the real filter.
          .whereType<ReservedSafeCompleter>();
      if (completers == null) continue;

      for (final completer in completers) {
        if (checkValue != null) {
          // Fast, reliable path: the completer knows its own T.
          if (!completer.typeCheck(checkValue)) continue;
          if (!completer.isCompleted) {
            completer.complete(value).end();
            break;
          }
        } else {
          // Future value — preserve the original behaviour. See note above.
          try {
            (completer as ReservedSafeCompleter<T>)
                .complete(value as FutureOr<T>)
                .end();
            break;
          } on TypeError {
            // Skip completers whose type T doesn't accept this value.
          } on StateError {
            // Skip already-completed completers.
          }
        }
      }
    }
  }

  /// Registers a [Dependency] object directly into the registry.
  Result<Dependency<T>> registerDependency<T extends Object>({
    required Dependency<T> dependency,
    bool checkExisting = false,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    UNSAFE:
    final g = dependency.metadata.isSome()
        ? dependency.metadata.unwrap().groupEntity
        : focusGroup;
    if (checkExisting) {
      final option = getDependency<T>(groupEntity: g, traverse: false);
      if (option.isSome()) {
        return Err('Dependency already registered.');
      }
    }
    registry.setDependency(dependency);
    return Ok(dependency);
  }

  /// Unregisters a dependency.
  ///
  /// Honors the documented contract:
  ///
  /// * If `traverse` is `false`, parents are not walked. Only this container
  ///   is touched.
  /// * If `removeAll` is `true` (the default), the dependency is removed from
  ///   this container *and* every parent that has a matching registration.
  ///   When `false`, only the first matching registration (this-first,
  ///   parent-walk thereafter) is removed.
  /// * If `triggerOnUnregisterCallbacks` is `true`, **every** removed
  ///   dependency's `onUnregister` callback fires (sequentially, in
  ///   container-walk order). Returns once all callbacks have completed.
  ///
  /// The returned `Option<T>` is the value of the first removed dependency
  /// (or `None` if nothing was removed).
  Resolvable<Option<T>> unregister<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    bool removeAll = true,
    bool triggerOnUnregisterCallbacks = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final g = groupEntity.preferOverDefault(focusGroup);
    final removed = <Dependency>[];

    final containers = traverse ? [this as DI, ...parents] : [this as DI];
    for (final di in containers) {
      final dependencyOption = di.removeDependency<T>(groupEntity: g);
      if (dependencyOption.isNone()) {
        if (!removeAll) break;
        continue;
      }
      UNSAFE:
      removed.add(dependencyOption.unwrap());
      // Clean up any pending untilExactlyK completers for this type.
      (di as SupportsMixinK).cleanupCompleters(
        TypeEntity(T),
        groupEntity: g,
      );
      if (!removeAll) break;
    }

    if (removed.isEmpty) return Sync.okValue(None<T>());

    return _runOnUnregisterChain<T>(
      removed: removed,
      triggerOnUnregisterCallbacks: triggerOnUnregisterCallbacks,
    );
  }

  /// Fires `onUnregister` for every entry in [removed] (in order), then
  /// resolves with the value of the first removed dependency. Medical-grade
  /// callers cannot afford silently-dropped cleanup callbacks, so every
  /// removed dep's callback runs — synchronous throws are logged and the
  /// chain continues.
  Resolvable<Option<T>> _runOnUnregisterChain<T extends Object>({
    required List<Dependency> removed,
    required bool triggerOnUnregisterCallbacks,
  }) {
    final firstResolvable = removed.first.transf<T>().value;
    return firstResolvable.then((first) {
      if (!triggerOnUnregisterCallbacks) {
        return Sync<Option<T>>.okValue(Some(first));
      }
      Resolvable<Option<T>> chain = Sync<Option<T>>.okValue(Some(first));
      for (final dep in removed) {
        final metaOpt = dep.metadata;
        if (metaOpt.isNone()) continue;
        UNSAFE:
        final cbOpt = metaOpt.unwrap().onUnregister;
        if (cbOpt.isNone()) continue;
        UNSAFE:
        final cb = cbOpt.unwrap();
        final depValue = dep.value;
        chain = chain
            .then(
              (acc) => depValue
                  .then(
                    (resolvedDepValue) => _fireOnUnregister<T>(
                      cb,
                      resolvedDepValue,
                      dep,
                      acc,
                    ),
                  )
                  .flatten(),
            )
            .flatten();
      }
      return chain;
    }).flatten();
  }

  /// Fires a single `onUnregister` callback and resolves to [acc] regardless
  /// of whether the callback succeeded, failed synchronously (logged), or
  /// errored asynchronously (propagated).
  ///
  /// Extracted so the outer chain can stay free of `FutureOr<Outcome>` types
  /// — the `must_await_all_futures` / `no_future_outcome_type_or_error` lints
  /// only visit annotated callback bodies, and this helper sits outside any
  /// such annotation.
  Resolvable<Option<T>> _fireOnUnregister<T extends Object>(
    TOnUnregisterCallback<Object> cb,
    Object resolvedDepValue,
    Dependency dep,
    Option<T> acc,
  ) {
    final Object? cbResult;
    try {
      cbResult = cb(Ok(resolvedDepValue));
    } catch (e) {
      Log.err(
        'onUnregister for ${dep.runtimeType} threw synchronously: $e',
      );
      return Sync<Option<T>>.okValue(acc);
    }
    // For onUnregister we follow the documented contract: sync failures are
    // logged and the chain continues; async failures propagate. The helper
    // honours both shapes (Future / Resolvable) and the logSyncErr flag.
    final FutureOr<void> awaited;
    try {
      awaited = awaitCallbackResult(
        cbResult,
        logAndSwallowSyncErr: true,
        logContext: 'onUnregister for ${dep.runtimeType}',
      );
    } catch (e) {
      // Sync `throw v` from the helper only fires when
      // logAndSwallowSyncErr=false; for unregister it stays a no-op.
      Log.err('onUnregister for ${dep.runtimeType} surfaced sync error: $e');
      return Sync<Option<T>>.okValue(acc);
    }
    if (awaited is Future) {
      final fut = awaited;
      return Async<Option<T>>(() async {
        await fut;
        return acc;
      });
    }
    return Sync<Option<T>>.okValue(acc);
  }

  /// Removes a dependency from the internal registry.
  @pragma('vm:prefer-inline')
  Option<Dependency> removeDependency<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final g = groupEntity.preferOverDefault(focusGroup);
    final result = registry.removeDependency<T>(groupEntity: g);
    if (result.isSome() && this is SupportsMixinK) {
      (this as SupportsMixinK).cleanupCompleters(
        TypeEntity(T),
        groupEntity: g,
      );
    }
    return result;
  }

  /// Returns whether a dependency keyed under exact type [T] is registered in
  /// [groupEntity]. Strict: a `Lazy<T>` registration does NOT count here —
  /// callers wanting that must check `isRegistered<Lazy<T>>()`. Mirrors the
  /// keying contract of the registry's insert/remove.
  bool isRegistered<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final g = groupEntity.preferOverDefault(focusGroup);
    if (registry.containsDependency<T>(groupEntity: g)) {
      return true;
    }
    if (traverse) {
      for (final parent in parents) {
        if (parent.isRegistered<T>(groupEntity: g, traverse: true)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Retrieves a synchronous dependency.
  Option<Sync<T>> getSync<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    UNSAFE:
    return get<T>(groupEntity: groupEntity, traverse: traverse).map(
      (e) => e.isSync()
          ? e.sync().unwrap()
          : Sync.err(Err('Called getSync() for an async dependency.')),
    );
  }

  @pragma('vm:prefer-inline')
  T call<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    return getSyncUnsafe<T>(groupEntity: groupEntity, traverse: traverse);
  }

  /// Retrieves a synchronous dependency.
  @pragma('vm:prefer-inline')
  T getSyncUnsafe<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    UNSAFE:
    return getSync<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().value.unwrap();
  }

  @pragma('vm:prefer-inline')
  Option<Async<T>> getAsync<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    return get<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.toAsync());
  }

  /// Retrieves an asynchronous dependency unsafely, returning a future of the
  /// instance or throwing an error if not found.
  @pragma('vm:prefer-inline')
  Future<T> getAsyncUnsafe<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    UNSAFE:
    return Future.sync(() async {
      final result = await getAsync<T>(
        groupEntity: groupEntity,
        traverse: traverse,
      ).unwrap().value;
      return result.unwrap();
    });
  }

  /// Retrieves a synchronous dependency or `None` if not found or async.
  Option<T> getSyncOrNone<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final option = get<T>(groupEntity: groupEntity, traverse: traverse);
    switch (option) {
      case Some(value: final resolvable):
        switch (resolvable) {
          case Sync(value: final result):
            switch (result) {
              case Ok(value: final value):
                return Some(value);
              default:
            }
          default:
        }
      default:
    }
    return const None();
  }

  // NOTE: This is another method aimed to optimize get but there's a bug and it
  // doesn't properly re-registers the dependency.
  /// Retrieves a dependency from the container.
  // Option<Resolvable<T>> get<T extends Object>({
  //   Entity groupEntity = const DefaultEntity(),
  //   bool traverse = true,
  // }) {
  //   assert(T != Object, 'T must be specified and cannot be Object.');
  //   final g = groupEntity.preferOverDefault(focusGroup);
  //   final option = getDependency<T>(groupEntity: g, traverse: traverse);
  //   if (option.isNone()) {
  //     return const None();
  //   }
  //   final result = option.unwrap();
  //   if (result.isErr()) {
  //     return Some(Sync.value(result.err().unwrap().transfErr()));
  //   }
  //   final dependency = result.unwrap();
  //   if (dependency.value.isSync()) {
  //     return Some(dependency.value);
  //   }
  //   return Some(dependency.cacheAsyncValue());
  // }

  /// Retrieves a dependency from the container.
  Option<Resolvable<T>> get<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final g = groupEntity.preferOverDefault(focusGroup);
    final option = getDependency<T>(groupEntity: g, traverse: traverse);
    if (option.isNone()) {
      return const None();
    }
    UNSAFE:
    {
      final result = option.unwrap();
      if (result.isErr()) {
        return Some(Sync.err(result.err().unwrap().transfErr()));
      }
      final dependency = result.unwrap();
      final value = dependency.value;
      if (value.isSync()) {
        return Some(value);
      }
      return Some(
        Async(
          () => value.async().unwrap().value.then((e) {
            final value = e.unwrap();
            registry.removeDependency<T>(groupEntity: g).unwrap();
            registerDependency<T>(
              dependency: Dependency<T>(
                Sync.okValue(value),
                metadata: option.unwrap().unwrap().metadata,
              ),
              checkExisting: false,
            ).unwrap();
            return value;
          }),
        ),
      );
    }
  }

  /// Retrieves a dependency unsafely, returning the instance or a future of it,
  /// or throwing an error if not found.
  @pragma('vm:prefer-inline')
  FutureOr<T> getUnsafe<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    UNSAFE:
    return get<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().unwrap();
  }

  /// Retrieves the underlying `Dependency` object from the registry.
  Option<Result<Dependency<T>>> getDependency<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final option = registry.getDependency<T>(groupEntity: g);
    var temp = option.map((e) => Ok(e).transf<Dependency<T>>());
    if (option.isNone() && traverse) {
      for (final parent in parents) {
        temp = parent.getDependency<T>(groupEntity: g);
        if (temp.isSome()) {
          break;
        }
      }
    }
    return temp;
  }

  /// Waits until a dependency of type `TSuper` is registered. `TSuper` should
  /// typically be the most general type expected.
  @pragma('vm:prefer-inline')
  Resolvable<TSuper> untilSuper<TSuper extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return until<TSuper, TSuper>(groupEntity: groupEntity, traverse: traverse);
  }

  /// Waits until a dependency of type `TSuper` or its subtype `TSub` is
  /// registered. `TSuper` should typically be the most general type expected.
  Resolvable<TSub> until<TSuper extends Object, TSub extends TSuper>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final typeEntity = TypeEntity(TSuper);
    final g = groupEntity.preferOverDefault(focusGroup);
    final test = get<TSuper>(groupEntity: g, traverse: traverse);
    UNSAFE:
    {
      if (test.isSome()) {
        return test.unwrap().transf();
      }
      final temp = getSyncOrNone<ReservedSafeCompleter<TSuper>>(
        groupEntity: g,
        traverse: traverse,
      );
      final completer = switch (temp) {
        Some(value: final c) => c,
        None() => () {
            final c = ReservedSafeCompleter<TSuper>(typeEntity);
            register(c, groupEntity: g).end();
            return c;
          }(),
      };
      return completer
          .resolvable()
          .then((_) {
            unregister<ReservedSafeCompleter<TSuper>>(
              groupEntity: g,
              traverse: traverse,
            ).end();
            return get<TSuper>(groupEntity: g, traverse: traverse).unwrap();
          })
          .flatten()
          .transf();
    }
  }

  //
  //
  //

  /// Completes once all [Async] dependencies associated with [groupEntity]
  /// complete, or every group when [groupEntity] is [None].
  Resolvable<Unit> resolveAll({
    Option<Entity> groupEntity = const Some(DefaultEntity()),
  }) {
    UNSAFE:
    return Resolvable(() {
      var resolvables = registry.unsortedDependencies;
      if (groupEntity case Some(value: final g)) {
        resolvables = resolvables.where(
          (e) => switch (e.metadata) {
            Some(value: final m) => m.groupEntity == g,
            None() => false,
          },
        );
      }
      final values = resolvables.map((e) => e.value);
      if (values.any((e) => e is Async)) {
        return wait(
          resolvables.map((e) => e.value.unwrap()),
          (_) => resolveAll(groupEntity: groupEntity).toUnit().unwrap(),
        );
      }
      return Unit();
    });
  }
}
