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

  /// Registers a dependency [value] of type [T] under the specified
  /// [groupEntity] in the [registry].
  ///
  /// If the [value] is an instance of [DI], it will be registered as
  /// a child of this container. This action sets the child’s parent to this
  /// [DI] and ensures that the child's [registry] is cleared upon
  /// unregistration.
  ///
  /// You can provide a [validator] function to validate the dependency before
  /// it gets retrieved. If the validation fails [DependencyInvalidException]
  /// will be throw upon retrieval.
  ///
  /// Additionally, an [onUnregister] callback can be specified to execute when
  /// the dependency is unregistered via [unregister].
  ///
  /// Throws a [DependencyAlreadyRegisteredException] if a dependency of the
  /// same type and group is already registered.
  Result<Option<FutureOr<T>>> register<T extends Object>(
    FutureOr<T> value, {
    Entity groupEntity = const Entity.zero(),
    Option<DependencyValidator<FutureOr<T>>> validator = const None(),
    Option<OnUnregisterCallback<FutureOr<T>>> onUnregister = const None(),
  }) {
    final groupEntity1 = groupEntity.isZero() ? focusGroup : groupEntity;
    final metadata = DependencyMetadata(
      index: Some(dependencyCount++),
      groupEntity: groupEntity1,
      validator:
          validator.isSome ? Some((e) => validator.unwrap()(e as FutureOr<T>)) : const None(),
      onUnregister:
          onUnregister.isSome ? Some((e) => onUnregister.unwrap()(e as FutureOr<T>)) : const None(),
    );
    completeRegistration(value, groupEntity1);
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

  /// Registers a [dependency] of type [T] in the [registry].
  ///
  /// If the value of [dependency] is an instance of [DI], it will be
  /// registered as a child of this container. This action sets the child’s
  /// parent to this [DI] and ensures that the child's registry is
  /// cleared upon unregistration.
  ///
  /// Throws a [DependencyAlreadyRegisteredException] if a dependency of the
  /// same type and group is already registered and [checkExisting] is set
  /// to `true`. If [checkExisting] is set to `false`, any existing dependency
  /// of the same type and group is replaced.
  ///
  /// Returns the registered [Dependency] object as a [FutureOr] that
  /// completes with the [dependency] object once it is registered.
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
    final groupEntity1 = dependency.metadata.fold((e) => e.groupEntity, () => focusGroup);
    if (checkExisting) {
      final existingDep = _getDependency<T>(
        groupEntity: groupEntity1,
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

    // If [dependency] is not a [DIContainer], register it as a normal
    // dependency.
    registry.setDependency(dependency);
    return Ok(Some(dependency));
  }

  /// Unregisters the dependency of type [T] associated with the specified
  /// [groupEntity] from the [registry], if it exists.
  ///
  /// If [skipOnUnregisterCallback] is true, the
  /// [DependencyMetadata.onUnregister] callback will be skipped.

  Option<FutureOr<Object>> unregister<T extends Object>({
    Entity? groupEntity,
    bool skipOnUnregisterCallback = false,
  }) {
    final groupEntity1 = groupEntity ?? focusGroup;
    final removed = registry
        .removeDependency<T>(groupEntity: groupEntity1)
        .or(registry.removeDependency<T>(groupEntity: groupEntity1))
        .or(registry.removeDependency<Lazy<T>>(groupEntity: groupEntity1));
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
    return const None();
  }

  /// Checks whether dependency of type [T] or subtype of [T] is registered
  /// under the specified [groupEntity] in the [registry].
  ///
  /// If [traverse] is true, it will also search recursively in parent
  /// containers.
  bool isRegistered<T extends Object>({
    Entity groupEntity = const Entity.zero(),
    bool traverse = true,
  }) {
    final groupEntity1 = groupEntity.isZero() ? focusGroup : groupEntity;
    if (registry.containsDependency<T>(groupEntity: groupEntity1) ||
        registry.containsDependency<Future<T>>(groupEntity: groupEntity1) ||
        registry.containsDependency<Lazy<T>>(groupEntity: groupEntity1)) {
      return true;
    }
    if (traverse) {
      for (final parent in parents) {
        if (parent.isRegistered<T>(groupEntity: groupEntity1, traverse: true)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Retrieves a dependency of type [T] or its subtypes registered under
  /// the specified [groupEntity] from the [registry].
  ///
  /// If [traverse] is true, it will also search recursively in parent
  /// containers.
  ///
  /// If the dependency does not exist, a [DependencyNotFoundException] is
  /// thrown.
  ///
  /// If the dependency is a [Future], a [DependencyIsFutureException] is
  /// thrown.
  Result<Option<T>> call<T extends Object>({
    Entity groupEntity = const Entity.zero(),
    bool traverse = true,
  }) {
    return getSync<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Retrieves a dependency of type [T] or its subtypes registered under
  /// the specified [groupEntity] from the [registry].
  ///
  /// If [traverse] is true, it will also search recursively in parent
  /// containers.
  ///
  /// If the dependency does not exist, a [DependencyNotFoundException] is
  /// thrown.
  ///
  /// This method always returns a [Future], ensuring compatibility. This
  /// provides a safe and consistent way to retrieve dependencies, even if the
  /// registered dependency is not a [Future].
  Result<Option<Future<T>>> getAsync<T extends Object>({
    Entity groupEntity = const Entity.zero(),
    bool traverse = true,
  }) {
    return get<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.map((e) async => e));
  }

  /// Retrieves a dependency of type [T] or its subtypes registered under
  /// the specified [groupEntity] from the [registry].
  ///
  /// If [traverse] is true, it will also search recursively in parent
  /// containers.
  ///
  /// If the dependency is a [Future], a [DependencyIsFutureException] is
  /// thrown.
  ///
  /// If the dependency does not exist, a [DependencyNotFoundException] is
  /// thrown.
  Result<Option<T>> getSync<T extends Object>({
    Entity groupEntity = const Entity.zero(),
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

  /// Retrieves a dependency of type [T] or its subtypes registered under
  /// the specified [groupEntity] from the [registry].
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  ///
  /// If the dependency is registered as a non-future, the returned value will
  /// always be non-future. If it is registered as a future, the returned value
  /// will initially be a future. Once that future completes, its resolved value
  /// is re-registered as a non-future, allowing future calls to this method
  /// to return the resolved value directly.
  Result<Option<FutureOr<T>>> get<T extends Object>({
    Entity groupEntity = const Entity.zero(),
    bool traverse = true,
  }) {
    final groupEntity1 = groupEntity.isZero() ? focusGroup : groupEntity;
    final existingDep = _getDependency<T>(
      groupEntity: groupEntity1,
      traverse: traverse,
    );
    if (existingDep.isErr) {
      return existingDep.err.cast();
    }

    if (existingDep.unwrap().isNone) {
      return const Ok(None());
    }

    final existingDep1 = existingDep.unwrap().unwrap();
    final value = existingDep1.value;
    switch (value) {
      case Future<T> futureValue:
        return Result(() async {
          final value = await futureValue;
          _registerDependency<T>(
            dependency: Dependency<T>(
              value,
              metadata: existingDep1.metadata,
            ),
            checkExisting: false,
          );
          registry.removeDependency<Future<T>>(
            groupEntity: groupEntity1,
          );
          return Some(value);
        });
      case T _:
        return Ok(Some(value));
    }
  }

  Result<Option<Dependency<FutureOr<T>>>> _getDependency<T extends Object>({
    Entity groupEntity = const Entity.zero(),
    bool traverse = true,
    bool validate = true,
  }) {
    final groupEntity1 = groupEntity.isZero() ? focusGroup : groupEntity;
    var a = registry
        .getDependency<T>(groupEntity: groupEntity1)
        .or(registry.getDependency<Future<T>>(groupEntity: groupEntity1));
    if (a.isNone && traverse) {
      for (final parent in parents) {
        final test = parent._getDependency<T>(
          groupEntity: groupEntity1,
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

  /// Retrieves a dependency of type [T] or its subtypes registered under
  /// the specified [groupEntity] from the [registry].
  ///
  /// If the dependency is found, it is returned; otherwise, this method waits
  /// until the dependency is registered before returning it.
  ///
  /// If [traverse] is set to `true`, the search will also include all parent
  /// containers.
  Result<Option<FutureOr<T>>> until<T extends Object>({
    Entity groupEntity = const Entity.zero(),
    bool traverse = true,
  }) {
    final g = groupEntity.isZero() ? focusGroup : groupEntity;
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

    // If it's not already registered, register a Completer for the type
    // inside the untilsContainer.
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

    // Wait for the register function to complete the Completer, then unregister
    // the completer before returning the value.
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

  /// Unregisters all dependencies in the reverse order they were registered.
  ///
  /// If [onBeforeUnregister] is provided, it will be called before each
  /// dependency is unregistered. If [onAfterUnregister] is provided, it will
  /// be called after each dependency is unregistered. These methods are
  /// particularly useful for debugging, logging and additional cleanup logic.
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
                  dependency.metadata.map((e) => e.groupEntity).unwrapOr(const Entity.zero()),
            ),
        (_) => dependency.metadata.map((e) => e.onUnregister.ifSome((e) => e(dependency))),
        (_) => onAfterUnregister.ifSome((e) => e(dependency)),
      ]);
    }
    return sequential.add((_) => results);
  }
}
