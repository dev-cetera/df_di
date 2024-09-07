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

import '/src/_internal.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// registry for storing and managing dependencies of by ther generic type,
/// runtime type and groupKey.
final class Registry {
  //
  //
  //

  Registry({this.onChange});

  /// Represents the internal state of this [Registry] instance, stored as a
  /// map.
  final RegistryState _state = {};

  /// A callback invoked whenever the [state] is updated.
  final _OnChangeRegistry? onChange;

  /// A snapshot describing the current state of the dependencies.
  RegistryState get state => Map<DIKey, Map<DIKey, Dependency>>.unmodifiable(state)
      .map((k, v) => MapEntry(k, Map.unmodifiable(v)));

  /// A snapshot of the current groups
  List<DIKey> get groupKeys => state.keys.toList();

  /// Updates the [state] by setting or updating [dependency].
  /// @protected
  @pragma('vm:prefer-inline')
  void setDependency<T extends Object>({
    required Dependency<T> dependency,
  }) {
    setDependencyOfType(dependency: dependency);
  }

  /// Updates the [state] by setting or updating [dependency].
  void setDependencyOfType({
    required Dependency dependency,
  }) {
    final groupKey = dependency.metadata.groupKey;
    final type = dependency.type;
    final previous = _state[groupKey]?[type];
    if (previous != dependency) {
      (_state[groupKey] ??= {})[type] = dependency;
      onChange?.call(state);
    }
  }

  /// Checks if any dependency of type [T] or subtype of [T] exists in the
  /// specified [groupKey].
  ///
  /// Returns `true` if it does and `false` if it doesn't.
  /// @protected
  @pragma('vm:prefer-inline')
  bool containsDependency<T extends Object>({
    required DIKey groupKey,
  }) {
    return getDependencyOrNull<T>(groupKey: groupKey) != null;
  }

  /// Checks if any dependency  of the exact [type] exists in the specified
  /// [groupKey]. Unlike [containsDependency], this will not include any
  /// subtype of [type].
  ///
  /// Returns `true` if it does and `false` if it doesn't.
  /// @protected
  @pragma('vm:prefer-inline')
  bool containsDependencyOfType({
    required DIKey type,
    required DIKey groupKey,
  }) {
    return getDependencyOfTypeOrNull(type: type, groupKey: groupKey) != null;
  }

  /// Gets any dependency of type [T] or subtype of [T] that is associated with
  /// the specified [groupKey] if it exists.
  ///
  /// Returns `null` if no matching dependency is found.
  /// @protected
  Dependency? getDependencyOrNull<T extends Object>({
    required DIKey groupKey,
  }) {
    final dependency = _state[groupKey]?.values.firstWhereOrNull((e) => e.value is T);
    final valid = dependency?.metadata.isValid?.call() == true;
    if (valid) {
      return dependency;
    } else {
      return null;
    }
  }

  /// Gets any dependency of the exact [type] that is associated with the
  /// specified [groupKey] if it exists. Unlike [getDependencyOrNull], this
  /// will not include any subtype of [type].
  ///
  /// Returns `null` if no matching dependency is found.
  /// @protected
  Dependency? getDependencyOfTypeOrNull({
    required DIKey type,
    required DIKey groupKey,
  }) {
    final dependency = _state[groupKey]?.values.firstWhereOrNull((e) => e.type == type);
    final valid = dependency?.metadata.isValid?.call() == true;
    if (valid) {
      return dependency;
    } else {
      return null;
    }
  }

  /// Gets all dependencies within [state] of the specified [type].
  /// @protected
  List<Dependency> getAllDependenciesOfType({
    required DIKey type,
  }) {
    return _state.entries.expand(
      (entry) {
        return entry.value.values.where((dependency) {
          return dependency.type == type;
        });
      },
    ).toList();
  }

  /// Removes any [Dependency] of [T] or subtype of [T] that is associated with
  /// the specified [groupKey].
  ///
  /// Returns the removed [Dependency] of [T], or `null` if it did not exist
  /// within [state].
  /// @protected
  Dependency<T>? removeDependency<T extends Object>({
    required DIKey groupKey,
  }) {
    final dependency = getDependencyOrNull<T>(groupKey: groupKey);
    if (dependency != null) {
      final removed = removeDependencyOfType(
        type: dependency.type,
        groupKey: groupKey,
      );
      return removed?.cast();
    }
    return null;
  }

  /// Removes any dependency of the exact [type] that is associated with the
  /// specified [groupKey]. Unlike [removeDependency], this will not include
  /// any subtype of [type].
  ///
  /// Returns the removed [Dependency] or `null` if it did not exist within
  /// [state].
  Dependency? removeDependencyOfType({
    required DIKey type,
    required DIKey groupKey,
  }) {
    final group = _state[groupKey];
    if (group != null) {
      final removed = group.remove(type);
      if (removed != null) {
        if (group.isEmpty) {
          removeGroup(
            groupKey: groupKey,
          );
        } else {
          setGroup(
            groupKey: groupKey,
            group: group,
          );
        }
        onChange?.call(state);
        return removed;
      }
    }
    return null;
  }

  /// Updates the [state] by setting or replacing the [group] associated with
  /// the specified [groupKey].
  void setGroup({
    required DIKey groupKey,
    required DependencyGroup<Object> group,
  }) {
    final prev = _state[groupKey];
    final equals = const MapEquality<DIKey, Dependency>().equals(prev, group);
    if (!equals) {
      _state[groupKey] = group;
      onChange?.call(state);
    }
  }

  /// Gets the [DependencyGroup] with the specified [groupKey] from the [state]
  /// as or `null` if none exist.
  /// @protected
  // DependencyGroup<Object>? getGroup({
  //   required DIKey groupKey,
  // }) {
  //   final temp = _state[groupKey];
  //   return temp != null ? DependencyGroup.unmodifiable(temp) : null;
  // }

  /// Removes the [DependencyGroup] with the specified [groupKey] from the
  /// [state].
  /// @protected
  @pragma('vm:prefer-inline')
  void removeGroup({
    required DIKey groupKey,
  }) {
    _state.remove(groupKey);
    onChange?.call(state);
  }

  /// Clears the [state], resetting the registry and effectively restoring it
  /// to the state of a newly created [Registry] instance.
  void clearRegistry() {
    _state.clear();
    onChange?.call(state);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A typedef for a Map representing the state of a [Registry].
typedef RegistryState = Map<DIKey, DependencyGroup<Object>>;

/// A typedef for a Map representing a group of dependencies organized by a
/// group key.
typedef DependencyGroup<T extends Object> = Map<DIKey, Dependency<T>>;

/// A typedef for a callback function to invoke when the [state] of a [Registry]
/// changes.
typedef _OnChangeRegistry = void Function(RegistryState state);
