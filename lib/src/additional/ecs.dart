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

// ignore_for_file: invalid_use_of_protected_member

import 'package:equatable/equatable.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Manages entities and their associated components,  facilitating the
/// creation, addition, querying, updating, and removal of components within an
/// Entity-Component-System (ECS) framework.
class World {
  /// Internal registry that holds and manages dependencies for components.
  final _di = DIRegistry();

  World();

  /// Used to generate unique dependency IDs.
  static int _dependencyCount = 0;

  /// Returns a new unique ID for a dependency.
  static int _newUniqueId() => _dependencyCount++;

  /// Creates a new [WorldEntity] with a unique ID.
  WorldEntity createUniqueEntity() => WorldEntity._(_newUniqueId(), this);

  /// Adds the [component] to the [entity].
  void addComponent(Entity entity, Component component) {
    _di.setDependency(
      Dependency(
        Sync.value(Ok(component)),
        metadata: Some(
          DependencyMetadata(
            groupEntity: entity,
            preemptivetypeEntity: TypeEntity(component.runtimeType),
            index: Some(_dependencyCount),
          ),
        ),
      ),
    );
  }

  /// Adds all [components] to the [entity].
  void addAllComponents(Entity entity, Set<Component> components) {
    for (final component in components) {
      addComponent(entity, component);
    }
  }

  /// Returns the entities that have the specified component.
  Iterable<WorldEntity> withComponent<T extends Component>() {
    UNSAFE:
    return _di.dependenciesWhereType<T>().map(
      (e) => e.metadata.unwrap().groupEntity as WorldEntity,
    );
  }

  /// Updates the component of type [T] for the given entity.
  /// Returns an [Ok] with the updated component or an [Err] if the component
  /// does not exist.
  Result<Component> updateComponent<T extends Component>(
    Entity entity,
    T newComponent,
  ) {
    final dependency = _di.getDependency<T>(groupEntity: entity);
    if (dependency.isSome()) {
      UNSAFE:
      _di.setDependency(
        Dependency<T>(
          Sync.value(Ok(newComponent)),
          metadata: dependency.unwrap().metadata,
        ),
      );
      return Ok(newComponent);
    } else {
      return Err('Component of type $T does not exist for entity $entity.');
    }
  }

  /// Removes the given entity and its associated components from the registry.
  void removeEntity(Entity entity) {
    _di.removeGroup(groupEntity: entity);
  }

  /// Queries entities that satisfy all the provided conditions.
  ///
  /// ```dart
  /// final results = query([
  ///       withComponent<Name>,
  ///       withComponent<Position>,
  ///       withComponent<Velocity>,
  ///     ])
  /// ```
  Set<WorldEntity> query(List<Iterable<WorldEntity> Function()> queries) {
    Set<WorldEntity>? result;
    for (final query in queries) {
      final t1 = query().toSet();
      result ??= t1;
      if (result != t1) {
        result = result.intersection(t1);
      }
    }
    return result ?? {};
  }

  /// Queries entities that have the specified component [T1].
  Iterable<WorldEntity> query1<T1 extends Component>() {
    return query([withComponent<T1>]);
  }

  /// Queries entities that have both the specified components [T1] and [T2].
  Iterable<WorldEntity> query2<T1 extends Component, T2 extends Component>() {
    return query([withComponent<T1>, withComponent<T2>]);
  }

  /// Queries entities that have the specified components [T1], [T2], and [T3].
  Iterable<WorldEntity>
  query3<T1 extends Component, T2 extends Component, T3 extends Component>() {
    return query([withComponent<T1>, withComponent<T2>, withComponent<T3>]);
  }

  /// Queries entities that have the specified components [T1], [T2], [T3], and
  /// [T4].
  Iterable<WorldEntity> query4<
    T1 extends Component,
    T2 extends Component,
    T3 extends Component,
    T4 extends Component
  >() {
    return query([
      withComponent<T1>,
      withComponent<T2>,
      withComponent<T3>,
      withComponent<T4>,
    ]);
  }

