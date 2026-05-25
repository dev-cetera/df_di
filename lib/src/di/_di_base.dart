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

/// Base class for the dependency injection container. Holds the [registry],
/// the parent links used by `traverse`, and the [focusGroup] that scopes
/// `groupEntity`-defaulted calls. The concrete [DI] class layers the public
/// `Supports*` mixins on top.
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
  ///
  /// The result is **snapshotted** via `.toList()` so callers can safely
  /// iterate even if a re-entrant register/unregister mutates the underlying
  /// registry mid-walk. Without the snapshot, `_maybeFinish` (which iterates
  /// `children()` on every register) would throw `ConcurrentModificationError`
  /// if any onRegister callback registered another dep on the same container.
  Option<Iterable<DI>> children() {
    return childrenContainer.map(
      (e) => e.registry.unsortedDependencies
          .toList(growable: false)
          .map(_childFromDep)
          .nonNulls,
    );
  }

  /// Pattern-matches a single registry entry down to its materialised `DI`
  /// instance, returning `null` for any branch that should be skipped (async,
  /// unmaterialised, errored). Pattern matching makes every "skip" path
  /// explicit and exhaustive — no chance of an accidental `.unwrap()` on an
  /// Err or async slot.
  DI? _childFromDep(Dependency e) {
    try {
      return switch (e.transf<Lazy<DI>>().value) {
        Sync(value: Ok(value: final lazy)) => _materialisedDI(lazy),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }

  /// Reads a `Lazy<DI>`'s already-materialised singleton without forcing
  /// construction. `currentInstance` is `@protected` because Lazy expects
  /// subclass-only mutation, but a read-only probe is the only safe way to
  /// honor the C7 contract that registering at a parent must not
  /// materialise unrelated children.
  // ignore: invalid_use_of_protected_member
  DI? _materialisedDI(Lazy<DI> lazy) => switch (lazy.currentInstance) {
        Some(value: Sync(value: Ok(value: final di))) => di,
        _ => null,
      };

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
    assert(
      value is! Future || T != FutureOr,
      'register<$T>: registering a Future where T is FutureOr is ambiguous. '
      'Use Resolvable<T> or unwrap the Future before registering.',
    );
    final g = groupEntity.preferOverDefault(focusGroup);

    // Existence check FIRST. If a slot for [T] already exists in this
    // container's [g] group, reject the registration BEFORE constructing
    // the wrapping Resolvable — building it runs the `onRegister` side
    // effects (init() etc.), and we must NOT run those for a registration
    // we'll reject (audit-pass-3 finding: previously a duplicate-register
    // call fired init() on a service that would never be reachable,
    // leaking the resource).
    switch (getDependency<T>(groupEntity: g, traverse: false)) {
      case Some():
        return Sync<T>.err(Err('Dependency already registered.'));
      case None():
        break;
    }

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
      // Slot was already free-checked above; skip the redundant probe.
      checkExisting: false,
    );
    switch (b) {
      case Err<Dependency<T>> err:
        return Sync.err(err.transfErr<T>());
      case Ok():
        break;
    }
    if (value is! ReservedSafeCompleter<T>) {
      // Used for until*. Walks ANY pending ReservedSafeCompleter (regardless
      // of its type parameter) and lets each completer's own captured
      // type-check decide whether `value` matches — see `_maybeFinish` for
      // why filtering by `<T>` here is unsafe under dart2js release.
      _maybeFinish<Object>(value: value, g: g);

      // Used for untilT and untilK. Disabled by default to improve performance.
      if (enableUntilExactlyK) {
        (this as SupportsMixinK).maybeFinishK<T>(g: g);
      }
    }
    // We just succeeded at `registerDependency` above, so `get<T>` MUST find
    // the slot we wrote. Pattern-match instead of `.unwrap()` so the
    // theoretical "should never happen" branch is explicit: if a concurrent
    // unregister somehow raced and wiped the slot, return an Err Resolvable
    // instead of throwing — callers awaiting the returned Resolvable then
    // see a normal Err on their chain.
    return switch (get<T>(groupEntity: groupEntity)) {
      Some(value: final r) => r,
      None() => Sync<T>.err(
          Err('register<$T>: post-register lookup returned None '
              '(slot was concurrently removed).'),
        ),
    };
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
      // Walk this container's deps and pull out every Ok-Sync-resolved
      // `ReservedSafeCompleter` via pattern matching. The destructuring
      // means we never call `.unwrap()` on an Err or an Async dep —
      // those branches are filtered structurally.
      //
      // We intentionally DON'T filter on `ReservedSafeCompleter<T>` here
      // because dart2js release makes generic-parameter matching
      // unreliable. The completer's own `typeCheck` does the real filter.
      //
      // Use the internal `groupSlots` accessor here, NOT `state[g]?.values`.
      // The public `state` getter deep-copies the entire registry (which is
      // its documented safety contract for external callers); doing that on
      // every `register` allocates O(N-groups + N-deps) per call. The
      // internal accessor still snapshots the ONE group we care about (so
      // re-entrant register/unregister inside a completer chain cannot
      // throw `ConcurrentModificationError`), but skips the outer copy.
      final slots = di.registry.groupSlots(g);
      if (slots == null) continue;
      final completers = slots
          .map(
            (e) => switch (e.value) {
              Sync(value: Ok(value: final v)) when v is ReservedSafeCompleter =>
                v,
              _ => null,
            },
          )
          .whereType<ReservedSafeCompleter>();

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
    final g = switch (dependency.metadata) {
      Some(value: final m) => m.groupEntity,
      None() => focusGroup,
    };
    if (checkExisting) {
      switch (getDependency<T>(groupEntity: g, traverse: false)) {
        case Some():
          return Err('Dependency already registered.');
        case None():
          break;
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

    // Walk the FULL ancestor chain (with cycle detection) — not just direct
    // parents — so `unregister(traverse: true, removeAll: true)` and
    // `isRegistered(traverse: true)` agree on which deps exist. Previously
    // `unregister` only touched `this` and direct parents, so a grandparent
    // registration that `isRegistered` could see would survive a deep
    // unregister — a real reliability hole on three-level hierarchies.
    final containers = traverse ? _allAncestors() : <DI>[this as DI];
    walk:
    for (final di in containers) {
      switch (di.removeDependency<T>(groupEntity: g)) {
        case Some(value: final dep):
          removed.add(dep);
          // Clean up any pending untilExactlyK completers for this type.
          // The cast is guarded because DIBase itself does NOT require
          // SupportsMixinK — only the concrete `DI` mixes it in.
          (di as SupportsMixinK).cleanupCompleters(
            TypeEntity(T),
            groupEntity: g,
          );
          if (!removeAll) break walk;
        case None():
          if (!removeAll) break walk;
      }
    }

    if (removed.isEmpty) return Sync.okValue(None<T>());

    return _runOnUnregisterChain<T>(
      removed: removed,
      triggerOnUnregisterCallbacks: triggerOnUnregisterCallbacks,
    );
  }

  /// Returns this container followed by every reachable ancestor via the
  /// `.parents` graph, in BFS order. Skips already-visited nodes so cycles
  /// terminate.
  List<DI> _allAncestors() {
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

  /// Fires `onUnregister` for every entry in [removed] (in order), then
  /// resolves with the value of the first removed dependency. Medical-grade
  /// callers cannot afford silently-dropped cleanup callbacks, so every
  /// removed dep's callback runs — synchronous throws are logged and the
  /// chain continues.
  Resolvable<Option<T>> _runOnUnregisterChain<T extends Object>({
    required List<Dependency> removed,
    required bool triggerOnUnregisterCallbacks,
  }) {
    // Convert the first removed dep's resolved value to Option<T>: Ok → Some,
    // Err → None. We CANNOT use `firstResolvable.then(...)` here because
    // `Async.then` short-circuits on Err — the chain would silently skip
    // every onUnregister callback whenever the dep's value resolved to Err
    // (e.g. a Future-valued registration that rejected). Mission-critical
    // callers register onUnregister precisely to clean up such failures, so
    // we explicitly walk the Result.
    final firstDep = removed.first.transf<T>();
    var chain = _firstResolvedToOption<T>(firstDep);

    if (!triggerOnUnregisterCallbacks) {
      return chain;
    }

    for (final dep in removed) {
      // Skip deps with no metadata or no onUnregister cb. Pattern matching
      // makes both "skip" paths structural — no unwraps on a None.
      if (dep.metadata case Some(value: final meta)) {
        if (meta.onUnregister case Some(value: final cb)) {
          chain = _chainOnUnregisterStep<T>(chain, dep, cb);
        }
      }
    }
    return chain;
  }

  /// Resolves a single dep's `Resolvable<T>` to `Option<T>`: `Ok(v)` → `Some(v)`,
  /// `Err` → `None`. Preserves the Sync fast-path. Exhaustive pattern
  /// matching makes every Resolvable × Result combination explicit.
  Resolvable<Option<T>> _firstResolvedToOption<T extends Object>(
    Dependency<T> dep,
  ) {
    return switch (dep.value) {
      Sync<T>(value: Ok(value: final v)) => Sync<Option<T>>.okValue(Some(v)),
      Sync<T>() => Sync<Option<T>>.okValue(const None()),
      Async<T>(value: final fut) => Async<Option<T>>(() async {
          return switch (await fut) {
            Ok(value: final v) => Some(v),
            Err() => None<T>(),
          };
        }),
    };
  }

  /// Chains an `onUnregister` step onto [chain]. The callback fires with the
  /// dep's resolved `Result` (Ok or Err) — callers must clean up on both
  /// success and failure. Preserves the Sync fast-path.
  Resolvable<Option<T>> _chainOnUnregisterStep<T extends Object>(
    Resolvable<Option<T>> chain,
    Dependency dep,
    TOnUnregisterCallback<Object> cb,
  ) {
    // Sync fast-path: only fire when BOTH the running chain and the dep's
    // value are synchronous. Pattern-match both at once so the Err branch
    // is encoded structurally, not via .isErr/.unwrap.
    if (chain case Sync<Option<T>>(value: final accResult)) {
      if (dep.value case Sync<Object>(value: final depResult)) {
        return switch (accResult) {
          Err() => chain,
          Ok(value: final acc) => _fireOnUnregister<T>(cb, depResult, dep, acc),
        };
      }
    }
    // Async path — explicit await to get both Results, then fire cb.
    return Async<Option<T>>(() async {
      final acc = switch (await chain.value) {
        Err<Option<T>> err => throw err,
        Ok<Option<T>>(value: final v) => v,
      };
      final depResult = await dep.value.value;
      return switch (
          await _fireOnUnregister<T>(cb, depResult, dep, acc).value) {
        Err<Option<T>> err => throw err,
        Ok<Option<T>>(value: final v) => v,
      };
    });
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
    Result<Object> depResult,
    Dependency dep,
    Option<T> acc,
  ) {
    final Object? cbResult;
    try {
      cbResult = cb(depResult);
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
    if (awaited case final Future<void> fut) {
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
    if (result case Some()) {
      if (this case final SupportsMixinK k) {
        k.cleanupCompleters(TypeEntity(T), groupEntity: g);
      }
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
    Set<DI>? visited,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    // Cycle guard: a misconfigured hierarchy (`a.parents.add(b)` and
    // `b.parents.add(a)`) would otherwise stack-overflow. The `visited`
    // parameter is internal — public callers should leave it null.
    final v = visited ?? <DI>{};
    if (!v.add(this as DI)) return false;
    final g = groupEntity.preferOverDefault(focusGroup);
    if (registry.containsDependency<T>(groupEntity: g)) {
      return true;
    }
    if (traverse) {
      for (final parent in parents) {
        if (parent.isRegistered<T>(
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

  /// Retrieves a synchronous dependency.
  Option<Sync<T>> getSync<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    return get<T>(groupEntity: groupEntity, traverse: traverse).map(
      (e) => switch (e) {
        Sync<T>() => e,
        Async<T>() =>
          Sync.err(Err('Called getSync() for an async dependency.')),
      },
    );
  }

  /// Shorthand for [getSyncUnsafe]: `di<MyService>()` returns the registered
  /// `MyService` synchronously or throws if missing / async-only.
  @pragma('vm:prefer-inline')
  T call<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    return getSyncUnsafe<T>(groupEntity: groupEntity, traverse: traverse);
  }

  /// Retrieves a synchronous dependency, returning the value directly. Throws
  /// if the dependency is missing, async-only, or resolved to `Err`.
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

  /// Retrieves a dependency as `Async<T>` regardless of whether it was
  /// registered synchronously or asynchronously, or `None` if not found.
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
  /// Single exhaustive pattern collapses the Option × Resolvable × Result
  /// state space — every "not found / not sync / not ok" branch falls into
  /// the wildcard, so we can't accidentally return a partial value.
  Option<T> getSyncOrNone<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    return switch (get<T>(groupEntity: groupEntity, traverse: traverse)) {
      Some(value: Sync(value: Ok(value: final v))) => Some(v),
      _ => const None(),
    };
  }

  /// Retrieves a dependency from the container.
  Option<Resolvable<T>> get<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final g = groupEntity.preferOverDefault(focusGroup);
    final option = getDependency<T>(groupEntity: g, traverse: traverse);
    // Outer pattern: collapse the Option<Result<Dependency<T>>>. Each branch
    // is structural — no .unwrap() on a None or Err sits between us and the
    // dependency.
    return switch (option) {
      None() => const None(),
      Some(value: Err(:final error, :final stackTrace)) => Some(
          Sync<T>.err(Err<T>(error, stackTrace: stackTrace)),
        ),
      Some(value: Ok(value: final dep)) => switch (dep.value) {
          Sync<T>() => Some(dep.value),
          Async<T>(value: final fut) => Some(
              Async<T>(
                () => fut.then((e) {
                  // If the async slot resolved to Err, propagate by throwing —
                  // the surrounding `Async()` constructor absorbs the throw
                  // into an Err Result on its own value.
                  final value = switch (e) {
                    Ok(value: final v) => v,
                    Err(:final error, :final stackTrace) =>
                      throw Err<T>(error, stackTrace: stackTrace),
                  };
                  // Replace the Async slot with a Sync slot holding the
                  // resolved value (memoisation). The remove may already
                  // be a no-op if a concurrent unregister won the race; the
                  // re-register skips its dup-check by design.
                  registry.removeDependency<T>(groupEntity: g).end();
                  switch (registerDependency<T>(
                    dependency: Dependency<T>(
                      Sync<T>.okValue(value),
                      metadata: dep.metadata,
                    ),
                    checkExisting: false,
                  )) {
                    case Ok():
                      break;
                    case Err(:final error):
                      // Should be unreachable with checkExisting: false; if it
                      // still fires we surface the cause rather than silently
                      // returning the resolved value with stale registry state.
                      throw error;
                  }
                  return value;
                }),
              ),
            ),
        },
    };
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
  ///
  /// [visited] is for internal cycle-detection — see [isRegistered].
  Option<Result<Dependency<T>>> getDependency<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    Set<DI>? visited,
  }) {
    final v = visited ?? <DI>{};
    if (!v.add(this as DI)) return const None();
    final g = groupEntity.preferOverDefault(focusGroup);
    final option = registry.getDependency<T>(groupEntity: g);
    var temp = option.map((e) => Ok(e).transf<Dependency<T>>());
    if (option case None() when traverse) {
      for (final parent in parents) {
        temp = parent.getDependency<T>(
          groupEntity: g,
          visited: v,
        );
        if (temp case Some()) {
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
    // Already-registered fast path: bail out with the resolved Resolvable.
    if (get<TSuper>(groupEntity: g, traverse: traverse)
        case Some(value: final r)) {
      return r.transf();
    }
    final completer = switch (getSyncOrNone<ReservedSafeCompleter<TSuper>>(
      groupEntity: g,
      traverse: traverse,
    )) {
      Some(value: final c) => c,
      None() => _seedCompleter<TSuper>(typeEntity, g, traverse),
    };
    return completer
        .resolvable()
        .then((_) {
          unregister<ReservedSafeCompleter<TSuper>>(
            groupEntity: g,
            traverse: traverse,
          ).end();
          // The completer was resolved because `_maybeFinish` saw a matching
          // register — so `get<TSuper>` should find it. If a concurrent
          // unregister wiped the slot between completion and now, surface an
          // Err Resolvable instead of throwing — callers chained off the
          // outer `.flatten().transf()` then see a normal failure.
          return switch (get<TSuper>(groupEntity: g, traverse: traverse)) {
            Some(value: final r) => r,
            None() => Sync<TSuper>.err(
                Err('until<$TSuper>: completer resolved but post-resolution '
                    'lookup returned None (raced with unregister).'),
              ),
          };
        })
        .flatten()
        .transf();
  }

  /// Constructs a fresh [ReservedSafeCompleter] keyed on [typeEntity] under
  /// [g], registers it here, and (when [traverse]) seeds the SAME instance
  /// into every ancestor that doesn't already carry one. Extracted from
  /// `until` so the caller stays a single `switch` expression — the
  /// fall-through control flow is what made the previous form hard to audit.
  ReservedSafeCompleter<TSuper> _seedCompleter<TSuper extends Object>(
    Entity typeEntity,
    Entity g,
    bool traverse,
  ) {
    final c = ReservedSafeCompleter<TSuper>(typeEntity);
    register(c, groupEntity: g).end();
    if (traverse) {
      // ALSO seed the same completer into every ancestor that this
      // container considers a parent. Otherwise an ancestor's
      // `register<TSuper>(...)` would walk its own registry +
      // childrenContainer (top-down only) and never see this bottom-up
      // `parents.add` wire — leaving the waiter to hang even though
      // `child.getDependency<TSuper>(traverse: true)` would have found
      // the same registration. We share ONE completer instance so all
      // sites resolve together.
      for (final ancestor in _allAncestors().skip(1)) {
        if (ancestor.isRegistered<ReservedSafeCompleter<TSuper>>(
          groupEntity: g,
          traverse: false,
        )) {
          continue;
        }
        ancestor
            .register<ReservedSafeCompleter<TSuper>>(c, groupEntity: g)
            .end();
      }
    }
    return c;
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
      // Snapshot the registry's unsorted dependencies up front so a
      // re-entrant register/unregister fired from `wait`'s callback (which
      // recursively calls `resolveAll`) cannot trigger
      // `ConcurrentModificationError` while we're still iterating.
      var resolvables = registry.unsortedDependencies
          .toList(growable: false)
          .cast<Dependency>();
      if (groupEntity case Some(value: final g)) {
        resolvables = resolvables
            .where(
              (e) => switch (e.metadata) {
                Some(value: final m) => m.groupEntity == g,
                None() => false,
              },
            )
            .toList(growable: false);
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
