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

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Registry for storing and managing dependencies by runtime type and a group
/// entity.
final class DIRegistry {
  //
  //
  //

  DIRegistry({this.onChange = const None()});

  /// Represents the internal state of this [DIRegistry] instance, stored as a
  /// map.
  final TRegistryState _state = {};

  /// A callback invoked whenever the [state] is updated.
  final Option<TOnChangeRegistry> onChange;

  /// A snapshot describing the current state of the dependencies.
  @pragma('vm:prefer-inline')
  TRegistryState get state => TRegistryState.unmodifiable(
        _state,
      ).map((k, v) => MapEntry(k, Map.unmodifiable(v)));

  /// Returns an iterable of all dependencies in the registry, unsorted.
  @protected
  @pragma('vm:prefer-inline')
  Iterable<Dependency> get unsortedDependencies =>
      _state.entries.expand((e) => e.value.values);

  /// Returns a list of all dependencies, sorted in reverse order of registration (newest first).
  /// Dependencies without a registration index are placed at the end.
  List<Dependency> get reversedDependencies {
    final entries = _state.entries.expand((e) => e.value.values);
    final sortedEntries = entries.map((d) {
      final metadata = d.metadata;
      final index = metadata.isSome() && metadata.unwrap().index.isSome()
          ? metadata.unwrap().index.unwrap()
          : -1;
      return (index, d);
    }).toList();
    sortedEntries.sort((a, b) => b.$1.compareTo(a.$1));
    return List.unmodifiable(sortedEntries.map((e) => e.$2));
  }

  /// Returns all dependencies witin this [DIRegistry] instance of type
  /// [T].
  @pragma('vm:prefer-inline')
  Iterable<Dependency> dependenciesWhereType<T extends Object>() {
    return reversedDependencies.map((e) => e.value is T ? e : null).nonNulls;
  }

  /// Returns all dependencies witin this [DIRegistry] instance of type [type].
  /// Unlike [dependenciesWhereType], this will not include subtypes of [type].
  @pragma('vm:prefer-inline')
  Iterable<Dependency> dependenciesWhereTypeT(Type type) {
    return dependenciesWhereTypeK(TypeEntity(type));
  }

  /// Returns all dependencies witin this [DIRegistry] instance of type
  /// [typeEntity]. Unlike [dependenciesWhereType], this will not include
  /// subtypes.
  @pragma('vm:prefer-inline')
  Iterable<Dependency> dependenciesWhereTypeK(Entity typeEntity) {
    return reversedDependencies
        .map((e) => e.typeEntity == typeEntity ? e : null)
        .nonNulls;
  }

  /// A snapshot of the current group entities within [state].
  @pragma('vm:prefer-inline')
  List<Entity> get groupEntities => List.unmodifiable(_state.keys);

  /// Updates the [state] by setting or updating [dependency].
  @protected
  void setDependency(Dependency dependency) {
    final groupEntity = dependency.metadata.isSome()
        ? dependency.metadata.unwrap().groupEntity
        : const DefaultEntity();
    final typeEntity = dependency.typeEntity;
    final currentDep = Option.fromNullable(_state[groupEntity]?[typeEntity]);

    if (currentDep.isNone() || currentDep.unwrap() != dependency) {
      (_state[groupEntity] ??= {})[typeEntity] = dependency;
      onChange.ifSome((e) => e.unwrap()());
    }
  }

