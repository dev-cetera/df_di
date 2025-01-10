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

  /// A key that identifies the current group in focus for dependency management.
  Entity focusGroup = DefaultEntities.FALLBACK_GROUP.entity;

  /// A container storing Future completions.
  @protected
  Option<DIBase> completers = const None();

  /// Returns the total number of registered dependencies.
  @protected
  int dependencyCount = 0;

  Result<Option<FutureOr<T>>> register<T extends Object>(
    FutureOr<T> value, {
    Entity groupEntity = const Entity.fallback(),
    Option<DependencyValidator<FutureOr<T>>> validator = const None(),
    Option<OnUnregisterCallback<FutureOr<T>>> onUnregister = const None(),
  }) {
    final g = groupEntity.isFallback() ? focusGroup : groupEntity;
    final metadata = DependencyMetadata(
      index: Some(dependencyCount++),
      groupEntity: g,
      validator:
          validator.isSome ? Some((e) => validator.unwrap()(e as FutureOr<T>)) : const None(),
      onUnregister:
          onUnregister.isSome ? Some((e) => onUnregister.unwrap()(e as FutureOr<T>)) : const None(),
    );
    completeRegistration(value, g);
    final registeredDep = _registerDependency(
      dependency: Dependency(
        value,
        metadata: Some(metadata),
      ),
      checkExisting: true,
    );
    return registeredDep.map((e) => e.map((e) => e.value));
  }

  @protected
  void completeRegistration<T extends Object>(
    T value,
    Entity groupEntity,
  ) {
    if (completers.isSome) {
      final a = completers.unwrap();
      final b = a.registry
          .getDependency<CompleterOr<FutureOr<T>>>(groupEntity: groupEntity)
          .or(
            a.registry.getDependencyK(
              TypeEntity(CompleterOr<Object>, [value.runtimeType]),
              groupEntity: groupEntity,
            ),
          )
          .or(
            a.registry.getDependencyK(
              TypeEntity(CompleterOr<Future<Object>>, [value.runtimeType]),
              groupEntity: groupEntity,
            ),
          );

      if (b.isSome) {
        (b.unwrap().value as CompleterOr?)?.complete(value);
      }
    }
  }

  Result<Option<Dependency<T>>> _registerDependency<T extends FutureOr<Object>>({
    required Dependency<T> dependency,
    bool checkExisting = false,
  }) {
    assert(
      T != Object,
      'T must be specified and cannot be Object.',
    );

    // If [checkExisting] is true, throw an exception if the dependency is
    // already registered.
    final g = dependency.metadata.fold((e) => e.groupEntity, () => focusGroup);
    if (checkExisting) {
      final existingDep = _getDependency<T>(
        groupEntity: g,
        traverse: false,
        validate: false,
      );
      if (existingDep.isErr) {
        return existingDep.err.cast();
      }
      if (existingDep.unwrap().isSome) {
        return const Err('Dependency already registered.');
      }
    }
    registry.setDependency(dependency);
    return Ok(Some(dependency));
  }

  Option<FutureOr<Object>> unregister<T extends Object>({
    Entity groupEntity = const Entity.fallback(),
    bool skipOnUnregisterCallback = false,
  }) {
    final g = groupEntity.isFallback() ? focusGroup : groupEntity;
    final removed = registry
        .removeDependency<T>(groupEntity: g)
        .or(registry.removeDependency<Future<T>>(groupEntity: g))
        .or(registry.removeDependency<Lazy<T>>(groupEntity: g));
    if (removed.isNone) {
      return const None();
    }
    final removedDependency = removed.unwrap() as Dependency;
    if (skipOnUnregisterCallback) {
      return Some(removedDependency.value);
    }
    final metadata = removedDependency.metadata;
    if (metadata.isSome) {
      final onUnregister = metadata.unwrap().onUnregister;
      if (onUnregister.isSome) {
        return Some(
          consec(
            onUnregister.unwrap()(removedDependency),
            (_) => removedDependency,
          ),
        );
      }
    }
    return Some(removedDependency.value);
  }

  bool isRegistered<T extends Object>({
    Entity groupEntity = const Entity.fallback(),
    bool traverse = true,
  }) {
    final g = groupEntity.isFallback() ? focusGroup : groupEntity;
    if (registry.containsDependency<T>(groupEntity: g) ||
        registry.containsDependency<Future<T>>(groupEntity: g) ||
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

  Result<Option<T>> call<T extends Object>({
    Entity groupEntity = const Entity.fallback(),
    bool traverse = true,
  }) {
    return getSync<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  Future<T> getAsyncUnsafe<T extends Object>({
    Entity groupEntity = const Entity.fallback(),
    bool traverse = true,
  }) {
    return getAsync<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().unwrap();
  }

  Result<Option<Future<T>>> getAsync<T extends Object>({
    Entity groupEntity = const Entity.fallback(),
    bool traverse = true,
  }) {
    return get<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.map((e) async => e));
  }

  Result<Option<T>> getSync<T extends Object>({
    Entity groupEntity = const Entity.fallback(),
    bool traverse = true,
  }) {
    final value = get<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    );
    if (value.isErr) {
      return value.err.cast();
    }
    return Result(
      () {
        PanicIf(
          value.unwrap().isSome && value.unwrap() is Future,
          'getSync cannot return a Future.',
        );
        return value.unwrap().map((e) => e as T);
      },
    );
  }

  Result<Option<FutureOr<T>>> get<T extends Object>({
    Entity groupEntity = const Entity.fallback(),
    bool traverse = true,
  }) {
    final g = groupEntity.isFallback() ? focusGroup : groupEntity;
    final existingDep = _getDependency<T>(
      groupEntity: g,
      traverse: traverse,
    );
    if (existingDep.isErr) {
      return existingDep.err.cast();
    }
    if (existingDep.unwrap().isNone) {
      return const Ok(None());
    }
    final value = existingDep.unwrap().unwrap().value;
    switch (value) {
      case Future<T> futureValue:
        return Ok(
          Some(() async {
            final value = await futureValue;
            _registerDependency<T>(
              dependency: Dependency<T>(
                value,
                metadata: existingDep.unwrap().unwrap().metadata,
              ),
              checkExisting: false,
            );
            registry.removeDependency<Future<T>>(
              groupEntity: g,
            );
            return value;
          }()),
        );
      case T _:
        return Ok(Some(value));
    }
  }

  Result<Option<Dependency<FutureOr<T>>>> _getDependency<T extends Object>({
    Entity groupEntity = const Entity.fallback(),
    bool traverse = true,
    bool validate = true,
  }) {
    final g = groupEntity.isFallback() ? focusGroup : groupEntity;
    var a = registry
        .getDependency<T>(groupEntity: g)
        .or(registry.getDependency<Future<T>>(groupEntity: g));
    if (a.isNone && traverse) {
      for (final parent in parents) {
        final test = parent._getDependency<T>(
          groupEntity: g,
        );
        if (test.isErr) {
          return test;
        }
        a = test.unwrap();
        if (a.isSome) {
          break;
        }
      }
    }
    if (a.isSome) {
      final dependency = a.unwrap() as Dependency;
      if (validate) {
        final metadata = dependency.metadata;
        if (metadata.isSome) {
          final valid = metadata.unwrap().validator.map((e) => e(dependency));
          if (valid.isSome && !valid.unwrap()) {
            return const Err('Dependency validation failed.');
          }
        }
      }
      return Ok(Some(dependency.cast()));
    }
    return const Ok(None());
  }

  Result<Option<FutureOr<T>>> until<T extends Object>({
    Entity groupEntity = const Entity.fallback(),
    bool traverse = true,
  }) {
    final g = groupEntity.isFallback() ? focusGroup : groupEntity;
    final test = get<T>(groupEntity: g);
    if (test.isErr) {
      return test.err.cast();
    }
    if (test.unwrap().isSome) {
      return test;
    }
    if (completers.isSome) {
      final d = completers.unwrap().registry.getDependency<CompleterOr<FutureOr<T>>>(
            groupEntity: g,
          );
      final completer = d.unwrap().value;
      return Ok(Some(completer.futureOr.thenOr((e) => e)));
    }

    if (completers.isNone) {
      completers = Some(DIBase());
    }

    final completer = CompleterOr<FutureOr<T>>();
    completers.unwrap().registry.setDependency(
          Dependency<CompleterOr<FutureOr<T>>>(
            completer,
            metadata: Some(
              DependencyMetadata(
                groupEntity: g,
              ),
            ),
          ),
        );

    return Ok(
      Some(
        completer.futureOr.thenOr((value) {
          completers.unwrap().registry.removeDependency<CompleterOr<FutureOr<T>>>(
                groupEntity: g,
              );
          return get<T>(
            groupEntity: groupEntity,
            traverse: traverse,
          ).unwrap().unwrap();
        }),
      ),
    );
  }

  FutureOr<List<Dependency>> unregisterAll({
    Option<OnUnregisterCallback<Dependency>> onBeforeUnregister = const None(),
    Option<OnUnregisterCallback<Dependency>> onAfterUnregister = const None(),
  }) {
    final results = List.of(registry.dependencies);
    final sequential = Sequential();
    for (final dependency in results) {
      sequential.addAll([
        (_) => onBeforeUnregister.ifSome((e) => e(dependency)),
        (_) => registry.removeDependencyK(
              dependency.typeEntity,
              groupEntity:
                  dependency.metadata.map((e) => e.groupEntity).unwrapOr(const Entity.fallback()),
            ),
        (_) => dependency.metadata.map((e) => e.onUnregister.ifSome((e) => e(dependency))),
        (_) => onAfterUnregister.ifSome((e) => e(dependency)),
      ]);
    }
    return sequential.add((_) => results);
  }
}
