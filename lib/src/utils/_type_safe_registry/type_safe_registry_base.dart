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
  Dependency<T>? getDependency<T extends Object>(DIKey key) =>
      getDependencyOfType(Key.type(T), key) as Dependency<T>?;

  /// Returns all dependencies of [types] and [key].
  Iterable<Dependency<Object>> getDependenciesOfTypes(
    Iterable<DIKey> types,
    DIKey key,
  ) {
    return types.map((type) => getDependencyOfType(type, key)).nonNulls;
  }

  Dependency<Object>? getDependencyOfType(DIKey type, DIKey key);

  /// Adds or updates a dependency of type [T] with the specified [key].
  ///
  /// If a dependency with the same type [T] and [key] already exists, it will
  /// be overwritten.
  void setDependency<T extends Object>(DIKey key, Dependency<T> dep) =>
      setDependencyOfType(Key.type(T), key, dep);

  void setDependencyOfType(
    DIKey type,
    DIKey key,
    Dependency<Object> dep,
  );

  Iterable<Dependency<Object>> getDependenciesWithKey(DIKey key);

  /// Removes a dependency of type [T] with the specified [key] then returns
  /// the removed dependency if it existed, or `null`.
  Dependency<T>? removeDependency<T extends Object>(DIKey key) =>
      removeDependencyOfType(Key.type(T), key) as Dependency<T>?;

  /// Removes all dependencies of [types] and [key] and returns the removed
  /// dependencies.
  Iterable<Dependency<Object>> removeDependenciesOfTypes(Iterable<DIKey> types, DIKey key) =>
      types.map((type) => removeDependencyOfType(type, key)).nonNulls;

  Dependency<Object>? removeDependencyOfType(DIKey type, DIKey key);

  /// Checks if a dependency of type [T] with the specified [key] exists.
  ///
  /// Returns `true` if the dependency exists, otherwise `false`.
  bool containsDependency<T>(DIKey key) => containsDependencyOfType(Key.type(T), key);

  @pragma('vm:prefer-inline')
  bool containsDependencyOfType(DIKey type, DIKey key) =>
      getDependencyMapOfType(type)?.containsKey(key) ?? false;

  /// Retrieves all dependencies of type [T].
  ///
  /// Returns an iterable of all registered dependencies of type [T]. If none
  /// exist, an empty iterable is returned.
  @pragma('vm:prefer-inline')
  Iterable<Dependency<Object>> getAllDependencies<T extends Object>() =>
      getAllDependenciesOfType(Key.type(T));

  @pragma('vm:prefer-inline')
  Iterable<Dependency<Object>> getAllDependenciesOfType(DIKey type) =>
      getDependencyMapOfType(type)?.values ?? const Iterable.empty();

  /// Sets the map of dependencies for type [T].
  ///
  /// This method is used internally to update the stored dependencies for a
  /// specific type [T].
  void setDependencyMap<T extends Object>(DependencyMap<T> deps) =>
      setDependencyMapOfType(Key.type(T), deps);

  void setDependencyMapOfType<T extends Object>(DIKey type, DependencyMap<T> deps);

  /// Retrieves the map of dependencies for type [T].
  ///
  /// Returns the map of dependencies for the specified type [T], or `null` if
  /// no dependencies of this type are registered.
  @pragma('vm:prefer-inline')
  DependencyMap<T>? getDependencyMap<T extends Object>() =>
      getDependencyMapOfType(Key.type(T)) as DependencyMap<T>?;

  DependencyMap<Object>? getDependencyMapOfType(DIKey type);

  /// Removes the entire map of dependencies for type [T].
  ///
  /// This method is used internally to remove all dependencies of a specific
  /// type [T].
  @pragma('vm:prefer-inline')
  void removeDependencyMap<T extends Object>() => removeDependencyMapOfType(Key.type(T));

  void removeDependencyMapOfType(DIKey type);

  /// Clears all registered dependencies.
  ///
  /// This method removes all entries from the registry, effectively resetting
  /// it.
  void clearRegistry();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A map of [Dependency], grouped by [DIKey].
typedef DependencyMap<T extends Object> = Map<DIKey, Dependency<T>>;

/// A map of [Dependency], grouped by [DIKey] and [DIKey].
typedef TypeSafeRegistryMap = Map<DIKey, DependencyMap<Object>>;
