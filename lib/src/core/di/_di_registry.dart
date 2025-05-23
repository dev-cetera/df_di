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

  DIRegistry({this.onChange = const None()});

  /// Represents the internal state of this [DIRegistry] instance, stored as a
  /// map.
  final RegistryState _state = {};

  /// A callback invoked whenever the [state] is updated.
  final Option<_OnChangeRegistry> onChange;

  /// A snapshot describing the current state of the dependencies.
  RegistryState get state => RegistryState.unmodifiable(
    _state,
  ).map((k, v) => MapEntry(k, Map.unmodifiable(v)));

  @protected
  @pragma('vm:prefer-inline')
  Iterable<Dependency> get unsortedDependencies =>
      _state.entries.expand((e) => e.value.values);

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
  Option<Dependency<T>> getDependency<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    return Option.fromNullable(
      _state[groupEntity]?.values.whereType<Dependency<T>>().firstOrNull,
      //_state[groupEntity]?.values.firstWhereOrNull((e) => e.value is Resolvable<T>)?.trans<T>(),
    );
  }

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

  @protected
  @pragma('vm:prefer-inline')
  Option<Dependency<T>> removeDependencyT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    return removeDependencyK<T>(TypeEntity(type), groupEntity: groupEntity);
  }

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
    return Some(dependency.transf());
  }

  Option<Dependency<T>> removeDependencyK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final test = _removeDependencyK<T>(
      TypeEntity(Sync, [typeEntity]),
      groupEntity: groupEntity,
    );
    if (test.isNone()) {
      return const None();
    }
    return _removeDependencyK<T>(
      TypeEntity(Async, [typeEntity]),
      groupEntity: groupEntity,
    );
  }

  @protected
  Option<Dependency<T>> _removeDependencyK<T extends Object>(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final group = _state[groupEntity];
    if (group == null) {
      return const None();
    }

    final removed = Option.fromNullable(group.remove(typeEntity));
    if (removed.isNone()) {
      return const None();
    }
    if (group.isEmpty) {
      removeGroup(groupEntity: groupEntity);
    } else {
      setGroup(group, groupEntity: groupEntity);
    }
    onChange.ifSome((e) => e.unwrap()());
    return removed.map((e) => e.transf());
  }

  /// Updates the [state] by setting or replacing the [group] under the
  /// specified [groupEntity].
  @protected
  void setGroup(
    DependencyGroup<Object> group, {
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

  /// Gets the [DependencyGroup] with the specified [groupEntity] from the [state]
  /// or `null` if none exist.
  @pragma('vm:prefer-inline')
  DependencyGroup<Object> getGroup({
    Entity groupEntity = const DefaultEntity(),
  }) {
    return DependencyGroup.unmodifiable(_state[groupEntity] ?? {});
  }

  @pragma('vm:prefer-inline')
  void removDependencyWhere(
    bool Function(Entity entity, Dependency dependency) test, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    _state[groupEntity]?.removeWhere(test);
  }

  /// Removes the [DependencyGroup] with the specified [groupEntity] from the
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
typedef RegistryState = Map<Entity, DependencyGroup<Object>>;

/// A typedef for a Map representing a group of dependencies organized by a
/// group entity.
typedef DependencyGroup<T extends Object> = Map<Entity, Dependency<T>>;

/// A typedef for a callback function to invoke when the [state] of a [DIRegistry]
/// changes.
typedef _OnChangeRegistry = void Function();
