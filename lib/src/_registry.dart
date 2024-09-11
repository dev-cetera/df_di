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

const _protected = protected;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Registry for storing and managing dependencies by runtime type and a group
/// key.
final class DIRegistry {
  //
  //
  //

  DIRegistry({this.onChange});

  /// Represents the internal state of this [DIRegistry] instance, stored as a
  /// map.
  final RegistryState _state = {};

  /// A callback invoked whenever the [state] is updated.
  final _OnChangeRegistry? onChange;

  /// A snapshot describing the current state of the dependencies.
  RegistryState get state =>
      RegistryState.unmodifiable(_state).map((k, v) => MapEntry(k, Map.unmodifiable(v)));

  /// A snapshot of the current dependencies within [state].
  List<Dependency> get dependencies =>
      List.unmodifiable(_state.entries.expand((e) => e.value.values));

  /// A snapshot of the current group keys within [state].
  List<DIKey?> get groupKeys => List.unmodifiable(_state.keys);

  /// Updates the [state] by setting or updating [dependency].
  @_protected
  void setDependency<T extends Object>(Dependency<T> dependency) {
    final groupKey = dependency.metadata?.groupKey;
    final typeKey = dependency.typeKey;
    final currentDep = _state[groupKey]?[typeKey];
    if (currentDep != dependency) {
      (_state[groupKey] ??= {})[typeKey] = dependency;
      onChange?.call();
    }
  }

  /// Checks if any dependency of type [T] or subtype of [T] exists that is
  /// associated with the specified [groupKey]
  ///
  /// Returns `true` if it does and `false` if it doesn't.
  @pragma('vm:prefer-inline')
  bool containsDependency<T extends Object>({
    DIKey? groupKey,
  }) {
    return getDependencyOrNull<T>(groupKey: groupKey) != null;
  }

  /// Checks if any dependency with the exact [runtimeType] exists that is
  /// associated with the specified [groupKey]. Unlike [containsDependency],
  /// this will not include subtypes of [runtimeType].
  ///
  /// Returns `true` if it does and `false` if it doesn't.
  @pragma('vm:prefer-inline')
  bool containsDependencyOfRuntimeType(
    Type runtimeType, {
    DIKey? groupKey,
  }) {
    return containsDependencyWithKey(
      DIKey(runtimeType),
      groupKey: groupKey,
    );
  }

  /// Checks if any dependency registered under the exact [typeKey] exists that
  /// is associated with the specified [groupKey]. Unlike [containsDependency],
  /// this will not include subtypes.
  ///
  /// Returns `true` if it does and `false` if it doesn't.
  @pragma('vm:prefer-inline')
  bool containsDependencyWithKey(
    DIKey typeKey, {
    DIKey? groupKey,
  }) {
    return getDependencyWithKeyOrNull(typeKey, groupKey: groupKey) != null;
  }

  /// Returns any dependency of type [T] or subtype of [T] that is associated
  /// with the specified [groupKey] if it exists, or `null`.
  @_protected
  @pragma('vm:prefer-inline')
  Dependency<T>? getDependencyOrNull<T extends Object>({
    DIKey? groupKey,
  }) {
    return _state[groupKey]?.values.firstWhereOrNull((e) => e.value is T)?.cast<T>();
  }

  /// Returns any dependency with the exact [runtimeType] that is associated
  /// with the specified [groupKey] if it exists, or `null`. Unlike
  /// [getDependencyOrNull], this will not include subtypes.
  @_protected
  @pragma('vm:prefer-inline')
  Dependency? getDependencyOfRuntimeTypeOrNull(
    Type runtimeType, {
    DIKey? groupKey,
  }) {
    return getDependencyWithKeyOrNull(
      DIKey(runtimeType),
      groupKey: groupKey,
    );
  }

