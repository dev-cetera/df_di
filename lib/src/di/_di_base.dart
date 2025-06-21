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

// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

import '/_common.dart';
import '../_reserved_safe_completer.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Base class for the dependency injection container
base class DIBase {
  //
  //
  //

  /// Internal registry that stores dependencies.
  @protected
  final registry = DIRegistry();

  /// Parent containers.
  @protected
  final parents = <DI>{};

  /// A key that identifies the current group in focus for dependency management.
  Entity focusGroup = const DefaultEntity();

  @protected
  int _indexIncrementer = 0;

  /// Container for child DI instances.
  @protected
  Option<DI> childrenContainer = const None();

  /// Retrieves an iterable of child [DI] instances.
  @protected
  Option<Iterable<DI>> children() {
    UNSAFE:
    return childrenContainer.map(
      (e) => e.registry.unsortedDependencies.map(
        (e) => e
            .transf<Lazy<DI>>()
            .value
            .unwrapSync()
            .unwrap()
            .singleton
            .unwrapSync()
            .unwrap(),
      ),
    );
  }

  //
  //
  //

  /// Registers a dependency with the container.
  Resolvable<T> register<T extends Object>(
    FutureOr<T> value, {
    TOnRegisterCallback<T>? onRegister,
    TOnUnregisterCallback<T>? onUnregister,
    Entity groupEntity = const DefaultEntity(),
    bool enableUntilExactlyK = false,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final g = groupEntity.preferOverDefault(focusGroup);
    final metadata = DependencyMetadata(
      index: Some(_indexIncrementer++),
      groupEntity: g,
      onUnregister: onUnregister != null
          ? Some((e) => onUnregister(e.transf()))
          : const None(),
    );
    final a = Resolvable(
      () => consec(value, (e) => consec(onRegister?.call(e), (_) => e)),
    );
    final b = registerDependency<T>(
      dependency: Dependency(a, metadata: Some(metadata)),
      checkExisting: true,
    );
    UNSAFE:
    {
      if (b.isErr()) {
        return Sync.value(b.err().unwrap().transfErr<T>());
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

  /// Attempts to finish any pending [until] calls for the given type and group
  /// when a new dependency is registered.
  void _maybeFinish<T extends Object>({
    required FutureOr<Object> value, // General "Object"
    required Entity g,
  }) {
    for (final di in [this as DI, ...children().unwrapOr([])]) {
      // Get all completers in group g.
      UNSAFE:
      final completers = di.registry.state[g]?.values
          .map((e) => e.value)
          .where((e) => e.isSync())
          .map((e) => e.unwrapSync().value)
          .where((e) => e.isOk())
          .map((e) => e.unwrap())
          // Get all completers regardless of type.
          .whereType<ReservedSafeCompleter<T>>();
      if (completers == null) continue;
      // Try each one to see if they can finish. It will only be able to finish
      // if value is compatible with the completer.
      for (final completer in completers) {
        try {
          completer.complete(value as FutureOr<T>).end();
          break;
        } catch (_) {
          // Skip completers that throw. Either by incorrect type T or the
          // completer can't complete the Future.
        }
      }
    }
  }

  /// Registers a [Dependency] object directly into the registry.
  @protected
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
  Resolvable<Option<T>> unregister<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    bool removeAll = true,
    bool triggerOnUnregisterCallbacks = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final g = groupEntity.preferOverDefault(focusGroup);
    for (final di in [this as DI, ...parents]) {
      final dependencyOption = di.removeDependency<T>(groupEntity: g);
      if (dependencyOption.isNone()) {
        continue;
      }
      UNSAFE:
      if (triggerOnUnregisterCallbacks) {
        final dependency = dependencyOption.unwrap();
        final metadataOption = dependency.metadata;
        if (metadataOption.isSome()) {
          final metadata = metadataOption.unwrap();
          final onUnregisterOption = metadata.onUnregister;
          if (onUnregisterOption.isSome()) {
            final onUnregister = onUnregisterOption.unwrap();
            return dependency.value.map((e) {
              return Resolvable(() {
                return consec(
                  onUnregister(Ok(e)),
                  (_) => Some(e).transf<T>().unwrap(),
                );
              });
            }).flatten();
          }
        }
      }
      if (!removeAll) {
        break;
      }
    }
    return Sync.unsafe(Ok(None<T>()));
  }

  /// Removes a dependency from the internal registry.
  @protected
  @pragma('vm:prefer-inline')
  Option<Dependency> removeDependency<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final g = groupEntity.preferOverDefault(focusGroup);
    Option<Dependency> result;
    result = registry.removeDependency<T>(groupEntity: g);
    if (result.isNone()) {
      result = registry.removeDependency<Lazy<T>>(groupEntity: g);
    }
    return result;
  }

  /// Retrieves a synchronous dependency unsafely, returning the instance
  /// directly or throwing an error if not found or async.
  bool isRegistered<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final g = groupEntity.preferOverDefault(focusGroup);
    if (registry.containsDependency<T>(groupEntity: g) ||
        registry.containsDependency<Lazy<T>>(groupEntity: g)) {
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
          : Sync.value(Err('Called getSync() for an async dependency.')),
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
    // TODO: THIS IS CLEEEEEEAN switches BUT WE NEED TO DO IT FOR THE REST OF THE CODEBASE!!!
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
        return Some(Sync.value(result.err().unwrap().transfErr()));
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
                Sync.value(Ok(value)),
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
  @protected
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
    final test = get<TSuper>(groupEntity: g);
    UNSAFE:
    {
      if (test.isSome()) {
        return test.unwrap().transf();
      }
      ReservedSafeCompleter<TSuper>? completer;
      var temp = getSyncOrNone<ReservedSafeCompleter<TSuper>>(
        groupEntity: g,
        traverse: traverse,
      );
      if (temp.isSome()) {
        completer = temp.unwrap();
      } else {
        completer = ReservedSafeCompleter<TSuper>(typeEntity);
        register(completer, groupEntity: g).end();
      }
      return completer
          .resolvable()
          .map((_) {
            unregister<ReservedSafeCompleter<TSuper>>(groupEntity: g).end();
            return get<TSuper>(groupEntity: g).unwrap();
          })
          .flatten()
          .transf();
    }
  }

  //
  //
  //

  /// Completes once all [Async] dependencies associated with [groupEntity]
  /// complete or any group if [groupEntity] is `null`.
  Resolvable<void> resolveAll({Entity? groupEntity = const DefaultEntity()}) {
    UNSAFE:
    return Resolvable(() {
      var resolvables = registry.unsortedDependencies;
      if (groupEntity != null) {
        resolvables = resolvables.where((e) {
          if (e.metadata.isSome()) {
            return e.metadata.unwrap().groupEntity == groupEntity;
          }
          return false;
        });
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
