[![pub](https://img.shields.io/pub/v/df_di.svg)](https://pub.dev/packages/df_di)
[![tag](https://img.shields.io/badge/Tag-v0.16.0-purple?logo=github)](https://github.com/dev-cetera/df_di/tree/v0.16.0)
[![buymeacoffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/dev_cetera)
[![sponsor](https://img.shields.io/badge/Sponsor-grey?logo=github-sponsors&logoColor=pink)](https://github.com/sponsors/dev-cetera)
[![patreon](https://img.shields.io/badge/Patreon-grey?logo=patreon)](https://www.patreon.com/robelator)
[![discord](https://img.shields.io/badge/Discord-5865F2?logo=discord&logoColor=white)](https://discord.gg/gEQ8y2nfyX)
[![instagram](https://img.shields.io/badge/Instagram-E4405F?logo=instagram&logoColor=white)](https://www.instagram.com/dev_cetera/)
[![license](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/dev-cetera/df_di/main/LICENSE)

---

<!-- BEGIN _README_CONTENT -->

`df_di` is a lightweight, powerful "dependency injection" package for Dart and Flutter that makes your app modular, testable, and easy to maintain. It stops the confusion of finding and tracking services, like APIs or databases. With `df_di`, you store these services in "containers" that make them easy to access whenever you need them.

Why choose `df_di`? It’s inspired by [get_it](https://pub.dev/packages/get_it) but adds better type safety via monads provided by [df_safer_dart](https://pub.dev/packages/df_safer_dart), more robust async support, better debuggability and a very powerful `until` function that waits for dependencies to be ready, and much more. Whether you’re building a small Flutter app or a large-scale project, `df_di` keeps your code clean and your dependencies accessible.

## Quick Start: Managing a User Service

Let’s dive into a real-world example: managing a `UserService` that fetches user data. This shows how **df_di** containers shine in a Flutter app.

### Step 1: Create a User Service

```dart
class UserService {
  Future<String> getUserName() async {
    // Simulate fetching user data
    await Future.delayed(Duration(seconds: 1));
    return 'Alice';
  }

  Future<void> logOut() async {
    // Simulate the logout process.
    await Future.delayed(Duration(seconds: 1));
  }
}
```

### Step 2: Register the Service in a Container

Use a container to store the `UserService`. Here, we’ll put it in `DI.global` for app-wide access.

```dart
import 'package:df_di/df_di.dart';

void main() {
  // Register the UserService in the global container.
  // `onUnregister` receives a Result<UserService> — pattern-match so an
  // Err-resolved registration doesn't crash the unregister chain.
  DI.global.register<UserService>(
    UserService(),
    onUnregister: Some((result) {
      switch (result) {
        case Ok(value: final svc):
          svc.logOut();
        case Err():
          // Nothing to log out — the registration itself failed.
          break;
      }
    }),
  );
}
```

- **`DI.global`**: A built-in container for app-wide dependencies.
- **`register<UserService>`**: Stores the `UserService` instance, tagged by its type.
- **`onUnregister`** is `Option<TOnUnregisterCallback<T>>` — wrap your callback in `Some(...)`. The callback gets the dep's resolved `Result<T>` so you can clean up both successful and failed registrations.

### Step 3: Access the Service Anywhere

Retrieve the `UserService` from the container and use it in your Flutter widget.

```dart
import 'package:flutter/material.dart';

class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: DI.global<UserService>().getUserName(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        return Text('Welcome, ${snapshot.data ?? 'Guest'}!');
      },
    );
  }
}
```

- **`DI.global<UserService>()`**: Grabs the `UserService` from the container.
- The widget uses the service to fetch and display the user’s name.

This is the quick way, but it assumes the service exists. Let’s see a safer approach.

## Step 4: Safe Dependency Access

To avoid crashes if a dependency is missing, use `getSyncOrNone` and pattern-match the returned `Option<T>`:

```dart
void showUser() {
  switch (DI.global.getSyncOrNone<UserService>()) {
    case Some(value: final svc):
      print('Service found: $svc');
    case None():
      print('No UserService registered.');
  }
}
```

- **`getSyncOrNone<UserService>()`**: Returns `Some<UserService>` if found, or `None` if not.
- Pattern matching is the recommended style across this stack — it lets the compiler verify you've handled every case and avoids `.unwrap()` calls that could throw on `None`.

## Step 5: Hierarchical Containers

**df_di**’s containers can form a hierarchy, letting you scope dependencies. Built-in containers include:

- **`DI.global`**: For app-wide services (e.g., `UserService`).
- **`DI.session`**: For session-specific data (e.g., a logged-in user’s ID).
- **`DI.user`**: For user-specific data.

Child containers inherit from parents. Here’s an example:

```dart
void setupSession() {
  // Register a session ID in the session container
  DI.session.register<String>('session_123');

  // Access it from the user container
  final sessionId = DI.user<String>();
  print(sessionId); // Outputs: session_123
}
```

- **`DI.user`**: A child of `DI.session`, which is a child of `DI.global`.
- If `DI.user` doesn’t have a `String`, it checks `DI.session`, then `DI.global`.

You can also create custom hierarchies:

```dart
final featureContainer = DI();
final screenContainer = DI(parent: featureContainer);

featureContainer.register<String>('Feature data');
print(screenContainer<String>()); // Outputs: Feature data
```

## Step 6: Handling Async Dependencies

Need a dependency that’s not ready yet, like user data from an API? Wait for it with `untilSuper`:

```dart
Future<void> waitForService() async {
  // If UserService isn't registered yet, this resolves the moment it is.
  // IMPORTANT: T in untilSuper<T> should be the most general type expected —
  // see the docstring on `until<TSuper, TSub>` for the subtype rules.
  final result = await DI.global.untilSuper<UserService>().toAsync().value;
  switch (result) {
    case Ok(value: final service):
      print(await service.getUserName()); // Outputs: Alice
    case Err(:final error):
      print('Could not resolve UserService: $error');
  }
}
```

- **`untilSuper<UserService>()`**: Waits until a `UserService` is registered in the container or its parents. The returned `Resolvable<T>` lets you `.then(...)` chain or `.toAsync().value` await.
- Perfect for `FutureBuilder` to display data once it’s available — the resolved `Result<T>` distinguishes "loaded" from "failed".

## Step 7: Lazy Initialization

Save resources by registering dependencies that only create when needed:

```dart
DI.global.registerConstructor(UserService.new);

// This will create a new instance each time.
final a = DI.global.getLazySingletonSyncOrNone<UserService>(); // Created only now
final b = DI.global.getLazySingletonSyncOrNone<UserService>(); // NOT created again
print(a.unwrap() == b.unwrap()); // Outputs: true

// This will create a new instance each time.
final c = DI.global.getLazyFactorySyncOrNone<UserService>();
final d = DI.global.getLazyFactorySyncOrNone<UserService>();
print(c.unwrap() == d.unwrap()); // Outputs: false
```

- **`registerConstructor`**: The `UserService` is built only when first requested.

## Step 8: Cleaning Up

Remove dependencies when they’re no longer needed:

```dart
DI.session.register<String>('Temporary data');
DI.session.unregister<String>();

print(DI.session.isRegistered<String>()); // Outputs: false
```

You can also remove all dependencies at once — i.e. when you log the user out of a session:

```dart
// Unregisters all dependencies in reverse registration order. Each dep's
// `onUnregister` fires sequentially; ServiceMixin values have `dispose()`
// cascaded automatically.
DI.session.unregisterAll();
```

## Step 9: Service Lifecycle Management

`df_di` includes base service classes with well-defined lifecycle states (init, pause, resume, dispose). These integrate seamlessly with the DI system.

| Class | Purpose |
|-------|---------|
| `Service` | Base service with init/pause/resume/dispose lifecycle |
| `StreamService<TData>` | Service that manages a data stream |
| `PollingStreamService<TData>` | StreamService that polls at regular intervals |

```dart
import 'package:df_di/df_di.dart';

/// A simple counter service with lifecycle management.
final class CounterService extends Service {
  int _count = 0;
  int get count => _count;

  void increment() => _count++;

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
    (_) {
      _count = 0;
      print('CounterService initialized');
      return syncUnit();
    },
  ];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) => [];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) => [];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
    (_) {
      print('CounterService disposed with count: $_count');
      return syncUnit();
    },
  ];
}

// Register with DI and use lifecycle callbacks
DI.global.register<CounterService>(
  CounterService(),
  onRegister: (service) => service.init(),
  onUnregister: ServiceMixin.unregister, // Calls dispose() automatically
);

// Access the service
final counter = DI.global<CounterService>();
counter.increment();
```

For Flutter apps that need to respond to app lifecycle events (pause when backgrounded, resume when foregrounded), see the **Flutter integration** section below.

### Flutter integration via `df_flutter_services`

[`df_flutter_services`](https://pub.dev/packages/df_flutter_services) is the companion package that bridges `df_di` services to `WidgetsBindingObserver` and to the reactive `Pod<T>` containers in [`df_pod`](https://pub.dev/packages/df_pod):

| Class | What it adds on top of df_di |
| --- | --- |
| `ObservedService` | `Service` + `WidgetsBindingObserver`. Opt-in `handlePausedState() => true` / `handleResumedState() => true` hooks map `AppLifecycleState` changes to `pause()` / `resume()` / `dispose()`. The observer is registered in init listeners (not in the constructor), so constructing before `WidgetsFlutterBinding.ensureInitialized()` is safe. |
| `ObservedStreamService<T>` | `ObservedService` + `StreamServiceMixin<T>` — broadcast streams that auto-pause with the app lifecycle. |
| `ObservedDataStreamService<T>` | The most common subclass. Exposes `pData: Pod<Option<Result<T>>>` — a reactive container that mirrors the latest stream emission and is cleared (not disposed) on dispose so consumers can cache the reference across re-init cycles (relogin, etc.). |
| `ObservedPollingStreamService<T>` | Polling variant that stops the timer when the app backgrounds. |
| `HandleServiceLifecycleStateMixin` | Reusable mixin that wires the five `AppLifecycleState` hooks for any custom `Service` subclass. |

For the broader architecture (how Pods live on services, how DI scopes hold them, how Flutter lifecycle integrates) see [`doc/state_management_approach.md`](doc/state_management_approach.md).

## Plugin system

`df_di` ships with an app-level `Plugin` API for packaging features as **self-contained bundles** that can be installed and removed at runtime — themes, auth providers, analytics backends, optional integrations, etc.

Each installed plugin owns a fresh child `DI` scope keyed by `plugin.id`. Anything registered into that scope during `install` is torn down automatically on uninstall — including `ServiceMixin` services, whose `dispose()` is cascaded via the standard unregister hook.

```dart
import 'package:df_di/df_di.dart';

class AnalyticsPlugin extends Plugin {
  const AnalyticsPlugin();

  // Default id is `TypeEntity(runtimeType)` — only one of each plugin
  // can be installed per host scope at a time. Override `id` to allow
  // multiple keyed instances (e.g. `ThemePlugin` named 'dark' vs 'light').

  @override
  Resolvable<Unit> install(DI scope) {
    return scope
        .registerAndInitService(AnalyticsService())
        .then((_) => Unit());
  }

  @override
  Resolvable<Unit> uninstall(DI scope) {
    // Only cleanup the registry CAN'T do automatically goes here.
    // ServiceMixin services already have dispose() cascaded.
    return syncUnit();
  }
}

void main() {
  DI.global.installPlugin(const AnalyticsPlugin()).end();

  // Idempotent: subsequent installs of the same plugin id return the
  // existing scope without re-running install().
  if (DI.global.hasPlugin(const AnalyticsPlugin())) {
    print('analytics is on');
  }

  // Tears down: invokes uninstall(), then unregisterAll() on the plugin
  // scope (cascading dispose), then drops the scope itself.
  DI.global.uninstallPlugin(const AnalyticsPlugin()).end();
}
```

> **Note:** This `Plugin` API (owns a DI scope) is distinct from `EcsPlugin` (in `src/ecs/ecs.dart`), which bundles systems and resources into an ECS `World` rather than a DI scope. See [`doc/ecs_example.md`](doc/ecs_example.md) for ECS plugins.

### Lifecycle contract

Lifecycle methods return a `Resolvable<Unit>` whose resolved `Result<Unit>` is the authoritative success/failure signal — invalid transitions return `Err` rather than silently doing nothing:

| Transition | Result |
| --- | --- |
| `init()` on a fresh service | `Ok` — listeners run, state → `RUN_SUCCESS` (or `RUN_ERROR`). |
| `init()` after `init()` | `Err` — services are not re-initializable. |
| `init()` after `dispose()` | `Err` — disposed is terminal; construct a fresh instance. |
| `pause()` / `resume()` before `init()` | `Err` — call `init()` first. |
| `pause()` while paused / `resume()` while running / `dispose()` after `dispose()` | `Ok(None)` — idempotent no-op. |
| `pause()` / `resume()` / `dispose()` listener throws | `Err` carrying the listener error; state lands on the `_ERROR` variant. |

In debug builds, assertions surface these contract violations early. In release the assertions are stripped but the `Err` return still distinguishes them from successful transitions — mission-critical callers should pattern-match the awaited result.

## Step 10: Working with `Option<T>` / `Result<T>` / `Resolvable<T>`

All public APIs return these sealed types from [df_safer_dart](https://pub.dev/packages/df_safer_dart). The recommended way to consume them is **Dart pattern matching** — `switch` / `if case` — rather than `.isSome()` + `.unwrap()` chains:

```dart
// Reading a registered dep
switch (DI.global.get<UserService>()) {
  case Some(value: final r):
    // r is Resolvable<UserService>
  case None():
    // not registered
}

// Awaited Result
switch (await DI.global.untilSuper<UserService>().toAsync().value) {
  case Ok(value: final svc):
    // use svc
  case Err(:final error):
    // log / surface error
}

// Type-narrowing pattern (avoids a separate `is T` runtime check)
final value = switch (resolvable) {
  Sync(value: Ok(value: final T v)) => v,
  _ => fallback,
};
```

The exhaustive `switch` rules out the "I forgot to handle Err" class of bugs at compile time and removes the need for `UNSAFE` markers in user code.

## Related Packages

`df_di` is one layer of a four-package state-management stack. The packages publish independently but are designed to work together; pick what you need:

| Package | Layer | What it gives you |
| --- | --- | --- |
| [df_safer_dart](https://pub.dev/packages/df_safer_dart) | foundation | `Option<T>`, `Result<T>`, `Resolvable<T>`, `Outcome<T>`, `UNSAFE { … }`, `SafeCompleter`, `TaskSequencer` — the sealed value types every other layer is built on. |
| **df_di** *(this)* | DI + services | Container hierarchy, `Service` / `ServiceMixin`, `StreamService`, `PollingStreamService`, ECS subsystem, `Plugin` system. |
| [df_pod](https://pub.dev/packages/df_pod) | reactive containers | `Pod<T>`, `ChildPod`, `ReducerPod`, `SharedPod` (persisted to `SharedPreferences`), `WeakChangeNotifier`, `PodBuilder` / `PodListBuilder` / `PodCollectionBuilder`. |
| [df_flutter_services](https://pub.dev/packages/df_flutter_services) | Flutter glue | `ObservedService`, `ObservedDataStreamService`, `HandleServiceLifecycleStateMixin` — bridges `df_di` services to `WidgetsBindingObserver` and exposes `pData: Pod<Option<Result<T>>>` so streams flow into widgets via `PodBuilder`. |

See [`doc/state_management_approach.md`](doc/state_management_approach.md) for the cross-package architecture and the recommended `G` (global-access) façade pattern.

<!-- END _README_CONTENT -->

---

🔍 For more information, refer to the [API reference](https://pub.dev/documentation/df_di/).

---

## 💬 Contributing and Discussions

This is an open-source project, and we warmly welcome contributions from everyone, regardless of experience level. Whether you're a seasoned developer or just starting out, contributing to this project is a fantastic way to learn, share your knowledge, and make a meaningful impact on the community.

### ☝️ Ways you can contribute

- **Find us on Discord:** Feel free to ask questions and engage with the community here: https://discord.gg/gEQ8y2nfyX.
- **Share your ideas:** Every perspective matters, and your ideas can spark innovation.
- **Help others:** Engage with other users by offering advice, solutions, or troubleshooting assistance.
- **Report bugs:** Help us identify and fix issues to make the project more robust.
- **Suggest improvements or new features:** Your ideas can help shape the future of the project.
- **Help clarify documentation:** Good documentation is key to accessibility. You can make it easier for others to get started by improving or expanding our documentation.
- **Write articles:** Share your knowledge by writing tutorials, guides, or blog posts about your experiences with the project. It's a great way to contribute and help others learn.

No matter how you choose to contribute, your involvement is greatly appreciated and valued!

### ☕ We drink a lot of coffee...

If you're enjoying this package and find it valuable, consider showing your appreciation with a small donation. Every bit helps in supporting future development. You can donate here: https://www.buymeacoffee.com/dev_cetera

<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="40"></a>

## LICENSE

This project is released under the [MIT License](https://raw.githubusercontent.com/dev-cetera/df_di/main/LICENSE). See [LICENSE](https://raw.githubusercontent.com/dev-cetera/df_di/main/LICENSE) for more information.
