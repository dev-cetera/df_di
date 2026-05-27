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

  /// Container for child DI instances. Production code should not mutate
  /// this field directly — `registerChild` is the supported entry point.
  Option<DI> childrenContainer = const None();

  /// Returns already-materialised children only — an un-read `Lazy<DI>` is
  /// skipped so iterating `children()` from `_maybeFinish` cannot
  /// force-construct unrelated children. Snapshotted to survive re-entrant
  /// register/unregister.
  Option<Iterable<DI>> children() {
    return childrenContainer.map(
      (e) => e.registry.unsortedDependencies
          .toList(growable: false)
          .map(_childFromDep)
          .nonNulls,
    );
  }

  /// Returns the materialised `DI` for a registry entry, or `null` for any
  /// async / unmaterialised / errored slot.
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

  /// Reads `Lazy<DI>.currentInstance` without forcing construction — needed
  /// to honor the C7 contract that registering at a parent must not
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

    // Check for existing slot BEFORE building the Resolvable — wrapping it
    // runs the onRegister side effects (init()), which must not fire for a
    // registration we'll reject.
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
    // Wrap onRegister so a sync throw lands as Err on the returned
    // Resolvable instead of escaping out of `register()`.
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
      _maybeFinish<Object>(value: value, g: g);
      if (enableUntilExactlyK) {
        (this as SupportsMixinK).maybeFinishK<T>(g: g);
      }
    }
    // We just wrote the slot — `get<T>` should find it unless a concurrent
    // unregister raced. Return Err in that case rather than throw.
    return switch (get<T>(groupEntity: groupEntity)) {
      Some(value: final r) => r,
      None() => Sync<T>.err(
          Err('register<$T>: post-register lookup returned None '
              '(slot was concurrently removed).'),
        ),
    };
  }

  /// Invokes [onRegister] on [value], converting any sync throw into a
  /// `Future.error` so the surrounding Resolvable chain routes it through
  /// the normal error path. Callbacks may return a `Resolvable` (e.g.
  /// `(s) => s.init()`) — [awaitCallbackResult] unwraps such returns so
  /// `until*` waiters never observe a half-initialised service.
  FutureOr<void> _safeOnRegister<T extends Object>(
    Option<TOnRegisterCallback<T>> onRegister,
    T value,
  ) {
    try {
      // Capture as `Object?` so `awaitCallbackResult` can dispatch on the
      // runtime type.
      final Object? result = switch (onRegister) {
        Some(value: final cb) => cb(value),
        None() => null,
      };
      // onRegister failures must surface as Err on the returned Resolvable.
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
  /// Iterates every pending completer regardless of its type parameter and
  /// delegates the type test to the completer's captured `typeCheck` closure
  /// — `.whereType<ReservedSafeCompleter<T>>()` is unreliable under dart2js
  /// release. See `ReservedSafeCompleter.typeCheck`.
  void _maybeFinish<T extends Object>({
    required FutureOr<Object> value,
    required Entity g,
  }) {
    // `typeCheck` needs a non-Future Object. Future-valued registrations
    // fall back to the try/cast dance — works on VM and debug web, but
    // generic erasure can mis-match under dart2js release. Callers wanting
    // `until*` on Web release should not register raw Futures.
    final checkValue = value is Future ? null : value;

    for (final di in [this as DI, ...children().unwrapOr([])]) {
      // `groupSlots` snapshots only the target group; the public `state`
      // getter deep-copies the entire registry and would allocate per
      // register call.
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
          if (!completer.typeCheck(checkValue)) continue;
          if (!completer.isCompleted) {
            completer.complete(value).end();
            break;
          }
        } else {
          // Future-valued fallback — see method doc.
          try {
            (completer as ReservedSafeCompleter<T>)
                .complete(value as FutureOr<T>)
                .end();
            break;
          } on TypeError {
            // Wrong T.
          } on StateError {
            // Already completed.
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

    // Walk the full ancestor chain so `unregister(traverse: true)` and
    // `isRegistered(traverse: true)` agree on which deps exist.
    final containers = traverse ? _allAncestors() : <DI>[this as DI];
    walk:
    for (final di in containers) {
      switch (di.removeDependency<T>(groupEntity: g)) {
        case Some(value: final dep):
          removed.add(dep);
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

  /// Fires `onUnregister` for every entry in [removed] in order, then
  /// resolves with the value of the first removed dependency. Sync throws
  /// are logged and the chain continues so no cleanup is silently dropped.
  Resolvable<Option<T>> _runOnUnregisterChain<T extends Object>({
    required List<Dependency> removed,
    required bool triggerOnUnregisterCallbacks,
  }) {
    // Walk the Result manually — `Async.then` short-circuits on Err and
    // would skip onUnregister for Err-resolved deps.
    final firstDep = removed.first.transf<T>();
    var chain = _firstResolvedToOption<T>(firstDep);

    if (!triggerOnUnregisterCallbacks) {
      return chain;
    }

    for (final dep in removed) {
      if (dep.metadata case Some(value: final meta)) {
        if (meta.onUnregister case Some(value: final cb)) {
          chain = _chainOnUnregisterStep<T>(chain, dep, cb);
        }
      }
    }
    return chain;
  }

  /// Resolves `Resolvable<T>` to `Option<T>`: `Ok(v)` → `Some(v)`,
  /// `Err` → `None`. Preserves the Sync fast-path.
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
  /// dep's resolved `Result` (Ok or Err) so callers can clean up on both
  /// success and failure. Preserves the Sync fast-path.
  Resolvable<Option<T>> _chainOnUnregisterStep<T extends Object>(
    Resolvable<Option<T>> chain,
    Dependency dep,
    TOnUnregisterCallback<Object> cb,
  ) {
    // Sync fast-path only fires when both chain and dep are synchronous.
    if (chain case Sync<Option<T>>(value: final accResult)) {
      if (dep.value case Sync<Object>(value: final depResult)) {
        return switch (accResult) {
          Err() => chain,
          Ok(value: final acc) => _fireOnUnregister<T>(cb, depResult, dep, acc),
        };
      }
    }
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
    // Sync failures are logged and the chain continues; async failures
    // propagate.
    final FutureOr<void> awaited;
    try {
      awaited = awaitCallbackResult(
        cbResult,
        logAndSwallowSyncErr: true,
        logContext: 'onUnregister for ${dep.runtimeType}',
      );
    } catch (e) {
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
  ///
  /// Iterative DFS over the parent chain so deep hierarchies cannot blow
  /// the call stack. Cycle-safe via the internal `seen` set.
  bool isRegistered<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    @Deprecated('Cycle detection is internal; this parameter is now ignored.')
    Set<DI>? visited,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final seen = <DI>{};
    final stack = <(DI, Entity)>[
      (this as DI, groupEntity.preferOverDefault(focusGroup)),
    ];
    while (stack.isNotEmpty) {
      final (di, g) = stack.removeLast();
      if (!seen.add(di)) continue;
      if (di.registry.containsDependency<T>(groupEntity: g)) return true;
      if (!traverse) break;
      // Push in reverse so first parent is popped first (sibling order).
      final parentList = di.parents.toList(growable: false);
      for (var i = parentList.length - 1; i >= 0; i--) {
        final parent = parentList[i];
        stack.add((parent, g.preferOverDefault(parent.focusGroup)));
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
    return switch (option) {
      None() => const None(),
      Some(value: Err(:final error, :final stackTrace)) => Some(
          Sync<T>.err(Err<T>(error, stackTrace: stackTrace)),
        ),
      Some(value: Ok(value: final dep)) => switch (dep.value) {
          Sync<T>() => Some(dep.value),
          Async<T>(value: final fut) => () {
              // Capture the actually-stored slot (by identity) at scheduling
              // time. `dep` is a `.transf<T>()` view returned by
              // `registry.getDependency<T>()` — a fresh wrapper, never the
              // stored instance — so we cannot identity-compare against `dep`
              // directly. The registry slot key is `dep.typeEntity`.
              final slotKey = dep.typeEntity;
              final originalSlot = registry.getSlot(
                slotKey,
                groupEntity: g,
              );
              return Some(
                Async<T>(
                  () => fut.then((e) {
                    // Throw on Err — the surrounding Async() absorbs it.
                    final value = switch (e) {
                      Ok(value: final v) => v,
                      Err(:final error, :final stackTrace) =>
                        throw Err<T>(error, stackTrace: stackTrace),
                    };
                    // Memoise the resolved value as Sync, but ONLY when the
                    // registry slot still belongs to the original Dependency
                    // by reference. A concurrent `unregister<T>()` (or
                    // `unregister` + new `register<T>(...)`) between the time
                    // we scheduled the then-callback and the time the async
                    // resolves would otherwise be silently undone — we'd
                    // remove the user's new registration and re-write a stale
                    // Sync slot. Identity comparison detects both scenarios:
                    //  * slot is null  → user unregistered. Skip the swap.
                    //  * slot is other → user re-registered. Skip; their new
                    //    state wins.
                    //  * slot is identical to originalSlot → safe to memoise.
                    final currentSlot = registry.getSlot(
                      slotKey,
                      groupEntity: g,
                    );
                    if (originalSlot != null &&
                        identical(currentSlot, originalSlot)) {
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
                          throw error;
                      }
                    }
                    return value;
                  }),
                ),
              );
            }(),
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
  /// Iterative DFS — see [isRegistered].
  Option<Result<Dependency<T>>> getDependency<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    @Deprecated('Cycle detection is internal; this parameter is now ignored.')
    Set<DI>? visited,
  }) {
    final seen = <DI>{};
    final stack = <(DI, Entity)>[
      (this as DI, groupEntity.preferOverDefault(focusGroup)),
    ];
    while (stack.isNotEmpty) {
      final (di, g) = stack.removeLast();
      if (!seen.add(di)) continue;
      final option = di.registry.getDependency<T>(groupEntity: g);
      if (option case Some()) {
        return option.map((e) => Ok(e).transf<Dependency<T>>());
      }
      if (!traverse) break;
      final parentList = di.parents.toList(growable: false);
      for (var i = parentList.length - 1; i >= 0; i--) {
        final parent = parentList[i];
        stack.add((parent, g.preferOverDefault(parent.focusGroup)));
      }
    }
    return const None();
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
          // Surface Err on a post-resolution race rather than throw.
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

  /// Constructs a [ReservedSafeCompleter] keyed on [typeEntity] under [g],
  /// registers it here, and (when [traverse]) seeds the SAME instance into
  /// every ancestor that doesn't already carry one.
  ReservedSafeCompleter<TSuper> _seedCompleter<TSuper extends Object>(
    Entity typeEntity,
    Entity g,
    bool traverse,
  ) {
    final c = ReservedSafeCompleter<TSuper>(typeEntity);
    register(c, groupEntity: g).end();
    if (traverse) {
      // Ancestors only walk top-down (own registry + childrenContainer),
      // so a bottom-up `parents.add` wire wouldn't be seen otherwise. The
      // single shared completer lets every site resolve together.
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
      // Snapshot up front: `wait`'s callback recursively calls `resolveAll`,
      // and a re-entrant register/unregister would otherwise raise
      // ConcurrentModificationError.
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
