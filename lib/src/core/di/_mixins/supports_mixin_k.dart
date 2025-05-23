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

base mixin SupportsMixinK on DIBase {
  //
  //
  //

  @protected
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

  @protected
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

  @protected
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

  @protected
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

  @protected
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

  @protected
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

  @protected
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
      return Some(Sync.value(result.err().transErr()));
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

  @protected
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

  @protected
  Option<Result<Dependency<T>>> getDependencyK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final option = registry.getDependencyK(typeEntity, groupEntity: g);
    var temp = option.map((e) => Ok(e).asResult().transf<Dependency<T>>());
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

  @protected
  Resolvable<None> unregisterK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    bool removeAll = true,
    bool triggerOnUnregisterCallbacks = true,
  }) {
    final sequential = SafeSequential();
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
  Option<Dependency> removeDependencyK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    return registry
            .removeDependencyK<T>(typeEntity, groupEntity: g)
            .or(
              registry.removeDependencyK<Lazy<T>>(
                TypeEntity(Lazy, [typeEntity]),
                groupEntity: g,
              ),
            )
        as Option<Dependency>;
  }

  @protected
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

  @protected
  final finishersK = <Entity, List<ReservedSafeFinisher>>{};

  @protected
  void maybeFinishK<T extends Object>({required Entity g}) {
    assert(T != Object, 'T must be specified and cannot be Object.');
    final typeEntity = TypeEntity(T);
    for (final di in [this as DI, ...children().unwrapOr([])]) {
      final test = di.finishersK[g]?.firstWhereOrNull((e) {
        return e is ReservedSafeFinisher<T> || e.typeEntity == typeEntity;
      });
      if (test != null) {
        test.finish(const None());
        break;
      }
    }
  }

  /// You must register dependencies via [register] and set its parameter
  /// `enableUntilK` to true to use this method.
  @visibleForTesting
  @protected
  Resolvable<T> untilK<T extends Object>(
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
      finisher = ReservedSafeFinisher(typeEntity);
      (finishersK[g] ??= []).add(finisher);
    }
    return finisher.resolvable().map((_) {
      //
      //
      final temp = finishersK[g] ?? [];
      for (var n = 0; n < temp.length; n++) {
        final e = temp[n];
        if (e.typeEntity == typeEntity) {
          temp.removeAt(n);
          break;
        }
      }
      //
      //
      return getK<T>(typeEntity, groupEntity: g).unwrap();
    }).comb2();
  }
}
