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

/// Marker base class for components — the data half of the ECS, attached to
/// a [WorldEntity]. Inspired by Bevy: components are immutable values; logic
/// lives in [System]s, not on the components themselves. One concrete subclass
/// per entity (a second `add` replaces the first).
abstract class Component {
  const Component();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Marker base class for resources — global, type-keyed state that is not
/// attached to any entity (time, input, config, scoreboards, RNGs, etc.).
/// Bevy's equivalent of `Res<T>` / `ResMut<T>`.
abstract class Resource {
  const Resource();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Marker base class for events dispatched through [World.sendEvent].
abstract class Event {
  const Event();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Bundles let you spawn a fixed set of components with one call. Bevy's
/// equivalent of the `Bundle` trait.
///
/// ```dart
/// class PlayerBundle extends Bundle {
///   const PlayerBundle({required this.position});
///   final Position position;
///   @override
///   Iterable<Component> get components => [position, const Player()];
/// }
///
/// world.spawn().insertBundle(const PlayerBundle(position: Position(0, 0)));
/// ```
abstract class Bundle {
  const Bundle();
  Iterable<Component> get components;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A Bevy-inspired Entity-Component-System container backed by [DIRegistry].
///
/// Components, resources, entity-presence markers, and bundles all live as
/// dependencies in an internal [DIRegistry]; queries use its reverse type
/// index to fetch matching entities in O(K) rather than scanning every
/// dependency. The DI registry is exposed via [registry] so existing DI
/// tooling (lifecycle callbacks, snapshots, change listeners) keeps working.
///
/// ```dart
/// final world = World()
///   ..insertResource(const GameTime(0))
///   ..addStartupSystem(SpawnPlayer())
///   ..addSystem(MovementSystem())
///   ..addSystem(DamageSystem());
///
/// while (running) {
///   world.update(const Duration(milliseconds: 16));
/// }
/// ```
class World {
  World({Option<DIRegistry> registry = const None()})
      : registry = switch (registry) {
          Some(value: final r) => r,
          None() => DIRegistry(),
        };

  /// The backing DI registry. Components are stored under their owning
  /// entity's group; resources live under [_resourceGroup]; the alive-tag
  /// component anchors empty entities. Direct manipulation is supported but
  /// rarely needed — prefer the typed [World] / [WorldEntity] API.
  final DIRegistry registry;

  /// Reserved group for global resources.
  static const Entity _resourceGroup = _EcsResourceGroup();

  /// Type entity used to mark a spawned entity that has no other components
  /// yet, so it still appears in queries that iterate alive entities.
  static final Entity _aliveTagType = TypeEntity(_AliveTag);

  final List<System> _startupSystems = [];
  final List<System> _systems = [];
  bool _ranStartup = false;

  final Map<Type, List<void Function(Object event)>> _eventListeners = {};
  final Map<Type, List<Object>> _eventBuffers = {};

  int _nextEntityId = 0;
  Duration _elapsed = Duration.zero;
  bool _disposed = false;

  /// Cumulative time advanced through [update] since this world was created.
  Duration get elapsed => _elapsed;

  /// Whether [dispose] has been called.
  bool get isDisposed => _disposed;

  /// Systems registered to run every [update], in execution order.
  List<System> get systems => List.unmodifiable(_systems);

  /// Systems registered to run once before the first [update].
  List<System> get startupSystems => List.unmodifiable(_startupSystems);

  /// Spawns a new entity. If [components] are provided, they are attached
  /// immediately. Otherwise an alive-tag component is inserted so the entity
  /// remains visible to [entities] / queries until it gets real components.
  WorldEntity spawn([
    Option<Iterable<Component>> components = const None(),
  ]) {
    final entity = WorldEntity._(_nextEntityId++, this);
    final cs = switch (components) {
      Some(value: final c) when c.isNotEmpty => c,
      _ => const <Component>[],
    };
    if (cs.isEmpty) {
      _writeComponent(entity, const _AliveTag());
    } else {
      for (final c in cs) {
        _writeComponent(entity, c);
      }
    }
    return entity;
  }

  /// Spawns and returns the entity wrapped by [bundle].
  WorldEntity spawnBundle(Bundle bundle) => spawn(Some(bundle.components));

