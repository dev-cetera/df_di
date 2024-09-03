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

  /// Retrieves the dependency of type [T] or any subtype associated with
  /// the specified [group].
  ///
  /// Returns `null` if no matching dependency is found.
  Dependency<Object>? getDependencyOrNull<T extends Object>({
    required Descriptor group,
  }) {
    final deps = getDependenciesByKey(group: group);
    return deps.where((e) {
      return e.value is T;
    }).firstOrNull;
  }

  /// Retrieves the dependency of the exact [type] associated with the
  /// specified [group].
  ///
  /// Returns `null` if no matching dependency is found.
  Dependency<Object>? getDependencyUsingExactTypeOrNull({
    required Descriptor type,
    required Descriptor group,
  }) {
    final deps = getDependenciesByKey(group: group);
    return deps.where((e) => Descriptor.type(e.type) == type).firstOrNull?.cast();
  }

  /// Retrieves all dependencies associated with the specified [group].
  Iterable<Dependency<Object>> getDependenciesByKey({
    required Descriptor group,
  });

  //
  //
  //

  /// Adds or overwrites the dependency of type [T] with the specified [value].
  @pragma('vm:prefer-inline')
  void setDependency<T extends Object>({
    required Dependency<T> value,
  }) {
    setDependencyUsingExactType(
      type: Descriptor.type(T),
      value: value,
    );
  }

  /// Adds or overwrites the dependency of the exact [type] with the specified
  /// [value].
  void setDependencyUsingExactType({
    required Descriptor type,
    required Dependency<Object> value,
  });

  //
  //
  //

  /// Removes the dependency of type [T] or any subtype associated with the
  /// specified [group] if it exists.
  ///
  /// Returns the removed value, or `null` if it does not exist.
  Dependency<T>? removeDependency<T extends Object>({
    required Descriptor group,
  }) {
    final dep = getDependencyOrNull<T>(group: group);
    if (dep != null) {
      final removed = removeDependencyUsingExactType(
        type: Descriptor.type(dep.type),
        group: group,
      );
      return removed?.cast();
    }
    return null;
  }

  /// Removes the dependency of the exact [type] or any subtype associated with
  /// the specified [group] if it exists.
  ///
  /// Returns the removed value, or `null` if it does not exist.
  Dependency<Object>? removeDependencyUsingExactType({
    required Descriptor type,
    required Descriptor group,
  });

  //
  //
  //

  @pragma('vm:prefer-inline')
  bool containsDependencyUsingExactType({
    required Descriptor type,
    required Descriptor group,
  }) {
    return getDependencyUsingExactTypeOrNull(type: type, group: group) != null;
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
    required Descriptor group,
  }) {
    return getDependencyMapByKey(group: group)?.values ?? const Iterable.empty();
  }

  /// Sets the map of dependencies for a given [group].
  void setDependencyMapByKey({
    required Descriptor group,
    required DependencyMap value,
  });

  /// ...
  DependencyMap<Object>? getDependencyMapByKey({
    required Descriptor group,
  });

  /// ...
  void removeDependencyMapUsingExactType({
    required Descriptor type,
  });

  /// Clears all registered dependencies.
  ///
  /// This method removes all entries from the registry, effectively resetting
  /// it.
  void clearRegistry();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A map of [Dependency], grouped by [Descriptor].
typedef DependencyMap<T extends Object> = Map<Descriptor, Dependency<T>>;

/// A map of [Dependency], grouped by [Descriptor] and [Descriptor].
typedef TypeSafeRegistryMap = Map<Descriptor, DependencyMap<Object>>;
