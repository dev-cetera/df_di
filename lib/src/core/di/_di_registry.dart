//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Registry for storing and managing dependencies by runtime type and a group
/// entity.
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
  List<Dependency> get dependencies => List.unmodifiable(
        _state.entries.expand((e) => e.value.values).toList()
          // Sort by descending indexes, i.e. largest index is first element.
          ..sort((d1, d2) {
            final index1 = d1.metadata?.index ?? -1;
            final index2 = d2.metadata?.index ?? -1;
            return index2.compareTo(index1);
          }),
      );

  /// Returns all dependencies witin this [DIRegistry] instance of type
  /// [T].
  Iterable<Dependency> dependenciesWhereType<T>() {
    return dependencies.map((e) => e.value is T ? e : null).nonNulls;
  }

  /// Returns all dependencies witin this [DIRegistry] instance of type [type].
  /// Unlike [dependenciesWhereType], this will not include subtypes of [type].
  @pragma('vm:prefer-inline')
  Iterable<Dependency> dependenciesWhereTypeT(
    Type type,
  ) {
    return dependenciesWhereTypeK(Entity.obj(type));
  }

  /// Returns all dependencies witin this [DIRegistry] instance of type
  /// [typeEntity]. Unlike [dependenciesWhereType], this will not include
  /// subtypes.
  @pragma('vm:prefer-inline')
  Iterable<Dependency> dependenciesWhereTypeK(
    Entity typeEntity,
  ) {
    return dependencies.map((e) => e.typeEntity == typeEntity ? e : null).nonNulls;
  }

  /// A snapshot of the current group entities within [state].
  List<Entity?> get groupEntities => List.unmodifiable(_state.keys);

  /// Updates the [state] by setting or updating [dependency].
  @protected
  void setDependency(Dependency dependency) {
    final groupEntity = dependency.metadata?.groupEntity;
    final typeEntity = dependency.typeEntity;
    final currentDep = _state[groupEntity]?[typeEntity];
    if (currentDep != dependency) {
      (_state[groupEntity] ??= {})[typeEntity] = dependency;
      onChange?.call();
    }
  }

  /// Checks if any dependency of type [T] or subtype of [T] exists that is
  /// associated with the specified [groupEntity]
  ///
  /// Returns `true` if it does and `false` if it doesn't.
  @pragma('vm:prefer-inline')
  bool containsDependency<T extends Object>({
    Entity? groupEntity,
  }) {
    return getDependencyOrNull<T>(groupEntity: groupEntity) != null;
  }

  /// Checks if any dependency with the exact [type] exists that is
  /// associated with the specified [groupEntity]. Unlike [containsDependency],
  /// this will not include subtypes of [type].
  ///
  /// Returns `true` if it does and `false` if it doesn't.
  @pragma('vm:prefer-inline')
  bool containsDependencyT(
    Type type, {
    Entity? groupEntity,
  }) {
    return containsDependencyK(
      Entity.obj(type),
      groupEntity: groupEntity,
    );
  }

  /// Checks if any dependency registered under the exact [typeEntity] exists that
  /// is associated with the specified [groupEntity]. Unlike [containsDependency],
  /// this will not include subtypes.
  ///
  /// Returns `true` if it does and `false` if it doesn't.
  @pragma('vm:prefer-inline')
  bool containsDependencyK(
    Entity typeEntity, {
    Entity? groupEntity,
  }) {
    return getDependencyOrNullK(typeEntity, groupEntity: groupEntity) != null;
  }

  /// Returns any dependency of type [T] or subtype of [T] that is associated
  /// with the specified [groupEntity] if it exists, or `null`.
  @protected
  @pragma('vm:prefer-inline')
  Dependency<T>? getDependencyOrNull<T extends Object>({
    Entity? groupEntity,
  }) {
    return _state[groupEntity]?.values.firstWhereOrNull((e) => e.value is T)?.cast<T>();
  }

  /// Returns any dependency with the exact [type] that is associated
  /// with the specified [groupEntity] if it exists, or `null`. Unlike
  /// [getDependencyOrNull], this will not include subtypes.
  @protected
  @pragma('vm:prefer-inline')
  Dependency? getDependencyOrNullT(
    Type type, {
    Entity? groupEntity,
  }) {
    return getDependencyOrNullK(
      Entity.obj(type),
      groupEntity: groupEntity,
    );
  }

  /// Returns any dependency with the exact [typeEntity] that is associated with
  /// the specified [groupEntity] if it exists, or `null`. Unlike
  /// [getDependencyOrNull], this will not include subtypes.
  @protected
  @pragma('vm:prefer-inline')
  Dependency? getDependencyOrNullK(
    Entity typeEntity, {
    Entity? groupEntity,
  }) {
    return _state[groupEntity]?.values.firstWhereOrNull((e) => e.typeEntity == typeEntity);
  }

  /// Removes any [Dependency] of [T] or subtype of [T] that is associated with
  /// the specified [groupEntity].
  ///
  /// Returns the removed [Dependency] of [T], or `null` if it did not exist
  /// within [state].
  @protected
  Dependency<T>? removeDependency<T extends Object>({
    Entity? groupEntity,
  }) {
    final dependency = getDependencyOrNull<T>(groupEntity: groupEntity);
    if (dependency != null) {
      final removed = removeDependencyK(
        dependency.typeEntity,
        groupEntity: groupEntity,
      );
      return removed?.cast();
    }
    return null;
  }

  /// Removes any dependency with the exact [type] that is associated
  /// with the specified [groupEntity]. Unlike [removeDependency], this will not
  /// include any subtypes.
  ///
  /// Returns the removed [Dependency] or `null` if it did not exist within
  /// [state].
  @protected
  @pragma('vm:prefer-inline')
  Dependency? removeDependencyT(
    Type type, {
    Entity? groupEntity,
  }) {
    return removeDependencyK(
      Entity.obj(type),
      groupEntity: groupEntity,
    );
  }

  /// Removes any dependency with the exact [typeEntity] that is associated with
  /// the specified [groupEntity]. Unlike [removeDependency], this will not
  /// include any subtypes.
  ///
  /// Returns the removed [Dependency] or `null` if it did not exist within
  /// [state].
  @protected
  Dependency? removeDependencyK(
    Entity typeEntity, {
    Entity? groupEntity,
  }) {
    final group = _state[groupEntity];
    if (group != null) {
      final removed = group.remove(typeEntity);
      if (removed != null) {
        if (group.isEmpty) {
          removeGroup(
            groupEntity: groupEntity,
          );
        } else {
          setGroup(
            group,
            groupEntity: groupEntity,
          );
        }
        onChange?.call();
        return removed;
      }
    }
    return null;
  }

  /// Updates the [state] by setting or replacing the [group] associated with
  /// the specified [groupEntity].
  @protected
  void setGroup(
    DependencyGroup<Object> group, {
    Entity? groupEntity,
  }) {
    final currentGroup = _state[groupEntity];
    final equals = const MapEquality<Entity, Dependency>().equals(currentGroup, group);
    if (!equals) {
      _state[groupEntity] = group;
      onChange?.call();
    }
  }

  /// Gets the [DependencyGroup] with the specified [groupEntity] from the [state]
  /// or `null` if none exist.
  @pragma('vm:prefer-inline')
  DependencyGroup<Object> getGroup({
    Entity? groupEntity,
  }) {
    return DependencyGroup.unmodifiable(_state[groupEntity] ?? {});
  }

  /// Removes the [DependencyGroup] with the specified [groupEntity] from the
  /// [state].
  @protected
  @pragma('vm:prefer-inline')
  void removeGroup({
    Entity? groupEntity,
  }) {
    _state.remove(groupEntity);
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
typedef RegistryState = Map<Entity?, DependencyGroup<Object>>;

/// A typedef for a Map representing a group of dependencies organized by a
/// group entity.
typedef DependencyGroup<T extends Object> = Map<Entity, Dependency<T>>;

/// A typedef for a callback function to invoke when the [state] of a [DIRegistry]
/// changes.
typedef _OnChangeRegistry = void Function();