  /// Removes [entity] and all of its components. Returns `true` if the entity
  /// was alive.
  bool despawn(WorldEntity entity) {
    if (!_isAlive(entity)) return false;
    registry.removeGroup(groupEntity: entity);
    return true;
  }

  /// Removes every entity and component but keeps systems, resources, and
  /// event subscriptions.
  void clearEntities() {
    for (final entity in entities.toList()) {
      registry.removeGroup(groupEntity: entity);
    }
  }

  /// All entities currently alive in this world.
  Iterable<WorldEntity> get entities sync* {
    for (final group in registry.groupEntities) {
      if (_isWorldEntity(group)) yield group as WorldEntity;
    }
  }

  /// Number of live entities.
  int get entityCount {
    var n = 0;
    for (final group in registry.groupEntities) {
      if (_isWorldEntity(group)) n++;
    }
    return n;
  }

  bool _isAlive(WorldEntity entity) =>
      identical(entity.world, this) &&
      registry.getGroup(groupEntity: entity).isNotEmpty;

  bool _isWorldEntity(Entity entity) =>
      entity is WorldEntity && identical(entity.world, this);

  void _writeComponent(WorldEntity entity, Component component) {
    registry.setDependency(
      Dependency(
        Sync.okValue(component),
        metadata: Some(
          DependencyMetadata(
            groupEntity: entity,
            preemptivetypeEntity: TypeEntity(component.runtimeType),
          ),
        ),
      ),
    );
    // The first real component supersedes the alive-tag.
    if (component is! _AliveTag) {
      registry.removeDependencyExact(_aliveTagType, groupEntity: entity).end();
    }
  }

  Option<T> _readComponent<T extends Component>(WorldEntity entity) {
    final dep = registry.getGroup(groupEntity: entity)[TypeEntity(T)];
    if (dep == null) return const None();
    UNSAFE:
    final value = dep.value.unwrap();
    if (value is! T) return const None();
    return Some(value);
  }

  Option<T> _eraseComponent<T extends Component>(WorldEntity entity) {
    final removed = registry.removeDependencyExact(
      TypeEntity(T),
      groupEntity: entity,
    );
    if (removed.isNone()) return const None();
    UNSAFE:
    final value = removed.unwrap().value.unwrap();
    if (value is! T) return const None();
    // If we just removed the last real component, re-attach the alive-tag so
    // the entity still appears in [entities] until despawned.
    if (registry.getGroup(groupEntity: entity).isEmpty) {
      _writeComponent(entity, const _AliveTag());
    }
    return Some(value);
  }

  bool _hasComponent<T extends Component>(WorldEntity entity) =>
      registry.getGroup(groupEntity: entity).containsKey(TypeEntity(T));

  /// Reads the component of type [T] from [entity], or [None] if absent.
  Option<T> get<T extends Component>(WorldEntity entity) =>
      _readComponent<T>(entity);

  /// Sets or replaces a component on [entity].
  void set(WorldEntity entity, Component component) =>
      _writeComponent(entity, component);

  /// Replaces the component of type [T] using [update]. Returns the new
  /// value, or [None] if [entity] has no component of type [T].
  ///
  /// The new value is written into the slot keyed by [T] even when [update]
  /// returns a subclass — `get<T>()` stays stable instead of leaving the old
  /// [T] alongside a parallel subclass entry.
  Option<T> mutate<T extends Component>(
    WorldEntity entity,
    T Function(T current) update,
  ) {
    final current = _readComponent<T>(entity);
    if (current.isNone()) return const None();
    UNSAFE:
    final next = update(current.unwrap());
    registry.setDependency(
      Dependency(
        Sync.okValue(next),
        metadata: Some(
          DependencyMetadata(
            groupEntity: entity,
            preemptivetypeEntity: TypeEntity(T),
          ),
        ),
      ),
    );
    return Some(next);
  }

  /// Removes the component of type [T] from [entity].
  Option<T> remove<T extends Component>(WorldEntity entity) =>
      _eraseComponent<T>(entity);

  /// Whether [entity] has a component of type [T].
  bool has<T extends Component>(WorldEntity entity) => _hasComponent<T>(entity);

