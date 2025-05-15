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

import '/src/_common.dart';
import '/src/core/_reserved_safe_finisher.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

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

  Resolvable<T> register<T extends Object>(
    FutureOr<T> value, {
    FutureOr<void> Function(T value)? onRegister,
    OnUnregisterCallback<T>? onUnregister,
    Entity groupEntity = const DefaultEntity(),
    bool enableUntilK = false,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final g = groupEntity.preferOverDefault(focusGroup);
    final metadata = DependencyMetadata(
      index: Some(_indexIncrementer++),
      groupEntity: g,
      onUnregister:
          onUnregister != null
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
    if (b.isErr()) {
      return Sync.value(b.err().transErr());
    }
    if (value is! ReservedSafeFinisher) {
      // Used for until.
      _maybeFinish<T>(value: value, g: g);

      // Used for untilT and untilK. Disabled by default to improve performance.
      if (enableUntilK) {
        (this as SupportsMixinK).maybeFinishK<T>(g: g);
      }
    }
    return a.map((e) {
      return b.unwrap().value;
    }).comb2();
  }

  @protected
  Option<DI> childrenContainer = const None();

  @protected
  Option<Iterable<DI>> children() {
    return childrenContainer.map(
      (e) => e.registry.unsortedDependencies.map(
        (e) =>
            e
                .trans<Lazy<DI>>()
                .value
                .unwrapSync()
                .unwrap()
                .singleton
                .unwrapSync()
                .unwrap(),
      ),
    );
  }

  void _maybeFinish<T extends Object>({
    required FutureOr<T> value,
    required Entity g,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    for (final di in [this as DI, ...children().unwrapOr([])]) {
      // Get all finishers in group g.
      final finishers =
          di.registry.state[g]?.values
              .map((e) => e.value)
              .where((e) => e.isSync())
              .map((e) => e.unwrapSync().value)
              .where((e) => e.isOk())
              .map((e) => e.unwrap())
              .whereType<ReservedSafeFinisher>();
      if (finishers == null) continue;
      // Try each one to see if they can finish. It will only be able to finish
      // if value is compatible with the finisher.
      for (final finisher in finishers) {
        try {
          finisher.finish(value);
          break;
        } catch (_) {
          // Skip this finisher.
        }
      }
    }
  }

  @protected
  Result<Dependency<T>> registerDependency<T extends Object>({
    required Dependency<T> dependency,
    bool checkExisting = false,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final g =
        dependency.metadata.isSome()
            ? dependency.metadata.unwrap().groupEntity
            : focusGroup;
    if (checkExisting) {
      final option = getDependency<T>(groupEntity: g, traverse: false);
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

  Resolvable<None> unregister<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    bool removeAll = true,
    bool triggerOnUnregisterCallbacks = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    var result = SyncOk.value(const None());
    final g = groupEntity.preferOverDefault(focusGroup);
    for (final di in [this as DI, ...parents]) {
      final dependencyOption = di.removeDependency<T>(groupEntity: g);
      if (dependencyOption.isNone()) {
        continue;
      }
      if (triggerOnUnregisterCallbacks) {
        final dependency = dependencyOption.unwrap();
        final metadataOption = dependency.metadata;
        if (metadataOption.isSome()) {
          final metadata = metadataOption.unwrap();
          final onUnregisterOption = metadata.onUnregister;
          if (onUnregisterOption.isSome()) {
            final onUnregister = onUnregisterOption.unwrap();
            result = dependency.value.map((e) => onUnregister(Ok(e))!).comb();
          }
        }
      }
      if (!removeAll) {
        break;
      }
    }
    return result;
  }

  @protected
  @pragma('vm:prefer-inline')
  Option<Dependency> removeDependency<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final g = groupEntity.preferOverDefault(focusGroup);
    return registry
            .removeDependency<T>(groupEntity: g)
            .or(registry.removeDependency<Lazy<T>>(groupEntity: g))
        as Option<Dependency>;
  }

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

  @pragma('vm:prefer-inline')
  T getSyncUnsafe<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    return getSync<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().value.unwrap();
  }

  Option<Sync<T>> getSync<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    return get<T>(groupEntity: groupEntity, traverse: traverse).map(
      (e) =>
          e.isSync()
              ? e.sync().unwrap()
              : Sync.value(
                Err(
                  debugPath: ['DIBase', 'getSync'],
                  error: 'Called getSync() for an async dependency.',
                ),
              ),
    );
  }

  @pragma('vm:prefer-inline')
  Future<T> getAsyncUnsafe<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    return Future.sync(() async {
      final result =
          await getAsync<T>(
            groupEntity: groupEntity,
            traverse: traverse,
          ).unwrap().value;
      return result.unwrap();
    });
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

  @pragma('vm:prefer-inline')
  FutureOr<T> getUnsafe<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    return get<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().unwrap();
  }

  @pragma('vm:prefer-inline')
  Option<T> call<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    return getSyncOrNone<T>(groupEntity: groupEntity, traverse: traverse);
  }

  Option<T> getSyncOrNone<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final option = get<T>(groupEntity: groupEntity, traverse: traverse);
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
    final result = option.unwrap();
    if (result.isErr()) {
      return Some(Sync.value(result.err().transErr()));
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
          registry.removeDependency<T>(groupEntity: g);
          registerDependency<T>(
            dependency: Dependency<T>(
              Sync.value(Ok(value)),
              metadata: option.unwrap().unwrap().metadata,
            ),
            checkExisting: false,
          );
          return value;
        }),
      ),
    );
  }

  @protected
  Option<Result<Dependency<T>>> getDependency<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final test = registry.getDependency<T>(groupEntity: g);
    var temp = test.map((e) => Ok(e).asResult());
    if (test.isNone() && traverse) {
      for (final parent in parents) {
        temp = parent.getDependency<T>(groupEntity: g);
        if (temp.isSome()) {
          break;
        }
      }
    }
    return temp;
  }

  @pragma('vm:prefer-inline')
  Resolvable<TSuper> untilSuper<TSuper extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return until<TSuper, TSuper>(groupEntity: groupEntity, traverse: traverse);
  }

  Resolvable<TSub> until<TSuper extends Object, TSub extends TSuper>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final typeEntity = TypeEntity(TSuper);
    final g = groupEntity.preferOverDefault(focusGroup);
    final test = get<TSuper>(groupEntity: g);
    if (test.isSome()) {
      return test.unwrap().transf();
    }
    ReservedSafeFinisher<TSuper>? finisher;
    var temp = getSyncOrNone<ReservedSafeFinisher<TSuper>>(
      groupEntity: g,
      traverse: traverse,
    );
    if (temp.isSome()) {
      finisher = temp.unwrap();
    } else {
      finisher = ReservedSafeFinisher<TSuper>(typeEntity);
      register(finisher, groupEntity: g);
    }
    return finisher
        .resolvable()
        .map((_) {
          unregister<ReservedSafeFinisher<TSuper>>(groupEntity: g);
          return get<TSuper>(groupEntity: g).unwrap();
        })
        .comb2()
        .transf();
  }

  Resolvable<None> unregisterAll({
    OnUnregisterCallback<Dependency>? onBeforeUnregister,
    OnUnregisterCallback<Dependency>? onAfterUnregister,
  }) {
    final results = List.of(registry.reversedDependencies);
    final sequential = SafeSequential();
    for (final dependency in results) {
      sequential
        ..addSafe((_) {
          return onBeforeUnregister?.call(Ok(dependency));
        })
        ..addSafe((_) {
          registry.removeDependencyK(
            dependency.typeEntity,
            groupEntity: dependency.metadata
                .map((e) => e.groupEntity)
                .unwrapOr(const DefaultEntity()),
          );

          final metadataOption = dependency.metadata;
          if (metadataOption.isSome()) {
            final metadata = metadataOption.unwrap();
            final onUnregisterOption = metadata.onUnregister;
            if (onUnregisterOption.isSome()) {
              final onUnregister = onUnregisterOption.unwrap();
              return dependency.value
                  .map((e) => onUnregister(Ok(e)) ?? SyncOk.value(const None()))
                  .comb();
            }
          }
          return null;
        })
        ..addSafe((_) {
          return onAfterUnregister?.call(Ok(dependency));
        });
    }
    return sequential.last;
  }
}
