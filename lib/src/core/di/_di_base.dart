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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class ReservedSafeFinisher<T extends Object> extends SafeFinisher<T> {
  final Entity typeEntity;
  ReservedSafeFinisher(this.typeEntity);

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode {
    final a = Object() is! T ? T.hashCode : typeEntity.hashCode;
    final b = (ReservedSafeFinisher).hashCode;
    return Object.hash(a, b);
  }
}

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

  @pragma('vm:prefer-inline')
  Resolvable<T> register<T extends Object>(
    FutureOr<T> value, {
    FutureOr<void> Function(T value)? onRegister,
    OnUnregisterCallback<T>? onUnregister,
    Entity groupEntity = const DefaultEntity(),
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final g = groupEntity.preferOverDefault(focusGroup);
    final metadata = DependencyMetadata(
      index: Some(_indexIncrementer++),
      groupEntity: g,
      onUnregister:
          onUnregister != null
              ? Some((e) => onUnregister(e.trans()))
              : const None(),
    );
    final a = Resolvable(
      () => consec(value, (e) => consec(onRegister?.call(e), (_) => e)),
    );
    _resolveFinisher(value: a, g: g);
    final b = registerDependency<T>(
      dependency: Dependency(a, metadata: Some(metadata)),
      checkExisting: true,
    );
    return a.map((e) => b.unwrap().value).comb2();
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

  // Resolve all finishers that can be resolved with the value.
  void _resolveFinisher<T extends Object>({
    required Resolvable<T> value,
    required Entity g,
  }) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    for (final di in [this as DI, ...children().unwrapOr([])]) {
      var finisher = di.getFinisher<T>(typeEntity: TypeEntity(T), g: g);
      if (finisher == null) continue;
      try {
        finisher.resolve(value);
        break;
      } catch (_) {}
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
    final sequential = SafeSequential();
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
            sequential.addSafe((_) => dependency.value.map((e) => Some(e)));
            sequential.addSafe((e) {
              final option = e.swap();
              if (option.isSome()) {
                final result = option.unwrap();
                return onUnregister(result);
              }
              return null;
            });
          }
        }
      }
      if (!removeAll) {
        break;
      }
    }
    return sequential.last;
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

  Resolvable<T> until<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final typeEntity = TypeEntity(T);
    final g = groupEntity.preferOverDefault(focusGroup);
    final test = get<T>(groupEntity: g);
    if (test.isSome()) {
      return test.unwrap();
    }
    var finisher = getFinisher<T>(typeEntity: typeEntity, g: g);
    if (finisher == null) {
      finisher = ReservedSafeFinisher(typeEntity);
      register<ReservedSafeFinisher>(finisher, groupEntity: g);
    }
    return finisher.resolvable().map((_) {
      removeFinisher<T>(typeEntity: typeEntity, g: g);
      return get<T>(groupEntity: g).unwrap();
    }).comb2();
  }

  @protected
  void removeFinisher<T extends Object>({
    required Entity typeEntity,
    required Entity g,
  }) {
    registry.removDependencyWhere((entity, dependency) {
      final resolvable = dependency.value;
      if (resolvable.isAsync()) return false;
      final result = resolvable.sync().unwrap().value;
      if (result.isErr()) return false;
      final value = result.unwrap();
      if (value is ReservedSafeFinisher) {
        if (isSubtype<ReservedSafeFinisher<T>, ReservedSafeFinisher>()) {
          return true;
        } else if (value.typeEntity == typeEntity) {
          return true;
        }
      }
      return false;
    }, groupEntity: g,);
  }

  @protected
  ReservedSafeFinisher? getFinisher<T extends Object>({
    required Entity typeEntity,
    required Entity g,
  }) {
    ReservedSafeFinisher? finisher;
    for (final e in registry.getGroup(groupEntity: g).values) {
      final resolvable = e.value;
      if (resolvable.isAsync()) break;
      final result = resolvable.sync().unwrap().value;
      if (result.isErr()) break;
      final value = result.unwrap();
      if (value is ReservedSafeFinisher) {
        if (isSubtype<ReservedSafeFinisher<T>, ReservedSafeFinisher>()) {
          finisher = value;
        } else if (value.typeEntity == typeEntity) {
          finisher = value;
        }
      }
    }
    return finisher;
  }

  Resolvable<List<Dependency>> unregisterAll({
    OnUnregisterCallback<Dependency>? onBeforeUnregister,
    OnUnregisterCallback<Dependency>? onAfterUnregister,
  }) {
    final results = List.of(registry.sortedDependencies);
    final sequential = SafeSequential();
    for (final dependency in results) {
      sequential.addAll([
        (_) {
          onBeforeUnregister?.call(Ok(dependency));
          return null;
        },
        (_) {
          registry.removeDependencyK(
            dependency.typeEntity,
            groupEntity: dependency.metadata
                .map((e) => e.groupEntity)
                .unwrapOr(const DefaultEntity()),
          );
          return null;
        },
        (_) {
          return dependency.metadata.map(
            (e) => e.onUnregister.ifSome((e) => e.unwrap()(Ok(dependency))),
          );
        },
        (_) {
          onAfterUnregister?.call(Ok(dependency));
          return null;
        },
      ]);
    }
    final result = sequential.add((_) => Some(results)).map((e) => e.unwrap());
    return result;
  }
}

bool _isSubtype<TChild, TParent>() => <TChild>[] is List<TParent>;