  /// Every alive entity that has a component of type [T]. O(K) using the
  /// reverse type index in [DIRegistry]. A snapshot of the bucket is taken
  /// up-front so callers can safely insert, remove, or despawn entities
  /// mid-iteration.
  Iterable<WorldEntity> withComponent<T extends Component>() sync* {
    final snapshot = registry.groupsWithTypeK(TypeEntity(T)).toList();
    for (final group in snapshot) {
      if (_isWorldEntity(group)) yield group as WorldEntity;
    }
  }

  /// Entities that hold every type in [types]. The smallest matching bucket
  /// is iterated first; missing types short-circuit to an empty result.
  Iterable<WorldEntity> queryTypes(List<Type> types) sync* {
    if (types.isEmpty) {
      yield* entities;
      return;
    }
    final buckets = <Set<Entity>>[];
    for (final type in types) {
      final bucket = registry.groupsWithTypeK(TypeEntity(type));
      if (bucket.isEmpty) return;
      buckets.add(bucket.toSet());
    }
    buckets.sort((a, b) => a.length.compareTo(b.length));
    final smallest = buckets.first;
    outer:
    for (final group in smallest) {
      if (!_isWorldEntity(group)) continue;
      for (var i = 1; i < buckets.length; i++) {
        if (!buckets[i].contains(group)) continue outer;
      }
      yield group as WorldEntity;
    }
  }

  Iterable<WorldEntity> query1<T1 extends Component>() => queryTypes([T1]);

  Iterable<WorldEntity> query2<T1 extends Component, T2 extends Component>() =>
      queryTypes([T1, T2]);

  Iterable<WorldEntity> query3<T1 extends Component, T2 extends Component,
          T3 extends Component>() =>
      queryTypes([T1, T2, T3]);

  Iterable<WorldEntity> query4<T1 extends Component, T2 extends Component,
          T3 extends Component, T4 extends Component>() =>
      queryTypes([T1, T2, T3, T4]);

  Iterable<WorldEntity> query5<T1 extends Component, T2 extends Component,
          T3 extends Component, T4 extends Component, T5 extends Component>() =>
      queryTypes([T1, T2, T3, T4, T5]);

  /// Iterates `(entity, T1)` for every entity with a [T1] component. Inspired
  /// by Bevy's `Query<&T>`.
  Iterable<(WorldEntity, T1)> each1<T1 extends Component>() sync* {
    for (final entity in withComponent<T1>()) {
      final c = _readComponent<T1>(entity);
      if (c.isSome()) {
        UNSAFE:
        yield (entity, c.unwrap());
      }
    }
  }

  /// Iterates `(entity, T1, T2)` for every entity with both components.
  Iterable<(WorldEntity, T1, T2)>
      each2<T1 extends Component, T2 extends Component>() sync* {
    for (final entity in query2<T1, T2>()) {
      final c1 = _readComponent<T1>(entity);
      final c2 = _readComponent<T2>(entity);
      if (c1.isSome() && c2.isSome()) {
        UNSAFE:
        yield (entity, c1.unwrap(), c2.unwrap());
      }
    }
  }

  /// Iterates `(entity, T1, T2, T3)` for every entity with all three.
  Iterable<(WorldEntity, T1, T2, T3)> each3<T1 extends Component,
      T2 extends Component, T3 extends Component>() sync* {
    for (final entity in query3<T1, T2, T3>()) {
      final c1 = _readComponent<T1>(entity);
      final c2 = _readComponent<T2>(entity);
      final c3 = _readComponent<T3>(entity);
      if (c1.isSome() && c2.isSome() && c3.isSome()) {
        UNSAFE:
        yield (entity, c1.unwrap(), c2.unwrap(), c3.unwrap());
      }
    }
  }

  /// Inserts or replaces the global resource of type [T]. Bevy's
  /// `app.insert_resource(...)`.
  void insertResource<T extends Resource>(T resource) {
    registry.setDependency(
      Dependency(
        Sync.okValue(resource),
        metadata: Some(
          DependencyMetadata(
            groupEntity: _resourceGroup,
            preemptivetypeEntity: TypeEntity(resource.runtimeType),
          ),
        ),
      ),
    );
  }

