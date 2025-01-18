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

import 'dart:async';

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
  Entity focusGroup = const DefaultEntity();

  /// A container storing Future completions.
  @protected
  Option<DIBase> completers = const None();

  /// Returns the total number of registered dependencies.
  @protected
  int dependencyCount = 0;

  Result<Option<Resolvable<T>>> register<T extends Object>({
    required FutureOr<T> Function() unsafe,
    Entity groupEntity = const DefaultEntity(),
    Option<DependencyValidator<Resolvable<T>>> validator = const None(),
    Option<OnUnregisterCallback<Resolvable<T>>> onUnregister = const None(),
  }) {
    final g = groupEntity.isDefault() ? focusGroup : groupEntity;
    final metadata = DependencyMetadata(
      index: Some(dependencyCount++),
      groupEntity: g,
      validator: validator.map((f) => (e) => f(e as Resolvable<T>)),
      onUnregister: onUnregister.map((f) => (e) => f(e as Resolvable<T>)),
    );
    final value = Resolvable.unsafe(unsafe);
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
    if (completers.isSome()) {
      final a = completers.unwrap();
      final b = a.registry
          .getDependency<CompleterOr<Resolvable<T>>>(groupEntity: groupEntity)
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

      if (b.isSome()) {
        (b.unwrap() as CompleterOr?)?.complete(value);
      }
    }
  }

  Result<Option<Dependency<T>>> _registerDependency<T extends Object>({
    required Dependency<T> dependency,
    bool checkExisting = false,
  }) {
    assert(
      T != Object,
      'T must be specified and cannot be Object.',
    );

    // ignore: invalid_use_of_visible_for_testing_member
    final g = dependency.metadata.isSome() ? dependency.metadata.unwrap().groupEntity : focusGroup;
    if (checkExisting) {
      final dep = getDependency<T>(
        groupEntity: g,
        traverse: false,
        validate: false,
      );
      if (dep.isErr()) {
        return dep.err().cast();
      }
      if (dep.unwrap().isSome()) {
        return const Err(
          stack: ['DIBase', '_registerDependency'],
          error: 'Dependency already registered.',
        );
      }
    }
    registry.setDependency(dependency);
    return Ok(Some(dependency));
  }

  Option<Resolvable<Object>> unregister<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool skipOnUnregisterCallback = false,
  }) {
    final g = groupEntity.isDefault() ? focusGroup : groupEntity;
    final removed = registry
        .removeDependency<T>(groupEntity: g)
        .or(registry.removeDependency<Future<T>>(groupEntity: g))
        .or(registry.removeDependency<Lazy<T>>(groupEntity: g));
    if (removed.isNone()) {
      return const None();
    }
    final removedDependency = removed.unwrap() as Dependency;
    if (skipOnUnregisterCallback) {
      return Some(Sync(Ok(removedDependency.value)));
    }
    final metadata = removedDependency.metadata;
    if (metadata.isSome()) {
      final onUnregister = metadata.unwrap().onUnregister;
      if (onUnregister.isSome()) {
        return Some(
          onUnregister.unwrap()(removedDependency).map((_) => removedDependency),
        );
      }
    }
    return Some(Sync(Ok(removedDependency.value)));
  }

  bool isRegistered<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.isDefault() ? focusGroup : groupEntity;
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

  Future<T> getAsyncUnsafe<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getAsync<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).then((e) => e.unwrap().unwrap());
  }

  Future<Result<Option<T>>> getAsync<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return get<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).toAsync().value;
  }

  // Result<Option<T>> getSync<T extends Object>({
  //   Entity groupEntity = const Entity.defaultEntity(),
  //   bool traverse = true,
  // }) {
  //   final value = get<T>(
  //     groupEntity: groupEntity,
  //     traverse: traverse,
  //   );
  //   if (value.isErr) {
  //     return value.err.cast();
  //   }
  //   return Result(
  //     () {
  //       PanicIf(
  //         value.unwrap().isSome && value.unwrap() is Future,
  //         'getSync cannot return a Future.',
  //       );
  //       return value.unwrap().map((e) => e as T);
  //     },
  //   );
  // }

  ResolvableOption<T> get<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.isDefault() ? focusGroup : groupEntity;
    final dep = getDependency<T>(
      groupEntity: g,
      traverse: traverse,
    );

    if (dep.isErr()) {
      return Sync(dep.err().cast());
    }
    if (dep.unwrap().isNone()) {
      return const Sync(Ok(None()));
    }
    final value = dep.unwrap().unwrap().value;
    if (value.isAsync()) {
      return Async.unsafe(() {
        final futureValue = value.async().unwrap().value.then((e) {
          final value = e.unwrap();
          _registerDependency<T>(
            dependency: Dependency<T>(
              Sync(Ok(value)),
              metadata: dep.unwrap().unwrap().metadata,
            ),
            checkExisting: false,
          );
          registry.removeDependency<Async<T>>(
            groupEntity: g,
          );
          return value;
        });
        return futureValue.then((e) => Some(e));
      });
    } else {
      return value.map((e) => Some(e));
    }
  }

  @protected
  Result<Option<Dependency<T>>> getDependency<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    bool validate = true,
  }) {
    final g = groupEntity.isDefault() ? focusGroup : groupEntity;
    var dep = registry.getDependency<T>(groupEntity: g);
    if (dep.isNone() && traverse) {
      for (final parent in parents) {
        final test = parent.getDependency<T>(
          groupEntity: g,
        );
        if (test.isErr()) {
          return test;
        }
        dep = test.unwrap();
        if (dep.isSome()) {
          break;
        }
      }
    }
    if (dep.isSome()) {
      final dependency = dep.unwrap() as Dependency;
      if (validate) {
        final metadata = dependency.metadata;
        if (metadata.isSome()) {
          final valid = metadata.unwrap().validator.map((e) => e(dependency));
          if (valid.isSome() && !valid.unwrap()) {
            return const Err(
              stack: ['DIBase', '_getDependency'],
              error: 'Dependency validation failed.',
            );
          }
        }
      }
      return Ok(Some(dependency.cast()));
    }
    return const Ok(None());
  }

  // Result<Option<Resolvable<T>>> until<T extends Object>({
  //   Entity groupEntity = const Entity.defaultEntity(),
  //   bool traverse = true,
  // }) {
  //   final g = groupEntity.isDefault() ? focusGroup : groupEntity;
  //   final test = get<T>(groupEntity: g);
  //   if (test.isErr()) {
  //     return test.err().cast();
  //   }
  //   if (test.unwrap().isSome()) {
  //     return test;
  //   }
  //   if (completers.isSome()) {
  //     final dep = completers.unwrap().registry.getDependency<CompleterOr<Resolvable<T>>>(
  //           groupEntity: g,
  //         );
  //     final completer = dep.unwrap().value;
  //     return Ok(Some(Resolvable.unsafe(functionCanThrow)));
  //   }

  //   if (completers.isNone()) {
  //     completers = Some(DIBase());
  //   }

  //   final completer = CompleterOr<Resolvable<T>>();
  //   completers.unwrap().registry.setDependency(
  //         Dependency<CompleterOr<Resolvable<T>>>(
  //           completer,
  //           metadata: Some(
  //             DependencyMetadata(
  //               groupEntity: g,
  //             ),
  //           ),
  //         ),
  //       );

  //   return Ok(
  //     Some(
  //       completer.futureOr.thenOr((value) {
  //         completers.unwrap().registry.removeDependency<CompleterOr<Resolvable<T>>>(
  //               groupEntity: g,
  //             );
  //         return get<T>(
  //           groupEntity: groupEntity,
  //           traverse: traverse,
  //         ).unwrap().unwrap();
  //       }),
  //     ),
  //   );
  // }

  Resolvable<List<Dependency>> unregisterAll({
    Option<OnUnregisterCallback<Dependency>> onBeforeUnregister = const None(),
    Option<OnUnregisterCallback<Dependency>> onAfterUnregister = const None(),
  }) {
    final results = List.of(registry.dependencies);
    final sequential = Sequential();
    for (final dependency in results) {
      sequential.addAll([
        (_) {
          onBeforeUnregister.ifSome((e) => e.unwrap()(dependency));
          return const None();
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
          onAfterUnregister.ifSome((e) => e.unwrap()(dependency));
          return const None();
        },
      ]);
    }
    return sequential.add((_) => Some(results));
  }
}