  /// Checks if any dependency of type [T] or subtypes exists under the
  /// specified [groupEntity]
  ///
  /// Returns `true` if it does and `false` if it doesn't.
  @pragma('vm:prefer-inline')
  bool containsDependency<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    return _state[groupEntity]?.values.any((e) => e.value is Resolvable<T>) ==
        true;
  }

  /// Checks if any dependency with the exact [type] exists under the specified
  /// [groupEntity]. Unlike [containsDependency], this will not include subtypes
  /// of [type].
  ///
  /// Returns `true` if it does and `false` if it doesn't.
  @pragma('vm:prefer-inline')
  bool containsDependencyT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final a = TypeEntity(Sync, [type]);
    final b = TypeEntity(Async, [type]);
    return _state[groupEntity]?.values.any(
              (e) => e.typeEntity == a || e.typeEntity == b,
            ) ==
        true;
  }

  /// Checks if any dependency registered under the exact [typeEntity] exists
  /// under the specified [groupEntity]. Unlike [containsDependency], this will
  /// not include subtypes.
  ///
  /// Returns `true` if it does and `false` if it doesn't.
  @pragma('vm:prefer-inline')
  bool containsDependencyK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final a = TypeEntity(Sync, [typeEntity]);
    final b = TypeEntity(Async, [typeEntity]);
    return _state[groupEntity]?.values.any(
              (e) => e.typeEntity == a || e.typeEntity == b,
            ) ==
        true;
  }

  /// Returns any dependency of type [T] or subtypes under the specified
  /// [groupEntity].
  @pragma('vm:prefer-inline')
  Option<Dependency<T>> getDependency<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    return Option.fromNullable(
      _state[groupEntity]
          ?.values
          .firstWhereOrNull((e) => e.value is Resolvable<T>)
          ?.transf<T>(),
    );
  }

  /// Returns an iterable of all dependencies of type [T] within the specified [groupEntity].
  /// This method considers exact type matches, not subtypes.
  @pragma('vm:prefer-inline')
  Iterable<Dependency<T>> getDependencies<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    return _state[groupEntity]?.values.whereType<Dependency<T>>() ?? [];
  }

  /// Returns any dependency with the exact [type] under the specified
  /// [groupEntity]. Unlike [getDependency], this will not include subtypes.
  @protected
  @pragma('vm:prefer-inline')
  Option<Dependency> getDependencyT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    return getDependencyK(TypeEntity(type), groupEntity: groupEntity);
  }

  /// Returns any dependency with the exact [typeEntity] under the specified
  /// [groupEntity]. Unlike [getDependency], this will not include subtypes.
  @protected
  @pragma('vm:prefer-inline')
  Option<Dependency> getDependencyK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final a = TypeEntity(Sync, [typeEntity]);
    final b = TypeEntity(Async, [typeEntity]);
    return Option.fromNullable(
      _state[groupEntity]?.values.firstWhereOrNull(
            (e) => e.typeEntity == a || e.typeEntity == b,
          ),
    );
  }

  /// Removes the first dependency of type [T] (or its subtypes) found under the specified [groupEntity].
  /// If the group becomes empty after removal, the group itself is removed.
  @protected
  @pragma('vm:prefer-inline')
  Option<Dependency> removeDependencyT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    return removeDependencyK(TypeEntity(type), groupEntity: groupEntity);
  }

  /// Removes the first dependency of type [T] (or its subtypes) found under the specified [groupEntity].
  /// If the group becomes empty after removal, the group itself is removed.
  Option<Dependency<T>> removeDependency<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final group = _state[groupEntity];
    if (group == null) {
      return const None();
    }
    final key = group.entries
        .firstWhereOrNull((e) => e.value.value is Resolvable<T>)
        ?.key;
    if (key == null) {
      return const None();
    }
    final dependency = group.remove(key);
    if (dependency == null) {
      return const None();
    }
    if (group.isEmpty) {
      removeGroup(groupEntity: groupEntity);
    }
    onChange.ifSome((e) => e.unwrap()());
    return Some(dependency.transf());
  }

  /// Removes the dependency with the exact [typeEntity] under the specified [groupEntity].
  /// If the group becomes empty after removal, the group itself is removed.
  @protected
  Option<Dependency> removeDependencyK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final group = _state[groupEntity];
    if (group == null) {
      return const None();
    }
    Option<Dependency<Object>> removed;
    removed = Option.fromNullable(group.remove(TypeEntity(Sync, [typeEntity])));
    if (removed.isNone()) {
      removed = Option.fromNullable(
        group.remove(TypeEntity(Async, [typeEntity])),
      );
    }
    if (removed.isNone()) {
      return const None();
    }
    if (group.isEmpty) {
      removeGroup(groupEntity: groupEntity);
    }
    onChange.ifSome((e) => e.unwrap()());
    return removed.map((e) => e.transf());
  }

  /// Updates the [state] by setting or replacing the [group] under the
  /// specified [groupEntity].
  @protected
  void setGroup(
    TDependencyGroup<Object> group, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final currentGroup = _state[groupEntity];
    final equals = const MapEquality<Entity, Dependency>().equals(
      currentGroup,
      group,
    );
    if (!equals) {
      _state[groupEntity] = group;
      onChange.ifSome((e) => e.unwrap()());
    }
  }

  /// Gets the [TDependencyGroup] with the specified [groupEntity] from the [state]
  /// or `null` if none exist.
  @pragma('vm:prefer-inline')
  TDependencyGroup<Object> getGroup({
    Entity groupEntity = const DefaultEntity(),
  }) {
    return TDependencyGroup.unmodifiable(_state[groupEntity] ?? {});
  }

  @pragma('vm:prefer-inline')
  void removDependencyWhere(
    bool Function(Entity entity, Dependency dependency) test, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    _state[groupEntity]?.removeWhere(test);
  }

  /// Removes the [TDependencyGroup] with the specified [groupEntity] from the
  /// [state].
  @protected
  @pragma('vm:prefer-inline')
  void removeGroup({Entity groupEntity = const DefaultEntity()}) {
    _state.remove(groupEntity);
    onChange.ifSome((e) => e.unwrap()());
  }

  /// Clears the [state], resetting the registry and effectively restoring it
  /// to the state of a newly created [DIRegistry] instance.
  @pragma('vm:prefer-inline')
  void clear() {
    _state.clear();
    onChange.ifSome((e) => e.unwrap()());
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A typedef for a Map representing the state of a [DIRegistry].
typedef TRegistryState = Map<Entity, TDependencyGroup<Object>>;

/// A typedef for a Map representing a group of dependencies organized by a
/// group entity.
typedef TDependencyGroup<T extends Object> = Map<Entity, Dependency<T>>;

/// A typedef for a callback function to invoke when the `state` of a [DIRegistry]
/// changes.
typedef TOnChangeRegistry = void Function();
