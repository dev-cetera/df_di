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
  Iterable<DIBase> get children =>
      registry.unsortedDependencies.map((e) => e.value).whereType<DIBase>();

  /// A key that identifies the current group in focus for dependency management.
  Entity focusGroup = const DefaultEntity();

  /// A container storing Future completions.
  @protected
  Option<DIBase> completers = const None();

  @protected
  int _indexIncrementer = 0;

  @pragma('vm:prefer-inline')
  Result<Resolvable<T>> registerValue<T extends Object>(
    FutureOr<T> value, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    return register(
      unsafe: () => value,
      groupEntity: groupEntity,
    );
  }

  Result<Resolvable<T>> register<T extends Object>({
    required FutureOr<T> Function() unsafe,
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final metadata = DependencyMetadata(
      index: Some(_indexIncrementer++),
      groupEntity: g,
    );
    final value = Resolvable.unsafe(unsafe);
    final check = completeRegistration(value, g);
    if (check.isErr()) {
      return check.err().castErr();
    }
    final result = _registerDependency(
      dependency: Dependency(
        value,
        metadata: Some(metadata),
      ),
      checkExisting: true,
    );
    return result.map((e) => e.value);
  }

  @protected
  Result<None> completeRegistration<T extends Object>(
    Resolvable<T> value,
    Entity groupEntity,
  ) {
    if (completers.isSome()) {
      final a = completers.unwrap();
      final b = a.registry.getDependency<SafeFinisher<T>>(groupEntity: groupEntity).or(
            a.registry.getDependencyK(
              TypeEntity(SafeFinisher<Object>, [value.runtimeType]),
              groupEntity: groupEntity,
            ),
          );
      if (b.isSome()) {
        //
        final test = (b.unwrap() as Dependency).value.sync().unwrap().value;
        if (test.isErr()) {
          return test.cast();
        }
        (test.unwrap() as SafeFinisher).resolve(value);
      }
      // TODO:
      // for (final child in children) {
      //   final test = child.completeRegistration(value, groupEntity);
      //   if (test.isErr()) {
      //     test.cast();
      //   }
      // }
    }
    return const Ok(None());
  }

  Result<Dependency<T>> _registerDependency<T extends Object>({
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
          _registerDependency<T>(
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
    if (completers.isSome()) {
      final test = completers.unwrap().registry.getDependency<SafeFinisher<T>>(
            groupEntity: g,
          );

      if (test.isSome()) {
        final some = test.unwrap();
        final completer = some.value.sync().unwrap().value.unwrap();
        return completer.resolvable;
      }
    } else {
      completers = Some(DIBase());
    }
    final completer = SafeFinisher<T>();
    completers.unwrap().registry.setDependency(
          Dependency<SafeFinisher<T>>(
            Sync(Ok(completer)),
            metadata: Some(
              DependencyMetadata(
                groupEntity: g,
              ),
            ),
          ),
        );
    return completer.resolvable.map((e) {
      completers.unwrap().registry.removeDependency<SafeFinisher<T>>(
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