  /// Queries entities that have the specified components [T1], [T2], [T3],
  /// [T4], and [T5].
  Iterable<WorldEntity> query5<
    T1 extends Component,
    T2 extends Component,
    T3 extends Component,
    T4 extends Component,
    T5 extends Component
  >() {
    return query([
      withComponent<T1>,
      withComponent<T2>,
      withComponent<T3>,
      withComponent<T4>,
      withComponent<T5>,
    ]);
  }

  /// Queries entities that have the specified components [T1], [T2], [T3],
  /// [T4], [T5], and [T6].
  Iterable<WorldEntity> query6<
    T1 extends Component,
    T2 extends Component,
    T3 extends Component,
    T4 extends Component,
    T5 extends Component,
    T6 extends Component
  >() {
    return query([
      withComponent<T1>,
      withComponent<T2>,
      withComponent<T3>,
      withComponent<T4>,
      withComponent<T5>,
      withComponent<T6>,
    ]);
  }

  /// Queries entities that have the specified components [T1], [T2], [T3],
  /// [T4], [T5], [T6], and [T7].
  Iterable<WorldEntity> query7<
    T1 extends Component,
    T2 extends Component,
    T3 extends Component,
    T4 extends Component,
    T5 extends Component,
    T6 extends Component,
    T7 extends Component
  >() {
    return query([
      withComponent<T1>,
      withComponent<T2>,
      withComponent<T3>,
      withComponent<T4>,
      withComponent<T5>,
      withComponent<T6>,
      withComponent<T7>,
    ]);
  }

  /// Queries entities that have the specified components [T1], [T2], [T3],
  /// [T4], [T5], [T6], [T7], and [T8].
  Iterable<WorldEntity> query8<
    T1 extends Component,
    T2 extends Component,
    T3 extends Component,
    T4 extends Component,
    T5 extends Component,
    T6 extends Component,
    T7 extends Component,
    T8 extends Component
  >() {
    return query([
      withComponent<T1>,
      withComponent<T2>,
      withComponent<T3>,
      withComponent<T4>,
      withComponent<T5>,
      withComponent<T6>,
      withComponent<T7>,
      withComponent<T8>,
    ]);
  }

  /// Queries entities that have the specified components [T1], [T2], [T3],
  /// [T4], [T5], [T6], [T7], [T8], and [T9].
  Iterable<WorldEntity> query9<
    T1 extends Component,
    T2 extends Component,
    T3 extends Component,
    T4 extends Component,
    T5 extends Component,
    T6 extends Component,
    T7 extends Component,
    T8 extends Component,
    T9 extends Component
  >() {
    return query([
      withComponent<T1>,
      withComponent<T2>,
      withComponent<T3>,
      withComponent<T4>,
      withComponent<T5>,
      withComponent<T6>,
      withComponent<T7>,
      withComponent<T8>,
      withComponent<T9>,
    ]);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Represents an entity with components in the ECS/World system. Manages
/// dependencies and allows retrieval of a specific component.
final class WorldEntity extends Entity {
  final World world;
  const WorldEntity._(super.value, this.world);

  /// Retrieves all dependencies (components) associated with this entity.
  Iterable<Dependency> _getDependencies<T extends Object>() {
    return world._di.getGroup(groupEntity: this).values;
  }

  /// Retrieves the component of type [T] associated with this entity.
  Option<T> getComponent<T extends Object>() {
    UNSAFE:
    return Option.from(
      _getDependencies()
          .map((e) => e.value.unwrap())
          .whereType<T>()
          .firstOrNull,
    );
  }

  /// Returns the entity itself.
  Entity getEntity() => this;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A base class for components that are equatable.
/// Components should extend this class to be used in the ECS system.
abstract class Component extends Equatable {
  const Component();
}
