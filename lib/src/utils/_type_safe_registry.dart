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

import 'package:meta/meta.dart' show internal;
import 'package:df_pod/df_pod.dart';

import '/src/_index.g.dart';

import '_dependency.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A type-safe registry for storing and managing dependencies of various types
/// within [DI]. This class provides methods for adding, retrieving, updating,
/// and removing dependencies, as well as checking if a specific dependency
/// exists.
@internal
final class TypeSafeRegistry {
  //
  //
  //

  /// Dependencies, organized by their type.
  final _pRegistry = Pod<TypeSafeRegistryMap>({});

  PodListenable<TypeSafeRegistryMap> get pRegistry => _pRegistry;

  /// A snapshot describing the current state of the dependencies.
  TypeSafeRegistryMap get state =>
      Map<Type, Map<DIKey, Dependency<dynamic>>>.unmodifiable(_pRegistry.value)
          .map((k, v) => MapEntry(k, Map.unmodifiable(v)));

  TypeSafeRegistry();

  /// Returns the dependency of type [T] with the specified [key] if it
  /// exists, or `null`.
  Dependency<T>? getDependency<T>(DIKey key) {
    return getDependencyOfType(T, key) as Dependency<T>?;
  }

  /// Returns all dependencies of [types] and [key].
  Iterable<Dependency<dynamic>> getDependenciesOfTypes(
    List<Type> types,
    DIKey key,
  ) {
    return types.map((type) => getDependencyOfType(type, key)).nonNulls;
  }

  Dependency<dynamic>? getDependencyOfType(Type type, DIKey key) {
    return _pRegistry.value[type]?[key];
  }

  /// Adds or updates a dependency of type [T] with the specified [key].
  ///
  /// If a dependency with the same type [T] and [key] already exists, it will
  /// be overwritten.
  void setDependency<T>(DIKey key, Dependency<T> dependency) {
    setDependencyOfType(T, key, dependency);
  }

  void setDependencyOfType(Type type, DIKey key, Dependency<dynamic> dependency) {
    final deps = getDependencyMapOfType(type) ?? <DIKey, Dependency<dynamic>>{};
    deps[key] = dependency;
    setDependencyMapOfType(type, deps);
  }

  /// Removes a dependency of type [T] with the specified [key] then returns
  /// the removed dependency if it existed, or `null`.
  Dependency<T>? removeDependency<T>(DIKey key) {
    return removeDependencyOfType(T, key) as Dependency<T>?;
  }

  /// Removes all dependencies of [types] and [key] and returns the removed
  /// dependencies.
  Iterable<Dependency<dynamic>> removeDependenciesOfTypes(
    List<Type> types,
    DIKey key,
  ) {
    return types.map((type) => removeDependencyOfType(type, key)).nonNulls;
  }

  Dependency<dynamic>? removeDependencyOfType(Type type, DIKey key) {
    final typeMap = getDependencyMapOfType(type);
    if (typeMap != null) {
      final removed = typeMap.remove(key);
      if (typeMap.isEmpty) {
        removeDependencyMapOfType(type);
      } else {
        setDependencyMapOfType(type, typeMap);
      }
      return removed;
    }
    return null;
  }

  /// Checks if a dependency of type [T] with the specified [key] exists.
  ///
  /// Returns `true` if the dependency exists, otherwise `false`.
  bool containsDependency<T>(DIKey key) {
    return containsDependencyOfType(T, key);
  }

  bool containsDependencyOfType(Type type, DIKey key) {
    return getDependencyMapOfType(type)?.containsKey(key) ?? false;
  }

  /// Retrieves all dependencies of type [T].
  ///
  /// Returns an iterable of all registered dependencies of type [T]. If none
  /// exist, an empty iterable is returned.
  Iterable<Dependency<dynamic>> getAllDependencies<T>() {
    return getAllDependenciesOfType(T);
  }

  Iterable<Dependency<dynamic>> getAllDependenciesOfType(Type type) {
    return getDependencyMapOfType(type)?.values ?? const Iterable.empty();
  }

  /// Sets the map of dependencies for type [T].
  ///
  /// This method is used internally to update the stored dependencies for a
  /// specific type [T].
  void setDependencyMap<T>(DependencyMap<T> deps) {
    setDependencyMapOfType(T, deps);
  }

  void setDependencyMapOfType<T>(Type type, DependencyMap<T> deps) {
    _pRegistry.update((e) => e..[type] = deps);
  }

  /// Retrieves the map of dependencies for type [T].
  ///
  /// Returns the map of dependencies for the specified type [T], or `null` if
  /// no dependencies of this type are registered.
  DependencyMap<T>? getDependencyMap<T>() {
    return getDependencyMapOfType(T) as DependencyMap<T>?;
  }

  DependencyMap<dynamic>? getDependencyMapOfType(Type type) {
    return _pRegistry.value[type];
  }

  /// Removes the entire map of dependencies for type [T].
  ///
  /// This method is used internally to remove all dependencies of a specific
  /// type [T].
  void removeDependencyMap<T>() {
    removeDependencyMapOfType(T);
  }
  
  void removeDependencyMapOfType(Type type) {
    _pRegistry.update((e) => e..remove(type));
  }

  /// Clears all registered dependencies.
  ///
  /// This method removes all entries from the registry, effectively resetting
  /// it.
  void clearRegistry() {
    _pRegistry.set({});
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A map of [Dependency], grouped by [DIKey].
typedef DependencyMap<T> = Map<DIKey, Dependency<T>>;

/// A map of [Dependency], grouped by [Type] and [DIKey].
typedef TypeSafeRegistryMap = Map<Type, DependencyMap<dynamic>>;
