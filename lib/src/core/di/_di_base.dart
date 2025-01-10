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
  Entity focusGroup = DefaultEntities.DEFAULT_GROUP.entity;

  /// A container storing Future completions.
  @protected
  Option<DIBase> completers = const None();

  /// Returns the total number of registered dependencies.
  @protected
  int dependencyCount = 0;

  Result<Option<Concur<T>>> register<T extends Object>(
    Concur<T> value, {
    Entity groupEntity = const Entity.defaultEntity(),
    Option<DependencyValidator<Concur<T>>> validator = const None(),
    Option<OnUnregisterCallback<Concur<T>>> onUnregister = const None(),
  }) {
    final g = groupEntity.isDefault() ? focusGroup : groupEntity;
    final metadata = DependencyMetadata(
      index: Some(dependencyCount++),
      groupEntity: g,
      validator: validator.map((f) => (e) => f(e as Concur<T>)),
      onUnregister: onUnregister.map((f) => (e) => f(e as Concur<T>)),
    );
    completeRegistration(value, g);
    final dep = _registerDependency(
      dependency: Dependency(
        value,
        metadata: Some(metadata),
      ),
      checkExisting: true,
    );
    return dep.map((e) => e.map((e) => e.value));
  }

  @protected
  void completeRegistration<T extends Object>(
    T value,
    Entity groupEntity,
  ) {
    if (completers.isSome) {
      final a = completers.unwrap();
      final b = a.registry
          .getDependency<CompleterOr<Concur<T>>>(groupEntity: groupEntity)
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

  Result<Option<Dependency<Concur<T>>>> _registerDependency<T extends Concur<Object>>({
    required Dependency<Concur<T>> dependency,
    bool checkExisting = false,
  }) {
    assert(
      T != Object,
      'T must be specified and cannot be Object.',
    );
    final g = dependency.metadata.fold((e) => e.groupEntity, () => focusGroup);
    if (checkExisting) {
      final dep = _getDependency<T>(
        groupEntity: g,
        traverse: false,
        validate: false,
      );
      if (dep.isErr) {
        return dep.err.cast();
      }
      if (dep.unwrap().isSome) {
        return const Err('Dependency already registered.');
      }
    }
    registry.setDependency(dependency);
    return Ok(Some(dependency));
  }

  Option<Concur<Object>> unregister<T extends Object>({
    Entity groupEntity = const Entity.defaultEntity(),
    bool skipOnUnregisterCallback = false,
  }) {
    final g = groupEntity.isDefault() ? focusGroup : groupEntity;
    final removed = registry
        .removeDependency<T>(groupEntity: g)
        .or(registry.removeDependency<Future<T>>(groupEntity: g))
        .or(registry.removeDependency<Lazy<T>>(groupEntity: g));
    if (removed.isNone) {
      return const None();
    }
    final removedDependency = removed.unwrap() as Dependency;
    if (skipOnUnregisterCallback) {
      return Some(Sync(removedDependency.value));
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
    Entity groupEntity = const Entity.defaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.isDefault() ? focusGroup : groupEntity;
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
    Entity groupEntity = const Entity.defaultEntity(),
    bool traverse = true,
  }) {
    return getSync<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  Result<Option<Future<T>>> getAsync<T extends Object>({
    Entity groupEntity = const Entity.defaultEntity(),
    bool traverse = true,
  }) {
    return get<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.map((e) async => e));
  }

  Result<Option<T>> getSync<T extends Object>({
    Entity groupEntity = const Entity.defaultEntity(),
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

  Result<Option<Concur<T>>> get<T extends Object>({
    Entity groupEntity = const Entity.defaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.isDefault() ? focusGroup : groupEntity;
    final dep = _getDependency<T>(
      groupEntity: g,
      traverse: traverse,
    );
    if (dep.isErr) {
      return dep.err.cast();
    }
    if (dep.unwrap().isNone) {
      return const Ok(None());
    }
    final value = dep.unwrap().unwrap().value;
    switch (value) {
      case Future<T> futureValue:
        return Ok(
          Some(() async {
            final value = await futureValue;
            _registerDependency<T>(
              dependency: Dependency<T>(
                value,
                metadata: dep.unwrap().unwrap().metadata,
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

  Result<Option<Dependency<Concur<T>>>> _getDependency<T extends Object>({
    Entity groupEntity = const Entity.defaultEntity(),
    bool traverse = true,
    bool validate = true,
  }) {
    final g = groupEntity.isDefault() ? focusGroup : groupEntity;
    var dep = registry
        .getDependency<T>(groupEntity: g)
        .or(registry.getDependency<Future<T>>(groupEntity: g));
    if (dep.isNone && traverse) {
      for (final parent in parents) {
        final test = parent._getDependency<T>(
          groupEntity: g,
        );
        if (test.isErr) {
          return test;
        }
        dep = test.unwrap();
        if (dep.isSome) {
          break;
        }
      }
    }
    if (dep.isSome) {
      final dependency = dep.unwrap() as Dependency;
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

  Result<Option<Concur<T>>> until<T extends Object>({
    Entity groupEntity = const Entity.defaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.isDefault() ? focusGroup : groupEntity;
    final test = get<T>(groupEntity: g);
    if (test.isErr) {
      return test.err.cast();
    }
    if (test.unwrap().isSome) {
      return test;
    }
    if (completers.isSome) {
      final dep = completers.unwrap().registry.getDependency<CompleterOr<Concur<T>>>(
            groupEntity: g,
          );
      final completer = dep.unwrap().value;
      return Ok(Some(completer.futureOr.thenOr((e) => e)));
    }

    if (completers.isNone) {
      completers = Some(DIBase());
    }

    final completer = CompleterOr<Concur<T>>();
    completers.unwrap().registry.setDependency(
          Dependency<CompleterOr<Concur<T>>>(
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
          completers.unwrap().registry.removeDependency<CompleterOr<Concur<T>>>(
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

  Concur<List<Dependency>> unregisterAll({
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
              groupEntity: dependency.metadata
                  .map((e) => e.groupEntity)
                  .unwrapOr(const Entity.defaultEntity()),
            ),
        (_) => dependency.metadata.map((e) => e.onUnregister.ifSome((e) => e(dependency))),
        (_) => onAfterUnregister.ifSome((e) => e(dependency)),
      ]);
    }
    return sequential.add((_) => results);
  }
}
