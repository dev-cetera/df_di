# Entity Component System (ECS)

`df_di` ships with a small, Bevy-inspired Entity-Component-System built
**directly on top of `DIRegistry`**. Components, resources, and entity-presence
markers live as DI dependencies; queries use a reverse type-index inside the
registry so `World.query2<A, B>()` is O(K) in the size of the smallest
matching bucket, not O(N) in the total number of registered dependencies.

The same DI machinery you already use for services (lifecycle hooks, change
listeners, snapshots, `unregisterAll`) keeps working — an ECS world is just a
typed view over the registry.

The public surface mirrors Bevy:

| Bevy concept            | `df_di` equivalent                            |
|-------------------------|-----------------------------------------------|
| `World`                 | `World`                                       |
| `Entity`                | `WorldEntity`                                 |
| `Component` trait       | `extends Component`                           |
| `Resource` / `Res<T>`   | `extends Resource`                            |
| `Event`                 | `extends Event`                               |
| `Bundle` trait          | `extends Bundle`                              |
| `System` (fn/struct)    | `extends System` / `FunctionSystem(...)`      |
| `Plugin`                | `extends EcsPlugin`                           |
| `Startup` schedule      | `world.addStartupSystem(...)`                 |
| `Update` schedule       | `world.addSystem(...)`                        |
| `Query<(&A, &B)>`       | `world.each2<A, B>()` / `world.query2<A, B>`  |
| `commands.insert(...)`  | `entity.insert(...)`                          |
| `commands.despawn()`    | `entity.despawn()`                            |

---

## 1. Components, resources, events

Everything is a plain Dart class. Components must be immutable — replace, do
not mutate.

```dart
import 'package:df_di/df_di.dart';

class Position extends Component {
  final double x;
  final double y;
  const Position(this.x, this.y);
  Position translated(double dx, double dy) => Position(x + dx, y + dy);
}

class Velocity extends Component {
  final double dx;
  final double dy;
  const Velocity(this.dx, this.dy);
}

class Health extends Component {
  final int current;
  final int max;
  const Health(this.current, this.max);
  Health damaged(int amount) =>
      Health((current - amount).clamp(0, max), max);
  bool get isDead => current <= 0;
}

// Tag components carry no fields — perfect for marking entities.
class Player extends Component {
  const Player();
}

// Resources are global, type-keyed singletons.
class GameTime extends Resource {
  final double seconds;
  const GameTime(this.seconds);
}

// Events ride the world's pub/sub bus.
class EntityDied extends Event {
  final int entityId;
  const EntityDied(this.entityId);
}
```

## 2. Spawn, insert, query, despawn

```dart
final world = World();

final player = world.spawn([
  const Position(0, 0),
  const Velocity(1, 0),
  const Health(100, 100),
  const Player(),
]);

// Chainable inserts.
world.spawn()
  ..insert(const Position(10, 0))
  ..insert(const Health(20, 20));

// Read.
final pos = player.get<Position>();    // Option<Position>
final hp = player.require<Health>();   // throws if absent
final hasPlayerTag = player.has<Player>();

// Replace / mutate.
player.insert(const Position(5, 5));
player.mutate<Health>((h) => h.damaged(10));

// Remove a single component (the entity stays alive).
player.remove<Velocity>();

// Despawn the entity entirely.
player.despawn();
```

`each1`–`each3` yield the components alongside the entity as a record — this
is what you usually want inside a system:

```dart
for (final (entity, position, velocity) in world.each2<Position, Velocity>()) {
  // position and velocity are typed and already resolved.
}
```

