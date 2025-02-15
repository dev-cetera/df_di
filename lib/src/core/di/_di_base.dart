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

base class DIBase {
  //
  //
  //

  /// Internal registry that stores dependencies.
  @protected
  final registry = DIRegistry();

  /// Parent containers.
  @protected
  final parents = <DIBase>{};

  /// Child containers.
  Iterable<DI> get children => registry.unsortedDependencies.map((e) => e.value).whereType<DI>();

  /// A key that identifies the current group in focus for dependency management.
  Entity focusGroup = const DefaultEntity();

  /// A container storing Future completions.
  @protected
  Option<DI> finishers = const None();

  @protected
  int _indexIncrementer = 0;

  @pragma('vm:prefer-inline')
  Result<void> register<T extends Object>(
    FutureOr<T> value, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    return registerUnsafe(
      () => value,
      groupEntity: groupEntity,
    );
  }

  Result<void> registerUnsafe<T extends Object>(
    FutureOr<T> Function() unsafe, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final metadata = DependencyMetadata(
      index: Some(_indexIncrementer++),
      groupEntity: g,
    );
    final value = Resolvable.unsafe(unsafe);
    final check = completeRegistration<T>(value, g);
    if (check.isErr()) {
      return check.err().castErr();
    }
    final result = registerDependency(
      dependency: Dependency(
        value,
        metadata: Some(metadata),
      ),
      checkExisting: true,
    );
    return result;
  }

  @protected
  Result<None> completeRegistration<T extends Object>(
    Resolvable<T> value,
    Entity groupEntity,
  ) {
    if (finishers.isSome()) {
      final finishers1 = (finishers.unwrap()).child(groupEntity: TypeEntity(T));
      final option = finishers1.registry.getDependency<SafeFinisher>(groupEntity: groupEntity);
      if (option.isSome()) {
        final test = (option.unwrap() as Dependency).value.sync().unwrap().value;
        if (test.isErr()) {
          return test.cast();
        }
        (test.unwrap() as SafeFinisher).resolve(value);
      }
    }
    return const Ok(None());
  }

  @protected
  Result<Dependency<T>> registerDependency<T extends Object>({
    required Dependency<T> dependency,
    bool checkExisting = false,
  }) {
    assert(
      T != Object,
      'T must be specified and cannot be Object.',
    );

    final g = dependency.metadata.isSome() ? dependency.metadata.unwrap().groupEntity : focusGroup;
    if (checkExisting) {
      final option = getDependency<T>(
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

  Option<Resolvable<Object>> unregister<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool skipOnUnregisterCallback = false,
  }) {
    final removed = removeDependency<T>(groupEntity: groupEntity);
    if (removed.isNone()) {
      return const None();
    }
    final removedDependency = removed.unwrap() as Dependency;
    return Some(Sync(Ok(removedDependency.value)));
  }

  @protected
  @pragma('vm:prefer-inline')
  Option<Object> removeDependency<T extends Object>({Entity groupEntity = const DefaultEntity()}) {
    final g = groupEntity.preferOverDefault(focusGroup);
    return registry
        .removeDependency<T>(groupEntity: g)
        .or(registry.removeDependency<Lazy<T>>(groupEntity: g));
  }

  bool isRegistered<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
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
    return getSync<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().value.unwrap();
  }

  Option<Sync<T>> getSync<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return get<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).map(
      (e) => e.isSync()
          ? e.sync().unwrap()
          : Sync(
              const Err(
                stack: ['DIBase', 'getSync'],
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
    return Future.sync(() async {
      final result = await getAsync<T>(
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
    return consec(
      get<T>(
        groupEntity: groupEntity,
        traverse: traverse,
      ).unwrap().value,
      (e) => e.unwrap(),
    );
  }

  @pragma('vm:prefer-inline')
  Option<T> call<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getSyncOrNone<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  Option<T> getSyncOrNone<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final option = get<T>(
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

  Option<Resolvable<T>> get<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final option = getDependency<T>(
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
    final dependency = result.unwrap();
    final value = dependency.value;
    if (value.isSync()) {
      return Some(value);
    }

    return Some(
      Async.unsafe(
        () => value.async().unwrap().value.then((e) {
          final value = e.unwrap();
          registry.removeDependency<T>(groupEntity: g);
          registerDependency<T>(
            dependency: Dependency<T>(
              Sync(Ok(value)),
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
  OptionResult<Dependency<T>> getDependency<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    bool validate = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final test = registry.getDependency<T>(groupEntity: g);
    var temp = test.map((e) => Ok(e).asResult());
    if (test.isNone() && traverse) {
      for (final parent in parents) {
        temp = parent.getDependency<T>(
          groupEntity: g,
        );
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
    final g = groupEntity.preferOverDefault(focusGroup);
    final test = get<T>(groupEntity: g);
    if (test.isSome()) {
      return test.some().unwrap().value;
    }
    if (finishers.isSome()) {
      final finishers1 = (finishers.unwrap()).child(groupEntity: TypeEntity(T));
      final option = finishers1.registry.getDependency<SafeFinisher<T>>(
        groupEntity: g,
      );
      if (option.isSome()) {
        final some = option.unwrap();
        final finisher = some.value.sync().unwrap().value.unwrap();
        return finisher.resolvable;
      }
    } else {
      finishers = Some(DI());
    }
    final finisher = SafeFinisher<T>();
    final finishers1 = (finishers.unwrap()).child(groupEntity: TypeEntity(T));
    finishers1.registry.setDependency(
      Dependency<SafeFinisher<T>>(
        Sync(Ok(finisher)),
        metadata: Some(
          DependencyMetadata(
            groupEntity: g,
          ),
        ),
      ),
    );
    return finisher.resolvable.map((e) {
      finishers1.registry.removeDependency<SafeFinisher<T>>(
        groupEntity: g,
      );
      return e;
    });
  }

  Resolvable<List<Dependency>> unregisterAll({
    OnUnregisterCallback<Dependency>? onBeforeUnregister,
    OnUnregisterCallback<Dependency>? onAfterUnregister,
  }) {
    final results = List.of(registry.sortedDependencies);
    final sequential = SafeSequential();
    for (final dependency in results) {
      sequential.addAll(
        unsafe: [
          (_) {
            onBeforeUnregister?.call(dependency);
            return null;
          },
          (_) {
            return registry.removeDependencyK(
              dependency.typeEntity,
              groupEntity:
                  dependency.metadata.map((e) => e.groupEntity).unwrapOr(const DefaultEntity()),
            );
          },
          (_) {
            return dependency.metadata
                .map((e) => e.onUnregister.ifSome((e) => e.unwrap()(dependency)));
          },
          (_) {
            onAfterUnregister?.call(dependency);
            return null;
          },
        ],
      );
    }
    final result = sequential.add(unsafe: (_) => Some(results)).map((e) => e.unwrap());
    return result;
  }
}
