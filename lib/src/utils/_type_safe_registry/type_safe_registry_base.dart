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
      getDependencyOfType(T, key) as Dependency<T>?;

  /// Returns all dependencies of [types] and [key].
  Iterable<Dependency<Object>> getDependenciesOfTypes(
    List<Type> types,
    DIKey key,
  ) {
    return types.map((type) => getDependencyOfType(type, key)).nonNulls;
  }

  Dependency<Object>? getDependencyOfType(Type type, DIKey key);

  /// Adds or updates a dependency of type [T] with the specified [key].
  ///
  /// If a dependency with the same type [T] and [key] already exists, it will
  /// be overwritten.
  void setDependency<T extends Object>(DIKey key, Dependency<T> dep) =>
      setDependencyOfType(T, key, dep);

  void setDependencyOfType(
    Type type,
    DIKey key,
    Dependency<Object> dep,
  );

  Iterable<Dependency<Object>> getDependenciesWithKey(DIKey key);

  /// Removes a dependency of type [T] with the specified [key] then returns
  /// the removed dependency if it existed, or `null`.
  Dependency<T>? removeDependency<T extends Object>(DIKey key) =>
      removeDependencyOfType(T, key) as Dependency<T>?;

  /// Removes all dependencies of [types] and [key] and returns the removed
  /// dependencies.
  Iterable<Dependency<Object>> removeDependenciesOfTypes(List<Type> types, DIKey key) =>
      types.map((type) => removeDependencyOfType(type, key)).nonNulls;

  Dependency<Object>? removeDependencyOfType(Type type, DIKey key);

  /// Checks if a dependency of type [T] with the specified [key] exists.
  ///
  /// Returns `true` if the dependency exists, otherwise `false`.
  bool containsDependency<T>(DIKey key) => containsDependencyOfType(T, key);

  @pragma('vm:prefer-inline')
  bool containsDependencyOfType(Type type, DIKey key) =>
      getDependencyMapOfType(type)?.containsKey(key) ?? false;

  /// Retrieves all dependencies of type [T].
  ///
  /// Returns an iterable of all registered dependencies of type [T]. If none
  /// exist, an empty iterable is returned.
  @pragma('vm:prefer-inline')
  Iterable<Dependency<Object>> getAllDependencies<T extends Object>() =>
      getAllDependenciesOfType(T);

  @pragma('vm:prefer-inline')
  Iterable<Dependency<Object>> getAllDependenciesOfType(Type type) =>
      getDependencyMapOfType(type)?.values ?? const Iterable.empty();

  /// Sets the map of dependencies for type [T].
  ///
  /// This method is used internally to update the stored dependencies for a
  /// specific type [T].
  void setDependencyMap<T extends Object>(DependencyMap<T> deps) => setDependencyMapOfType(T, deps);

  void setDependencyMapOfType<T extends Object>(Type type, DependencyMap<T> deps);

  /// Retrieves the map of dependencies for type [T].
  ///
  /// Returns the map of dependencies for the specified type [T], or `null` if
  /// no dependencies of this type are registered.
  @pragma('vm:prefer-inline')
  DependencyMap<T>? getDependencyMap<T extends Object>() =>
      getDependencyMapOfType(T) as DependencyMap<T>?;

  DependencyMap<Object>? getDependencyMapOfType(Type type);

  /// Removes the entire map of dependencies for type [T].
  ///
  /// This method is used internally to remove all dependencies of a specific
  /// type [T].
  @pragma('vm:prefer-inline')
  void removeDependencyMap<T extends Object>() => removeDependencyMapOfType(T);

  void removeDependencyMapOfType(Type type);

  /// Clears all registered dependencies.
  ///
  /// This method removes all entries from the registry, effectively resetting
  /// it.
  void clearRegistry();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A map of [Dependency], grouped by [DIKey].
typedef DependencyMap<T extends Object> = Map<DIKey, Dependency<T>>;

/// A map of [Dependency], grouped by [Type] and [DIKey].
typedef TypeSafeRegistryMap = Map<Type, DependencyMap<Object>>;
