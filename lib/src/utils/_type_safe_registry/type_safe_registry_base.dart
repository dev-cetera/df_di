//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/src/_index.g.dart';

import '/src/utils/_dependency.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract base class TypeSafeRegistryBase {
  //
  //
  //

  /// Returns the dependency of type [T] with the specified [key] if it
  /// exists, or `null`.
  Dependency<T>? getDependency<T extends Object>({
    required Identifier key,
  }) {
    final deps = getDependenciesByKey(key: key);
    return deps.where((e) => e.value is T).firstOrNull?.cast();
  }

  Dependency<Object>? getDependencyByExactType({
    required Identifier type,
    required Identifier key,
  }) {
    final deps = getDependenciesByKey(key: key);
    return deps.where((e) => Identifier.typeId(e.type) == type.value).firstOrNull?.cast();
  }

  /// Adds or updates a dependency of type [T] with the specified [key].
  ///
  /// If a dependency with the same type [T] and [key] already exists, it will
  /// be overwritten.
  void setDependency<T extends Object>({
    required Dependency<T> dep,
  }) {
    setDependencyByExactType(
      type: Identifier.typeId(T),
      dep: dep,
    );
  }

  void setDependencyByExactType({
    required Identifier type,
    required Dependency<Object> dep,
  });

  Iterable<Dependency<Object>> getDependenciesByKey({
    required Identifier key,
  });

  /// Removes a dependency of type [T] with the specified [key] then returns
  /// the removed dependency if it existed, or `null`.
  Dependency<T>? removeDependency<T extends Object>({
    required Identifier key,
  }) {
    final dep = getDependency<T>(key: key);
    if (dep != null) {
      return removeDependencyByExactType(
        type: Identifier.typeId(dep.type),
        key: key,
      ) as Dependency<T>?;
    }
    return null;
  }

  Dependency<Object>? removeDependencyByExactType({
    required Identifier type,
    required Identifier key,
  });


  @pragma('vm:prefer-inline')
  bool containsDependencyByExactType({
    required Identifier type,
    required Identifier key,
  }) {
    return getDependencyMapByKey(key: key)?.containsKey(type) ?? false;
  }

  /// Retrieves all dependencies of type [T].
  ///
  /// Returns an iterable of all registered dependencies of type [T]. If none
  /// exist, an empty iterable is returned.
  @pragma('vm:prefer-inline')
  // Iterable<Dependency<Object>> getAllDependencies<T extends Object>() {
  //   return getDependencyMap<T>()?.values ?? const Iterable.empty();
  // }

  @pragma('vm:prefer-inline')
  Iterable<Dependency<Object>> getAllDependenciesByKey({
    required Identifier key,
  }) {
    return getDependencyMapByKey(key: key)?.values ?? const Iterable.empty();
  }

  /// Sets the map of dependencies for a given [key].
  void setDependencyMapByKey({
    required Identifier key,
    required DependencyMap value,
  });


  /// ...
  DependencyMap<Object>? getDependencyMapByKey({
    required Identifier key,
  });

  /// ...
  void removeDependencyMapByExactType({
    required Identifier type,
  });

  /// Clears all registered dependencies.
  ///
  /// This method removes all entries from the registry, effectively resetting
  /// it.
  void clearRegistry();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A map of [Dependency], grouped by [Identifier].
typedef DependencyMap<T extends Object> = Map<Identifier, Dependency<T>>;

/// A map of [Dependency], grouped by [Identifier] and [Identifier].
typedef TypeSafeRegistryMap = Map<Identifier, DependencyMap<Object>>;