  /// Returns the resource of type [T], or [None] if not registered.
  Option<T> getResource<T extends Resource>() {
    final dep = registry.getGroup(groupEntity: _resourceGroup)[TypeEntity(T)];
    if (dep == null) return const None();
    UNSAFE:
    final value = dep.value.unwrap();
    if (value is! T) return const None();
    return Some(value);
  }

  /// Returns the resource of type [T] or throws if not registered.
  T requireResource<T extends Resource>() {
    final option = getResource<T>();
    if (option.isNone()) {
      throw StateError(
        'Resource of type $T not registered. Call insertResource<$T>() first.',
      );
    }
    UNSAFE:
    return option.unwrap();
  }

  /// Removes and returns the resource of type [T].
  Option<T> removeResource<T extends Resource>() {
    final removed = registry.removeDependencyExact(
      TypeEntity(T),
      groupEntity: _resourceGroup,
    );
    if (removed.isNone()) return const None();
    UNSAFE:
    final value = removed.unwrap().value.unwrap();
    if (value is! T) return const None();
    return Some(value);
  }

  /// Adds [system] to the schedule. Runs every [update] in registration order.
  /// Returns `this` for chaining.
  World addSystem(System system) {
    _systems.add(system);
    system.init(this);
    return this;
  }

  /// Adds [system] to the startup schedule. Runs once, before the first
  /// regular [update]. Returns `this` for chaining.
  World addStartupSystem(System system) {
    _startupSystems.add(system);
    system.init(this);
    return this;
  }

  /// Removes [system] from either schedule, calling its [System.dispose].
  bool removeSystem(System system) {
    final removed = _systems.remove(system) || _startupSystems.remove(system);
    if (removed) system.dispose(this);
    return removed;
  }

  /// Installs [plugin], letting it register systems, resources, and event
  /// subscriptions. Returns `this` for chaining. Bevy's `app.add_plugin(...)`.
  World addPlugin(EcsPlugin plugin) {
    plugin.build(this);
    return this;
  }

  /// Advances the world by [dt]. The first call also runs every startup
  /// system. Drains the per-tick event buffer after all systems have run.
  /// No-op if the world has been disposed.
  ///
  /// System lists are snapshotted before iteration so a running system can
  /// safely add or remove systems; the change takes effect on the next tick.
  void update(Duration dt) {
    if (_disposed) return;
    if (!_ranStartup) {
      _ranStartup = true;
      for (final system in List.of(_startupSystems)) {
        system.update(this, Duration.zero);
      }
    }
    _elapsed += dt;
    for (final system in List.of(_systems)) {
      system.update(this, dt);
    }
    _eventBuffers.clear();
  }

  /// Synchronously dispatches [event] to every listener registered for its
  /// exact runtime type, then buffers it for [readEvents] until the next tick
  /// ends. A snapshot of the listener list is taken so subscribing or
  /// unsubscribing inside a handler does not affect the current dispatch.
  void sendEvent<E extends Event>(E event) {
    final type = event.runtimeType;
    (_eventBuffers[type] ??= <Object>[]).add(event);
    final listeners = _eventListeners[type];
    if (listeners == null || listeners.isEmpty) return;
    for (final listener in List.of(listeners)) {
      listener(event);
    }
  }

  /// Returns the events of type [E] sent so far this tick. Cleared at the
  /// end of every [update].
  Iterable<E> readEvents<E extends Event>() {
    final buffer = _eventBuffers[E];
    if (buffer == null || buffer.isEmpty) return const Iterable.empty();
    return buffer.cast<E>();
  }

  /// Subscribes to events of type [E]. Returns a closure that removes the
  /// subscription when called.
  void Function() onEvent<E extends Event>(void Function(E event) listener) {
    final listeners = _eventListeners.putIfAbsent(E, () => []);
    void wrapper(Object event) => listener(event as E);
    listeners.add(wrapper);
    return () => listeners.remove(wrapper);
  }