  /// Returns any dependency with the exact [typeKey] that is associated with
  /// the specified [groupKey] if it exists, or `null`. Unlike
  /// [getDependencyOrNull], this will not include subtypes.
  @_protected
  @pragma('vm:prefer-inline')
  Dependency? getDependencyWithKeyOrNull(
    DIKey typeKey, {
    DIKey? groupKey,
  }) {
    return _state[groupKey]?.values.firstWhereOrNull((e) => e.typeKey == typeKey);
  }

  /// Removes any [Dependency] of [T] or subtype of [T] that is associated with
  /// the specified [groupKey].
  ///
  /// Returns the removed [Dependency] of [T], or `null` if it did not exist
  /// within [state].
  @_protected
  Dependency<T>? removeDependency<T extends Object>({
    DIKey? groupKey,
  }) {
    final dependency = getDependencyOrNull<T>(groupKey: groupKey);
    if (dependency != null) {
      final removed = removeDependencyWithKey(
        dependency.typeKey,
        groupKey: groupKey,
      );
      return removed?.cast();
    }
    return null;
  }

  /// Removes any dependency with the exact [runtimeType] that is associated
  /// with the specified [groupKey]. Unlike [removeDependency], this will not
  /// include any subtypes.
  ///
  /// Returns the removed [Dependency] or `null` if it did not exist within
  /// [state].
  @_protected
  @pragma('vm:prefer-inline')
  Dependency? removeDependencyOfRuntimeType(
    Type runtimeType, {
    DIKey? groupKey,
  }) {
    return removeDependencyWithKey(
      DIKey(runtimeType),
      groupKey: groupKey,
    );
  }

  /// Removes any dependency with the exact [typeKey] that is associated with
  /// the specified [groupKey]. Unlike [removeDependency], this will not
  /// include any subtypes.
  ///
  /// Returns the removed [Dependency] or `null` if it did not exist within
  /// [state].
  @_protected
  Dependency? removeDependencyWithKey(
    DIKey typeKey, {
    DIKey? groupKey,
  }) {
    final group = _state[groupKey];
    if (group != null) {
      final removed = group.remove(typeKey);
      if (removed != null) {
        if (group.isEmpty) {
          removeGroup(
            groupKey: groupKey,
          );
        } else {
          setGroup(
            group,
            groupKey: groupKey,
          );
        }
        onChange?.call();
        return removed;
      }
    }
    return null;
  }

  /// Updates the [state] by setting or replacing the [group] associated with
  /// the specified [groupKey].
  @_protected
  void setGroup(
    DependencyGroup<Object> group, {
    DIKey? groupKey,
  }) {
    final currentGroup = _state[groupKey];
    final equals = const MapEquality<DIKey, Dependency>().equals(currentGroup, group);
    if (!equals) {
      _state[groupKey] = group;
      onChange?.call();
    }
  }

  /// Gets the [DependencyGroup] with the specified [groupKey] from the [state]
  /// or `null` if none exist.
  @pragma('vm:prefer-inline')
  DependencyGroup<Object> getGroup({
    DIKey? groupKey,
  }) {
    return DependencyGroup.unmodifiable(_state[groupKey] ?? {});
  }

  /// Removes the [DependencyGroup] with the specified [groupKey] from the
  /// [state].
  @_protected
  @pragma('vm:prefer-inline')
  void removeGroup({
    DIKey? groupKey,
  }) {
    _state.remove(groupKey);
    onChange?.call();
  }

  /// Clears the [state], resetting the registry and effectively restoring it
  /// to the state of a newly created [DIRegistry] instance.
  @pragma('vm:prefer-inline')
  void clear() {
    _state.clear();
    onChange?.call();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A typedef for a Map representing the state of a [DIRegistry].
typedef RegistryState = Map<DIKey?, DependencyGroup<Object>>;

/// A typedef for a Map representing a group of dependencies organized by a
/// group key.
typedef DependencyGroup<T extends Object> = Map<DIKey, Dependency<T>>;

/// A typedef for a callback function to invoke when the [state] of a [DIRegistry]
/// changes.
typedef _OnChangeRegistry = void Function();
