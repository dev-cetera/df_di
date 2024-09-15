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
  RegistryState get state => RegistryState.unmodifiable(_state)
      .map((k, v) => MapEntry(k, Map.unmodifiable(v)));

  /// A snapshot of the current dependencies within [state].
  List<Dependency> get dependencies => List.unmodifiable(
        _state.entries.expand((e) => e.value.values).toList()
          // Sort by descending indexes, i.e. largest index is first element.
          ..sort((d1, d2) {
            final index1 = d1.metadata?.index ?? -1;
            final index2 = d2.metadata?.index ?? -1;
            return index2.compareTo(index1);
          }),
      );

  /// A snapshot of the current group keys within [state].
  List<DIKey?> get groupKeys => List.unmodifiable(_state.keys);

  /// Updates the [state] by setting or updating [dependency].
  @protected
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

  /// Checks if any dependency with the exact [type] exists that is
  /// associated with the specified [groupKey]. Unlike [containsDependency],
  /// this will not include subtypes of [type].
  ///
  /// Returns `true` if it does and `false` if it doesn't.
  @pragma('vm:prefer-inline')
  bool containsDependencyT(
    Type type, {
    DIKey? groupKey,
  }) {
    return containsDependencyK(
      DIKey(type),
      groupKey: groupKey,
    );
  }

  /// Checks if any dependency registered under the exact [typeKey] exists that
  /// is associated with the specified [groupKey]. Unlike [containsDependency],
  /// this will not include subtypes.
  ///
  /// Returns `true` if it does and `false` if it doesn't.
  @pragma('vm:prefer-inline')
  bool containsDependencyK(
    DIKey typeKey, {
    DIKey? groupKey,
  }) {
    return getDependencyOrNullK(typeKey, groupKey: groupKey) != null;
  }

  /// Returns any dependency of type [T] or subtype of [T] that is associated
  /// with the specified [groupKey] if it exists, or `null`.
  @protected
  @pragma('vm:prefer-inline')
  Dependency<T>? getDependencyOrNull<T extends Object>({
    DIKey? groupKey,
  }) {
    return _state[groupKey]
        ?.values
        .firstWhereOrNull((e) => e.value is T)
        ?.cast<T>();
  }

  /// Returns any dependency with the exact [type] that is associated
  /// with the specified [groupKey] if it exists, or `null`. Unlike
  /// [getDependencyOrNull], this will not include subtypes.
  @protected
  @pragma('vm:prefer-inline')
  Dependency? getDependencyOrNullT(
    Type type, {
    DIKey? groupKey,
  }) {
    return getDependencyOrNullK(
      DIKey(type),
      groupKey: groupKey,
    );
  }

  /// Returns any dependency with the exact [typeKey] that is associated with
  /// the specified [groupKey] if it exists, or `null`. Unlike
  /// [getDependencyOrNull], this will not include subtypes.
  @protected
  @pragma('vm:prefer-inline')
  Dependency? getDependencyOrNullK(
    DIKey typeKey, {
    DIKey? groupKey,
  }) {
    return _state[groupKey]
        ?.values
        .firstWhereOrNull((e) => e.typeKey == typeKey);
  }

  /// Removes any [Dependency] of [T] or subtype of [T] that is associated with
  /// the specified [groupKey].
  ///
  /// Returns the removed [Dependency] of [T], or `null` if it did not exist
  /// within [state].
  @protected
  Dependency<T>? removeDependency<T extends Object>({
    DIKey? groupKey,
  }) {
    final dependency = getDependencyOrNull<T>(groupKey: groupKey);
    if (dependency != null) {
      final removed = removeDependencyK(
        dependency.typeKey,
        groupKey: groupKey,
      );
      return removed?.cast();
    }
    return null;
  }

  /// Removes any dependency with the exact [type] that is associated
  /// with the specified [groupKey]. Unlike [removeDependency], this will not
  /// include any subtypes.
  ///
  /// Returns the removed [Dependency] or `null` if it did not exist within
  /// [state].
  @protected
  @pragma('vm:prefer-inline')
  Dependency? removeDependencyT(
    Type type, {
    DIKey? groupKey,
  }) {
    return removeDependencyK(
      DIKey(type),
      groupKey: groupKey,
    );
  }

  /// Removes any dependency with the exact [typeKey] that is associated with
  /// the specified [groupKey]. Unlike [removeDependency], this will not
  /// include any subtypes.
  ///
  /// Returns the removed [Dependency] or `null` if it did not exist within
  /// [state].
  @protected
  Dependency? removeDependencyK(
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
  @protected
  void setGroup(
    DependencyGroup<Object> group, {
    DIKey? groupKey,
  }) {
    final currentGroup = _state[groupKey];
    final equals =
        const MapEquality<DIKey, Dependency>().equals(currentGroup, group);
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
  @protected
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
