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
  Dependency<T>? getDependencyOrNull<T extends Object>({
    required Identifier group,
  }) {
    final deps = getDependenciesByKey(group: group);
    return deps.where((e) => e.value is T).firstOrNull?.cast();
  }

  /// Retrieves the dependency of the exact [type] associated with the
  /// specified [group].
  ///
  /// Returns `null` if no matching dependency is found.
  Dependency<Object>? getDependencyOfExactTypeOrNull({
    required Identifier type,
    required Identifier group,
  }) {
    final deps = getDependenciesByKey(group: group);
    return deps.where((e) => Identifier.typeId(e.type) == type.value).firstOrNull?.cast();
  }

  /// Retrieves all dependencies associated with the specified [group].
  Iterable<Dependency<Object>> getDependenciesByKey({
    required Identifier group,
  });

  //
  //
  //

  /// Adds or overwrites the dependency of type [T] with the specified [value].
  @pragma('vm:prefer-inline')
  void setDependency<T extends Object>({
    required Dependency<T> value,
  }) {
    setDependencyOfExactType(
      type: Identifier.typeId(T),
      value: value,
    );
  }

  /// Adds or overwrites the dependency of the exact [type] with the specified
  /// [value].
  void setDependencyOfExactType({
    required Identifier type,
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
    required Identifier group,
  }) {
    final dep = getDependencyOrNull<T>(group: group);
    if (dep != null) {
      final removed = removeDependencyOfExactType(
        type: Identifier.typeId(dep.type),
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
  Dependency<Object>? removeDependencyOfExactType({
    required Identifier type,
    required Identifier group,
  });

  //
  //
  //

  @pragma('vm:prefer-inline')
  bool containsDependencyOfExactType({
    required Identifier type,
    required Identifier group,
  }) {
    return getDependencyOfExactTypeOrNull(type: type, group: group) != null;
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
    required Identifier group,
  }) {
    return getDependencyMapByKey(group: group)?.values ?? const Iterable.empty();
  }

  /// Sets the map of dependencies for a given [group].
  void setDependencyMapByKey({
    required Identifier group,
    required DependencyMap value,
  });

  /// ...
  DependencyMap<Object>? getDependencyMapByKey({
    required Identifier group,
  });

  /// ...
  void removeDependencyMapOfExactType({
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
