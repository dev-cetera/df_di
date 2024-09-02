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
    final entry = getDepMapEntry<T>();
    if (entry != null) {
      final type = entry.key;
      return getDependencyByExactType(
        type: type,
        key: key,
      ) as Dependency<T>?;
    }
    return null;
  }

  Dependency<Object>? getDependencyByExactType({
    required Identifier type,
    required Identifier key,
  });

  /// Adds or updates a dependency of type [T] with the specified [key].
  ///
  /// If a dependency with the same type [T] and [key] already exists, it will
  /// be overwritten.
  void setDependency<T extends Object>({
    required Identifier key,
    required Dependency<T> dep,
  }) {
    final entry = getDepMapEntry<T>();
    if (entry != null) {
      final type = entry.key;
      setDependencyByExactType(
        key: key,
        type: type,
        dep: dep,
      );
    }
  }

  void setDependencyByExactType({
    required Identifier type,
    required Identifier key,
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
    final entry = getDepMapEntry<T>();
    if (entry != null) {
      final type = entry.key;
      return removeDependencyByExactType(
        type: type,
        key: key,
      ) as Dependency<T>?;
    }
    return null;
  }

  Dependency<Object>? removeDependencyByExactType({
    required Identifier type,
    required Identifier key,
  });

  /// Checks if a dependency of type [T] with the specified [key] exists.
  ///
  /// Returns `true` if the dependency exists, otherwise `false`.
  @pragma('vm:prefer-inline')
  bool containsDependency<T extends Object>({
    required Identifier key,
  }) {
    return getDependencyMap<T>()?.containsKey(key) ?? false;
  }

  @pragma('vm:prefer-inline')
  bool containsDependencyByExactType({
    required Identifier type,
    required Identifier key,
  }) {
    return getDependencyMapByExactType(type: type)?.containsKey(key) ?? false;
  }

  /// Retrieves all dependencies of type [T].
  ///
  /// Returns an iterable of all registered dependencies of type [T]. If none
  /// exist, an empty iterable is returned.
  @pragma('vm:prefer-inline')
  Iterable<Dependency<Object>> getAllDependencies<T extends Object>() {
    return getDependencyMap<T>()?.values ?? const Iterable.empty();
  }

  @pragma('vm:prefer-inline')
  Iterable<Dependency<Object>> getAllDependenciesByExactType({
    required Identifier type,
  }) {
    return getDependencyMapByExactType(type: type)?.values ?? const Iterable.empty();
  }

  /// Sets the map of dependencies for type [T].
  ///
  /// This method is used internally to update the stored dependencies for a
  /// specific type [T].
  void setDependencyMap<T extends Object>({
    required DependencyMap value,
  }) {
    final entry = getDepMapEntry<T>();
    if (entry != null) {
      final type = entry.key;
      setDependencyMapByExactType(
        type: type,
        value: value,
      );
    }
  }

  /// ...
  void setDependencyMapByExactType({
    required Identifier type,
    required DependencyMap value,
  });

  /// Retrieves the map of dependencies for type [T].
  ///
  /// Returns the map of dependencies for the specified type [T], or `null` if
  /// no dependencies of this type are registered.
  DependencyMap<T>? getDependencyMap<T extends Object>() {
    final entry = getDepMapEntry<T>();
    if (entry != null) {
      return getDependencyMapByExactType(type: entry.key)?.cast();
    }
    return null;
  }

  /// ...
  DependencyMap<Object>? getDependencyMapByExactType({
    required Identifier type,
  });

  /// Removes the entire map of dependencies for type [T].
  ///
  /// This method is used internally to remove all dependencies of a specific
  /// type [T].
  void removeDependencyMap<T extends Object>() {
    final entry = getDepMapEntry<T>();
    if (entry != null) {
      removeDependencyMapByExactType(type: entry.key);
    }
  }

  /// ...
  void removeDependencyMapByExactType({
    required Identifier type,
  });

  /// Clears all registered dependencies.
  ///
  /// This method removes all entries from the registry, effectively resetting
  /// it.
  void clearRegistry();

  /// ...
  MapEntry<Identifier, DependencyMap<T>>? getDepMapEntry<T extends Object>();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A map of [Dependency], grouped by [Identifier].
typedef DependencyMap<T extends Object> = Map<Identifier, Dependency<T>>;

/// A map of [Dependency], grouped by [Identifier] and [Identifier].
typedef TypeSafeRegistryMap = Map<Identifier, DependencyMap<Object>>;