For more than three component types use `queryTypes` (passes the bucket
intersection straight to the registry's reverse index):

```dart
for (final entity in world.queryTypes([Position, Velocity, Health, Player])) {
  // ...
}
```

## 3. Systems

A `System` is the unit of logic. It's stateless about *which* entities it
touches — it queries the world each tick.

```dart
class MovementSystem extends System {
  @override
  void update(World world, Duration dt) {
    final s = dt.inMicroseconds / Duration.microsecondsPerSecond;
    for (final (entity, position, velocity) in world.each2<Position, Velocity>()) {
      entity.insert(position.translated(velocity.dx * s, velocity.dy * s));
    }
  }
}

class DeathSystem extends System {
  @override
  void update(World world, Duration dt) {
    final dead = <WorldEntity>[];
    for (final (entity, health) in world.each1<Health>()) {
      if (health.isDead) dead.add(entity);
    }
    for (final entity in dead) {
      world.sendEvent(EntityDied(entity.id));
      entity.despawn();
    }
  }
}
```

Wire systems into the world, then drive it with `update`:

```dart
world
  ..addStartupSystem(SpawnPlayer())   // runs once before the first update
  ..addSystem(MovementSystem())       // runs every update, in registration order
  ..addSystem(DeathSystem());

// Game loop.
world.update(const Duration(milliseconds: 16));
```

`FunctionSystem` covers one-off behaviour:

```dart
world.addSystem(FunctionSystem((world, dt) {
  print('elapsed: ${world.elapsed}');
}));
```

## 4. Resources

```dart
world.insertResource(GameTime(0));

final time = world.requireResource<GameTime>();  // throws if missing
final maybe = world.getResource<GameTime>();     // Option<GameTime>

world.removeResource<GameTime>();
```

Resources are stored in `DIRegistry` under a reserved group, so anything that
already works against the registry (snapshots, change listeners) sees them.

**`ServiceMixin` cascade.** A `Resource` (or `Component`) that mixes
`ServiceMixin` has its `dispose()` fired automatically on `removeResource` /
`despawn` / `clearEntities` / `World.dispose`. Subscriptions, timers, and
stream controllers attached via the lifecycle hooks are torn down without
manual cleanup:

```dart
class GameLoop extends Resource with ServiceMixin {
  Timer? _tick;
  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
    (_) => Sync(() {
      _tick = Timer.periodic(/* ... */);
      return Unit();
    }),
  ];
  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
    (_) => Sync(() { _tick?.cancel(); return Unit(); }),
  ];
  // pause/resume listeners as needed
}

// `world.dispose()` cascades to `gameLoop.dispose()`, which cancels the timer.
```

## 5. Events

Events are dispatched synchronously to subscribers and also buffered for the
current tick so systems can read them.

```dart
final unsubscribe = world.onEvent<EntityDied>((event) {
  print('entity ${event.entityId} died');
});

// Inside a system:
class DamageReporter extends System {
  @override
  void update(World world, Duration dt) {
    for (final death in world.readEvents<EntityDied>()) {
      print('reported: ${death.entityId}');
    }
  }
}

// Later:
unsubscribe();
```

The buffer is cleared at the end of the outermost `World.update`. Re-entrant
updates (a system calling `world.update` recursively) share the outer tick's
buffer — events sent before the re-entry remain visible to subsequent
outer-tick systems.

**Subtype propagation (Liskov).** `sendEvent<Derived>` reaches every
`onEvent<Base>` listener whose `Base` is a supertype of `Derived`, and
`readEvents<Base>()` includes derived events sent this tick:

```dart
class EntityDamaged extends Event { /* ... */ }
class EntityCrit extends EntityDamaged { /* ... */ }

world.onEvent<EntityDamaged>((e) {
  // Fires for both EntityDamaged AND EntityCrit instances.
});

world.sendEvent(EntityCrit(/* ... */));   // Triggers the EntityDamaged listener.
```

## 6. Bundles

`Bundle` is a convenience for spawning a fixed set of components together —
Bevy's `Bundle` trait, minus the derive macro.

```dart
class PlayerBundle extends Bundle {
  const PlayerBundle({required this.position});
  final Position position;

  @override
  Iterable<Component> get components => [
    position,
    const Velocity(1, 0),
    const Health(100, 100),
    const Player(),
  ];
}

final hero = world.spawnBundle(const PlayerBundle(position: Position(0, 0)));
```

## 7. Plugins

`EcsPlugin`s package related systems, resources, and event wiring into reusable
modules. (Named `EcsPlugin` to distinguish from the app-level `Plugin` in
`df_di` that owns a DI scope rather than a `World`.)

```dart
class CombatPlugin extends EcsPlugin {
  const CombatPlugin();

  @override
  void build(World world) {
    world
      ..insertResource(const GameTime(0))
      ..addSystem(MovementSystem())
      ..addSystem(DeathSystem());
  }
}

world.addPlugin(const CombatPlugin());
```

## 8. Putting it together

```dart
void main() {
  final world = World()..addPlugin(const CombatPlugin());

  world.spawn([
    const Position(0, 0),
    const Velocity(1, 0),
    const Health(100, 100),
    const Player(),
  ]);

  for (var i = 0; i < 60; i++) {
    world.update(const Duration(milliseconds: 16));
  }

  for (final (entity, position) in world.each1<Position>()) {
    print('${entity.id} @ (${position.x.toStringAsFixed(2)}, ${position.y.toStringAsFixed(2)})');
  }

  world.dispose(); // disposes systems, clears the registry, drops listeners.
}
```

## 9. Reaching the registry

Sometimes you want to look at the underlying DI state — for tooling, tests,
or to integrate the ECS with existing services. `World.registry` exposes the
`DIRegistry` directly:

```dart
// Every group key that holds a Position. Backed by the reverse type-index,
// so this is O(K) in the number of matching entities.
final groups = world.registry.groupsWithTypeT(Position);
```

## Design notes

- **DIRegistry-backed.** Components live under their owning entity's group;
  resources live under a reserved group. Existing DI tooling keeps working.
- **Fast queries.** `DIRegistry` maintains a reverse `typeEntity → groups`
  index. `withComponent`, `query*`, and `each*` use it — no full-state scan.
- **Exact-type storage for components.** A component is keyed by its exact
  runtime class; storing `Velocity` does not satisfy a lookup for a parent
  type. Compose, don't subclass.
- **One component per type per entity.** `insert` replaces.
- **Per-world entity ids.** Ids start at 0 and grow within a world; do not
  compare `WorldEntity`s across different `World`s.
- **Ids are not recycled.** Once despawned, an id is not reused.
- **Synchronous events with subtype propagation.** `sendEvent` invokes
  listeners immediately and buffers for `readEvents` until the end of the
  outermost tick. The flat buffer + `is E` filter means a derived event
  reaches base-typed listeners and readers.
- **Re-entrant `update` is safe.** A system calling `world.update`
  recursively shares the outer tick's event buffer; only the outermost
  return drains it. Systems and entities mutate the world safely from
  within a tick.
- **`ServiceMixin` cascade.** Removing a resource or component (or
  disposing the world) that mixes `ServiceMixin` fires its `dispose()`
  fire-and-forget — attached subscriptions / timers don't leak past
  ECS teardown.
- **Deterministic schedule.** Systems run in the order they were added; the
  startup phase runs once before the first regular `update`.
- **`World.dispose` is terminal.** Asserts surface use-after-dispose in
  debug; in release `update` is a silent no-op and `spawn` / `addSystem` /
  `insertResource` are best-effort. Construct a fresh `World` to start over.
