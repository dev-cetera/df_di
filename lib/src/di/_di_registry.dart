//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
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

  /// Reverse index: `typeEntity → set of groupEntities` that contain a
  /// dependency keyed by that type. Maintained in tandem with [_state] so
  /// cross-group lookups by type are O(K) in the number of matching groups,
  /// not O(N) in the total number of dependencies.
  final Map<Entity, Set<Entity>> _typeIndex = {};

  /// A callback invoked whenever the [state] is updated.
  final Option<TOnChangeRegistry> onChange;

  /// A snapshot describing the current state of the dependencies.
  @pragma('vm:prefer-inline')
  TRegistryState get state => TRegistryState.unmodifiable(
        _state,
      ).map((k, v) => MapEntry(k, Map.unmodifiable(v)));

  /// Returns an iterable of all dependencies in the registry, unsorted.
  @pragma('vm:prefer-inline')
  Iterable<Dependency> get unsortedDependencies =>
      _state.entries.expand((e) => e.value.values);

  /// Returns a list of all dependencies, sorted in reverse order of registration (newest first).
  /// Dependencies without a registration index are placed at the end.
  List<Dependency> get reversedDependencies {
    final entries = _state.entries.expand((e) => e.value.values);
    final sortedEntries = entries.map((d) {
      final index = switch (d.metadata) {
        Some(value: DependencyMetadata(index: Some(value: final i))) => i,
        _ => -1,
      };
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

  /// Returns the group entities that contain a dependency keyed by
  /// [typeEntity]. Backed by the reverse type-index, so this is O(K) in the
  /// number of matching groups regardless of the total dependency count.
  ///
  /// The returned iterable is a live, unmodifiable view of the underlying
  /// set; callers that need a stable snapshot must copy it (e.g. `.toList()`).
  @pragma('vm:prefer-inline')
  Iterable<Entity> groupsWithTypeK(Entity typeEntity) {
    final groups = _typeIndex[typeEntity];
    if (groups == null) return const Iterable<Entity>.empty();
    return UnmodifiableSetView(groups);
  }

  /// Returns the group entities that contain a dependency keyed under the
  /// type-entity for [type]. See [groupsWithTypeK].
  @pragma('vm:prefer-inline')
  Iterable<Entity> groupsWithTypeT(Type type) =>
      groupsWithTypeK(TypeEntity(type));

  /// Updates the [state] by setting or updating [dependency].
  void setDependency(Dependency dependency) {
    final groupEntity = switch (dependency.metadata) {
      Some(value: final m) => m.groupEntity,
      None() => const DefaultEntity(),
    };
    final typeEntity = dependency.typeEntity;
    final currentDep = _state[groupEntity]?[typeEntity];
    if (currentDep != dependency) {
      (_state[groupEntity] ??= {})[typeEntity] = dependency;
      (_typeIndex[typeEntity] ??= <Entity>{}).add(groupEntity);
      _fireOnChange();
    }
  }

  /// Fires the `onChange` listener if one is registered. Extracted so the
  /// many call sites stay one-liners and the `Some(value: final cb) => cb()`
  /// shape isn't repeated.
  void _fireOnChange() {
    if (onChange case Some(value: final cb)) {
      cb();
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
    return Option.from(
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
  @pragma('vm:prefer-inline')
  Option<Dependency> getDependencyT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    return getDependencyK(TypeEntity(type), groupEntity: groupEntity);
  }

  /// Returns any dependency with the exact [typeEntity] under the specified
  /// [groupEntity]. Unlike [getDependency], this will not include subtypes.
  @pragma('vm:prefer-inline')
  Option<Dependency> getDependencyK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final a = TypeEntity(Sync, [typeEntity]);
    final b = TypeEntity(Async, [typeEntity]);
    return Option.from(
      _state[groupEntity]?.values.firstWhereOrNull(
            (e) => e.typeEntity == a || e.typeEntity == b,
          ),
    );
  }

  /// Removes the first dependency of type [T] (or its subtypes) found under the specified [groupEntity].
  /// If the group becomes empty after removal, the group itself is removed.
  @pragma('vm:prefer-inline')
  Option<Dependency> removeDependencyT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    return removeDependencyK(TypeEntity(type), groupEntity: groupEntity);
  }

  /// Removes the dependency keyed under exact type [T] in [groupEntity], using
  /// the same key construction as [setDependency] (`Sync<T>` / `Async<T>`).
  /// If the group becomes empty after removal, the group itself is removed.
  ///
  /// This is strict by design: a `Lazy<T>` registration is keyed under
  /// `Sync<Lazy<T>>` and is NOT matched here — callers wanting to remove a
  /// lazy must call `removeDependency<Lazy<T>>()` (or `unregisterLazy<T>()`
  /// at the [DIBase] layer). Keeping the key space identical on insert and
  /// remove avoids the silent "register-a-lazy-and-fail-to-find-it" trap.
  @pragma('vm:prefer-inline')
  Option<Dependency<T>> removeDependency<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
  }) {
    return removeDependencyK(
      TypeEntity(T),
      groupEntity: groupEntity,
    ).map((e) => e.transf<T>());
  }

  /// Removes the dependency stored under [exactTypeEntity] (the raw registry
  /// key — i.e. `dependency.typeEntity`, NOT the inner T).
  /// If the group becomes empty after removal, the group itself is removed.
  ///
  /// Use this when you already hold a `Dependency` and just need to evict its
  /// exact slot (e.g. [SupportsUnregisterAll]). For lookups keyed by an inner
  /// type entity (e.g. `Foo` rather than `Sync<Foo>`), use [removeDependencyK].
  Option<Dependency> removeDependencyExact(
    Entity exactTypeEntity, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final group = _state[groupEntity];
    if (group == null) {
      return const None();
    }
    final removed = Option.from(group.remove(exactTypeEntity));
    if (removed.isNone()) {
      return const None();
    }
    _detachFromTypeIndex(exactTypeEntity, groupEntity);
    if (group.isEmpty) {
      _state.remove(groupEntity);
    }
    _fireOnChange();
    return removed;
  }

  /// Removes the dependency with the exact [typeEntity] under the specified [groupEntity].
  /// If the group becomes empty after removal, the group itself is removed.
  Option<Dependency> removeDependencyK(
    Entity typeEntity, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final group = _state[groupEntity];
    if (group == null) {
      return const None();
    }
    final syncKey = TypeEntity(Sync, [typeEntity]);
    final asyncKey = TypeEntity(Async, [typeEntity]);
    final (Option<Dependency> removed, Entity? removedKey) =
        switch (Option<Dependency>.from(group.remove(syncKey))) {
      final Some<Dependency> s => (s, syncKey),
      None() => switch (Option<Dependency>.from(group.remove(asyncKey))) {
          final Some<Dependency> s => (s, asyncKey),
          None() => (const None(), null),
        },
    };
    if (removedKey == null) return const None();
    _detachFromTypeIndex(removedKey, groupEntity);
    if (group.isEmpty) {
      _state.remove(groupEntity);
    }
    _fireOnChange();
    return removed.map((e) => e.transf());
  }

  /// Updates the [state] by setting or replacing the [group] under the
  /// specified [groupEntity].
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
      if (currentGroup != null) {
        for (final typeEntity in currentGroup.keys) {
          _detachFromTypeIndex(typeEntity, groupEntity);
        }
      }
      _state[groupEntity] = group;
      for (final typeEntity in group.keys) {
        (_typeIndex[typeEntity] ??= <Entity>{}).add(groupEntity);
      }
      _fireOnChange();
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
  void removeDependencyWhere(
    bool Function(Entity entity, Dependency dependency) test, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final group = _state[groupEntity];
    if (group == null) return;
    final initialSize = group.length;
    group.removeWhere((typeEntity, dependency) {
      final drop = test(typeEntity, dependency);
      if (drop) _detachFromTypeIndex(typeEntity, groupEntity);
      return drop;
    });
    if (group.length == initialSize) return; // Nothing removed.
    // Match the invariant established by removeDependencyExact /
    // removeDependencyK: prune the group when it empties so `groupEntities`
    // doesn't expose ghost keys, and notify listeners.
    if (group.isEmpty) {
      _state.remove(groupEntity);
    }
    _fireOnChange();
  }

  /// Removes the [TDependencyGroup] with the specified [groupEntity] from the
  /// [state].
  void removeGroup({Entity groupEntity = const DefaultEntity()}) {
    final group = _state.remove(groupEntity);
    if (group != null) {
      for (final typeEntity in group.keys) {
        _detachFromTypeIndex(typeEntity, groupEntity);
      }
    }
    _fireOnChange();
  }

  /// Clears the [state], resetting the registry and effectively restoring it
  /// to the state of a newly created [DIRegistry] instance.
  @pragma('vm:prefer-inline')
  void clear() {
    _state.clear();
    _typeIndex.clear();
    _fireOnChange();
  }

  /// Drops [groupEntity] from the bucket for [typeEntity] in [_typeIndex],
  /// pruning the empty bucket. Must be called whenever a dependency leaves
  /// the registry so the reverse index never goes stale.
  @pragma('vm:prefer-inline')
  void _detachFromTypeIndex(Entity typeEntity, Entity groupEntity) {
    final bucket = _typeIndex[typeEntity];
    if (bucket == null) return;
    bucket.remove(groupEntity);
    if (bucket.isEmpty) _typeIndex.remove(typeEntity);
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
