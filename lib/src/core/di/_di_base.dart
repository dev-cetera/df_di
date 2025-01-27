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

  // TODO:
  // Iterable<DIBase> get children {
  //    registry.dependencies.whereType<Dependency<DIBase>>().map((e) => e.value);
  // }

  /// A key that identifies the current group in focus for dependency management.
  Entity focusGroup = const DefaultEntity();

  /// A container storing Future completions.
  @protected
  Option<DIBase> completers = const None();

  @protected
  int _indexIncrementer = 0;

  Result<Resolvable<T>> register<T extends Object>({
    required FutureOr<T> Function() unsafe,
    Entity groupEntity = const DefaultEntity(),
    Option<DependencyValidator<Resolvable<T>>> validator = const None(),
    Option<OnUnregisterCallback<Resolvable<T>>> onUnregister = const None(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final metadata = DependencyMetadata(
      index: Some(_indexIncrementer++),
      groupEntity: g,
      validator: validator.map((f) => (e) => f(e as Resolvable<T>)),
      onUnregister: onUnregister.map((f) => (e) => f(e as Resolvable<T>)),
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
      // TODO: MUST ALSO LOOK AT CHILDREN AND COMPLETE ALL COMPLETERS, could be more than 1.
      final b = a.registry.getDependency<SafeCompleter<T>>(groupEntity: groupEntity).or(
            // MAY NOT WORK!!!
            a.registry.getDependencyK(
              TypeEntity(SafeCompleter<Object>, [value.runtimeType]),
              groupEntity: groupEntity,
            ),
          );

      if (b.isSome()) {
        final test = (b.unwrap() as Dependency).value.sync().unwrap().value;
        if (test.isErr()) {
          // TODO:
          return Err(
            stack: [],
            error: '',
          );
        }
        (test.unwrap() as SafeCompleter).resolve(value);
      }
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

    // ignore: invalid_use_of_visible_for_testing_member
    final g = dependency.metadata.isSome() ? dependency.metadata.unwrap().groupEntity : focusGroup;
    if (checkExisting) {
      final test = getDependency<T>(
        groupEntity: g,
        traverse: false,
        validate: false,
      );
      if (test.isSome()) {
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
              Err<T>(
                stack: ['DIBase', 'getSync'],
                error: 'Called getSync() an async dependency.',
              ),
            ),
    );
  }

  Option<Async<T>> getAsync<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return get<T>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.toAsync());
  }

  Option<Resolvable<T>> get<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final test = getDependency<T>(
      groupEntity: g,
      traverse: traverse,
    );
    if (test.isNone()) {
      return const None();
    }
    final result = test.unwrap();
    if (result.isErr()) {
      return Some(Sync(result.err().castErr()));
    }
    final value = result.unwrap().value;
    if (value.isSync()) {
      return Some(value);
    }

    return Some(
      Async.unsafe(
        () => value.async().unwrap().value.then((e) {
          final value = e.unwrap();
          _registerDependency<T>(
            dependency: Dependency<T>(
              Sync(Ok(value)),
              metadata: test.unwrap().unwrap().metadata,
            ),
            checkExisting: false,
          );
          registry.removeDependency<Async<T>>(
            groupEntity: g,
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
    bool validate = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final test = registry.getDependency<T>(groupEntity: g);
    var temp = test.map((e) => Ok(e).result());
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

    if (temp.isSome()) {
      if (validate) {
        final result = temp.unwrap();
        if (result.isErr()) {
          return Some(result);
        }
        final dependency = result.unwrap();
        final metadata = dependency.metadata;
        if (metadata.isSome()) {
          final valid = metadata.unwrap().validator.map((e) => e(dependency));
          if (valid.isSome() && !valid.unwrap()) {
            return const Some(
              Err(
                stack: ['DIBase', 'getDependency'],
                error: 'Dependency validation failed.',
              ),
            );
          }
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
      final test = completers.unwrap().registry.getDependency<SafeCompleter<T>>(
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
    final completer = SafeCompleter<T>();
    completers.unwrap().registry.setDependency(
          Dependency<SafeCompleter<T>>(
            Sync(Ok(completer)),
            metadata: Some(
              DependencyMetadata(
                groupEntity: g,
              ),
            ),
          ),
        );
    return completer.resolvable.map((e) {
      completers.unwrap().registry.removeDependency<SafeCompleter<T>>(
            groupEntity: g,
          );
      return e;
      //return get<T>();
    });
  }

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