  /// Tears the world down: disposes every system (startup and regular),
  /// clears the registry, drops event subscriptions, and marks the world so
  /// further [update] calls are no-ops.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final system in List.of(_systems)) {
      system.dispose(this);
    }
    for (final system in List.of(_startupSystems)) {
      system.dispose(this);
    }
    _systems.clear();
    _startupSystems.clear();
    registry.clear();
    _eventListeners.clear();
    _eventBuffers.clear();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A lightweight handle to an entity inside a specific [World]. Equality is
/// based on [Entity.id]; do not compare entities from different worlds.
final class WorldEntity extends Entity {
  /// The world this entity belongs to.
  final World world;

  const WorldEntity._(super.id, this.world);

  /// Whether this entity still has at least one component in [world].
  bool get alive => world._isAlive(this);

  /// Sets or replaces a component on this entity. Bevy's `commands.insert`.
  WorldEntity insert(Component component) {
    world._writeComponent(this, component);
    return this;
  }

  /// Inserts every component in [components].
  WorldEntity insertAll(Iterable<Component> components) {
    for (final c in components) {
      world._writeComponent(this, c);
    }
    return this;
  }

  /// Inserts every component in [bundle].
  WorldEntity insertBundle(Bundle bundle) => insertAll(bundle.components);

  /// Reads the component of type [T], or [None] if absent.
  Option<T> get<T extends Component>() => world._readComponent<T>(this);

  /// Reads the component of type [T], throwing if absent.
  T require<T extends Component>() {
    final option = world._readComponent<T>(this);
    if (option.isNone()) {
      throw StateError('Entity $id has no component of type $T.');
    }
    UNSAFE:
    return option.unwrap();
  }

  /// Whether this entity has a component of type [T].
  bool has<T extends Component>() => world._hasComponent<T>(this);

  /// Removes the component of type [T] from this entity.
  Option<T> remove<T extends Component>() => world._eraseComponent<T>(this);

  /// Replaces the component of type [T] using [update].
  Option<T> mutate<T extends Component>(T Function(T current) update) =>
      world.mutate<T>(this, update);

  /// Despawns this entity. Returns `true` if it was alive.
  bool despawn() => world.despawn(this);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Logic that operates on a [World] every tick. Systems are stateless about
/// which entities they touch — they query the world each call.
abstract class System {
  const System();

  /// Called once when the system is registered with a world.
  void init(World world) {}

  /// Called from [World.update] (or once from the startup phase). [dt] is
  /// the delta supplied to `update`.
  void update(World world, Duration dt);

  /// Called when the system is removed or the world is disposed.
  void dispose(World world) {}
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A [System] implemented with callbacks. Useful for one-off behaviour or
/// prototypes where a full subclass would be overkill.
class FunctionSystem extends System {
  final void Function(World world, Duration dt) _update;
  final Option<void Function(World world)> _init;
  final Option<void Function(World world)> _dispose;

  const FunctionSystem(
    void Function(World world, Duration dt) update, {
    Option<void Function(World world)> init = const None(),
    Option<void Function(World world)> dispose = const None(),
  })  : _update = update,
        _init = init,
        _dispose = dispose;

  @override
  void init(World world) {
    if (_init case Some(value: final cb)) cb(world);
  }

  @override
  void update(World world, Duration dt) => _update(world, dt);

  @override
  void dispose(World world) {
    if (_dispose case Some(value: final cb)) cb(world);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A reusable bundle of systems, resources, and event wiring for an ECS
/// [World]. Named to distinguish it from the app-level [Plugin] (which owns
/// a DI scope rather than a [World]). Bevy's `Plugin` trait.
///
/// ```dart
/// class PhysicsPlugin extends EcsPlugin {
///   const PhysicsPlugin();
///   @override
///   void build(World world) {
///     world
///       ..insertResource(const Gravity(9.81))
///       ..addSystem(GravitySystem())
///       ..addSystem(MovementSystem());
///   }
/// }
/// ```
abstract class EcsPlugin {
  const EcsPlugin();
  void build(World world);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Reserved group entity used by [World] to store global [Resource]s in the
/// backing [DIRegistry].
final class _EcsResourceGroup extends Entity {
  const _EcsResourceGroup() : super.reserved(-20001);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Private alive-tag component. Attached to entities that have been spawned
/// but currently hold no user components, so the entity still appears in
/// [World.entities] until it gets a real component or is despawned.
final class _AliveTag extends Component {
  const _AliveTag();
}
