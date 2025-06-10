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

/// A mixin that provides methods for working with dependencies,
/// using `Entity` for type resolution.
base mixin SupportsMixinK on DIBase {
  /// Retrieves the synchronous dependency unsafely, returning the instance
  /// directly.
  @pragma('vm:prefer-inline')
  T getSyncUnsafeK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getSyncK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().value.unwrap();
  }

  /// Retrieves the synchronous dependency.
  Option<Sync<T>> getSyncK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).map(
      (e) => e.isSync()
          ? e.sync().unwrap()
          : Sync.value(Err('Called getSyncK() an async dependency.')),
    );
  }

  /// Retrieves an asynchronous dependency unsafely, returning a future of the
  /// instance, directly or throwing an error if not found.
  @pragma('vm:prefer-inline')
  Future<T> getAsyncUnsafeK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return Future.sync(() async {
      final result = await getAsyncK<T>(
        typeEntity,
        groupEntity: groupEntity,
        traverse: traverse,
      ).unwrap().value;
      return result.unwrap();
    });
  }

  /// Retrieves an asynchronous dependency.
  @pragma('vm:prefer-inline')
  Option<Async<T>> getAsyncK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).map((e) => e.toAsync());
  }

  /// Retrieves a dependency unsafely, returning it directly or throwing an
  /// error if not found.
  @pragma('vm:prefer-inline')
  FutureOr<T> getUnsafeK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getK<T>(
      typeEntity,
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().unwrap();
  }

  /// Retrieves the synchronous dependency or `None` if not found or async.
  Option<T> getSyncOrNoneK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final option = getK<T>(
      typeEntity,
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
    final value = result.transf<T>().unwrap();
    return Some(value);
  }

  /// Retrieves the dependency.
  Option<Resolvable<T>> getK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final option = getDependencyK<T>(
      typeEntity,
      groupEntity: g,
      traverse: traverse,
    );
    if (option.isNone()) {
      return const None();
    }
    final result = option.unwrap();
    if (result.isErr()) {
      return Some(Sync.value(result.err().unwrap().transfErr()));
    }
    final value = result.unwrap().value;
    if (value.isSync()) {
      return Some(value);
    }
    return Some(
      Async(
        () => value.async().unwrap().value.then((e) {
          final value = e.unwrap();
          registry.removeDependencyK(typeEntity, groupEntity: g);
          final metadata = option.unwrap().unwrap().metadata.map(
            (e) => e.copyWith(
              preemptivetypeEntity: TypeEntity(Sync, [typeEntity]),
            ),
          );
          registerDependencyK(
            dependency: Dependency(Sync.value(Ok(value)), metadata: metadata),
            checkExisting: false,
          );
          return value;
        }),
      ),
    );
  }

  /// Retrieves the underlying `Dependency` object.
  Result<Dependency<T>> registerDependencyK<T extends Object>({
    required Dependency<T> dependency,
    bool checkExisting = false,
  }) {
    final g = dependency.metadata.isSome()
        ? dependency.metadata.unwrap().groupEntity
        : focusGroup;
    if (checkExisting) {
      final option = getDependencyK(
        dependency.typeEntity,
        groupEntity: g,
        traverse: false,
      );
      if (option.isSome()) {
        return Err('Dependency already registered.');
      }
    }
    registry.setDependency(dependency);
    return Ok(dependency);
  }

  /// Retrieves the underlying `Dependency` object.
  Option<Result<Dependency<T>>> getDependencyK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final option = registry.getDependencyK(typeEntity, groupEntity: g);
    var temp = option.map((e) => Ok(e).transf<Dependency<T>>());
    if (option.isNone() && traverse) {
      for (final parent in parents) {
        temp = (parent as SupportsMixinK).getDependencyK(
          typeEntity,
          groupEntity: g,
        );
        if (temp.isSome()) {
          break;
        }
      }
    }
    return temp;
  }

  /// Unregisters a dependency.
  Resolvable<None> unregisterK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    bool removeAll = true,
    bool triggerOnUnregisterCallbacks = true,
  }) {
    final seq = SafeSequencer();
    final g = groupEntity.preferOverDefault(focusGroup);
    for (final di in [this as DI, ...parents]) {
      final dependencyOption = di.removeDependencyK(typeEntity, groupEntity: g);
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
            seq.addSafe((_) => dependency.value.map((e) => Some(e)));
            seq.addSafe((e) {
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
    return seq.last;
  }

  /// Removes a dependency from the registry.
  @pragma('vm:prefer-inline')
  Option<Dependency> removeDependencyK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    var result = registry.removeDependencyK(typeEntity, groupEntity: g);
    if (result.isNone()) {
      result = registry.removeDependencyK(
        TypeEntity(Lazy, [typeEntity]),
        groupEntity: g,
      );
    }
    return result;
  }

  /// Checks if a dependency is registered.
  bool isRegisteredK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (registry.containsDependencyK(typeEntity, groupEntity: g) ||
        registry.containsDependencyK(
          TypeEntity(Lazy, [typeEntity]),
          groupEntity: g,
        )) {
      return true;
    }
    if (traverse) {
      for (final parent in parents) {
        if ((parent as SupportsMixinK).isRegisteredK(
          typeEntity,
          groupEntity: g,
          traverse: true,
        )) {
          return true;
        }
      }
    }
    return false;
  }

  /// Waits until a dependency with the exact `typeEntity` is registered.
  /// The result is cast to `T`.
  ///
  /// **Note:** Requires `enableUntilExactlyK: true` during registration.
  /// If `typeEntity` doesn't match an existing or future registration exactly,
  /// this will not resolve.
  Resolvable<T> untilExactlyK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final test = getK(typeEntity, groupEntity: g);
    if (test.isSome()) {
      return test.unwrap().map((e) => e as T);
    }
    var finisher = finishersK[g]?.firstWhereOrNull(
      (e) => e.typeEntity == typeEntity,
    );
    if (finisher == null) {
      finisher = ReservedSafeCompleter(typeEntity);
      (finishersK[g] ??= []).add(finisher);
    }
    return finisher.resolvable().map((_) {
      final temp = finishersK[g] ?? [];
      for (var n = 0; n < temp.length; n++) {
        final e = temp[n];
        if (e.typeEntity == typeEntity) {
          temp.removeAt(n);
          break;
        }
      }
      return getK<T>(typeEntity, groupEntity: g).unwrap();
    }).flatten();
  }

  /// Stores finishers for [untilExactlyK].
  final finishersK = <Entity, List<ReservedSafeCompleter>>{};

  /// Attempts to finish any pending [untilExactlyK] calls for the given
  /// type and group.
  void maybeFinishK<T extends Object>({required Entity g}) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final typeEntity = TypeEntity(T);
    for (final di in [this as DI, ...children().unwrapOr([])]) {
      final test = di.finishersK[g]?.firstWhereOrNull((e) {
        return e is ReservedSafeCompleter<T> || e.typeEntity == typeEntity;
      });
      if (test != null) {
        test.complete(const None());
        break;
      }
    }
  }
}
