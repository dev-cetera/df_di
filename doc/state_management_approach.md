# State Management with `df_safer_dart` + `df_di` + `df_pod` + `df_flutter_services`

> This file is identical in every package's `doc/state_management_approach.md` — `df_safer_dart`, `df_di`, `df_pod`, `df_flutter_services`. The four packages are designed as one stack and share one architectural narrative; keep the copies in sync when editing.

Four packages cooperate to give Flutter apps a strict, lifecycle-aware, reactive state model:

| Package | Layer | Provides |
| --- | --- | --- |
| `df_safer_dart` | foundation | `Option<T>`, `Result<T>`, `Resolvable<T>`, `Outcome<T>`, `UNSAFE { ... }`, `Sync` / `Async`, `consec`, `Unit`, `SafeCompleter`, `TaskSequencer` |
| `df_pod` | reactive containers | `Pod<T>` (a.k.a. `RootPod<T>`), `ChildPod`, `ReducerPod`, `SharedPod`, `WeakChangeNotifier`, `PodBuilder`, `PodListBuilder`, `PodCollectionBuilder`, `PollingPodBuilder` |
| `df_di` | services + DI | `DI` (hierarchical container), `Service` / `ServiceMixin`, `ServiceState`, `StreamService` / `StreamServiceMixin`, `PollingStreamService`, `Entity` / `TypeEntity`, `World` / `Component` (ECS subsystem) |
| `df_flutter_services` | glue + Flutter lifecycle | `ObservedService`, `ObservedStreamService`, `ObservedDataStreamService`, `ObservedPollingStreamService`, `HandleServiceLifecycleStateMixin`, `ObservedDataStreamServiceMixin` |

The packages publish independently; their `^` constraints stay in lockstep (workspace majors today: safer 0.20, di 0.16, pod 0.20, flutter_services 0.2).

---

## 1. Mental model

State in this stack is **owned by long-lived services held in DI containers**. UI never holds state — it subscribes to `Pod<T>` instances that services expose as fields. Errors and absence travel through `Option<Result<T>>`; sync vs. async travel through `Resolvable<T>`. A service's whole life (`init` → `pause` ↔ `resume` → `dispose`) is sequenced so concurrent calls can't interleave their listeners.

```
                          ┌──────────────────────┐
                          │ UI widgets            │
                          │   PodBuilder etc.     │
                          └──────────┬───────────┘
                                     │ listens
                                     ▼
                          ┌──────────────────────┐
                          │ Pod<T> fields on      │
                          │ services (pData, …)   │
                          └──────────┬───────────┘
                                     │ updated by
                                     ▼
                          ┌──────────────────────┐
                          │ ServiceMixin /         │
                          │ StreamServiceMixin /   │
                          │ ObservedService ...    │
                          └──────────┬───────────┘
                                     │ resolved through
                                     ▼
                          ┌──────────────────────┐
                          │ DI (root → global →   │
                          │  session → user …)    │
                          └──────────┬───────────┘
                                     │ values flow as
                                     ▼
                          ┌──────────────────────┐
                          │ Option / Result /     │
                          │ Resolvable<T>         │
                          └──────────────────────┘
```

Three rules to internalize before reading the rest:

1. **The Pod is on the service.** Widgets reach the Pod through DI (or a thin `G` accessor), not through globals.
2. **No raw `Future`** in business code. Use `Resolvable<T>`. Internal Dart APIs that return `Future` are wrapped at the boundary.
3. **`UNSAFE { … }` is a marker, not a safety net.** It just tells the linter you accepted the throw. The contract is "errors are values" via `Result`.

---

## 2. `df_safer_dart` — the value types

### 2.1 `Option<T> = Some<T> | None<T>`

Absence as data.

```dart
Option<User> findUser(String id) {
  final hit = cache[id];
  return hit == null ? const None() : Some(hit);
}

// Consumption — no null checks
final name = findUser('42').map((u) => u.name).unwrapOr('anonymous');
```

`const None()` infers as `None<Never>`, so if you compare it against a typed `None<T>` with `==` you'll get `false`. Use `.isNone()` or supply the type (`const None<User>()`).

### 2.2 `Result<T> = Ok<T> | Err<T>`

Fallibility as data. `Err` implements `Exception` and carries an optional `stackTrace`, `statusCode`, and `breadcrumbs` (labels of the pipeline step(s) that produced the error).

```dart
Result<int> parseAge(String s) {
  final n = int.tryParse(s);
  return n == null ? Err('not a number') : Ok(n);
}

parseAge('twelve').fold(
  ifOk: (n)  => print('age=$n'),
  ifErr: (e) => Log.err(e),
);
```

`Ok.map<R>` / `Ok.flatMap<R>` / `Ok.mapOk` return `Result<R>` (not `Ok<R>`) — a callback that throws is absorbed into an `Err` with the original stack rather than escaping. Tag each step with `.named('label')` on any `Result`/`Sync`/`Async`/`Resolvable` to populate `Err.breadcrumbs` for first-failure attribution.

### 2.3 `Resolvable<T> = Sync<T> | Async<T>`

Sync/async unified. **Both wrap `Result<T>`**, so you always know whether the value is ready and whether it succeeded.

```dart
Resolvable<int> doubled(int n) => Sync.okValue(n * 2);

Resolvable<User> fetchUser(String id) =>
  Async(() async => Ok(await api.getUser(id)));

// `.then` keeps the sync fast-path when both halves are Sync
final r = doubled(21).then((x) => fetchUser('u$x'));
```

`Resolvable.value` is `FutureOr<Result<T>>` — `await`-able when async, immediate when sync. `combineResolvable` joins a heterogeneous list into a single `Resolvable<List<...>>`.

### 2.4 `UNSAFE { ... }` and `@unsafeOrError`

`unwrap()`, `Some.value`, `Ok.value` and a few helpers throw on `None` / `Err`. They are tagged `@unsafeOrError`. The `df_safer_dart_lints` plugin requires every call site be either:

```dart
final v = UNSAFE(() => maybeUser.unwrap());

// or use a labeled statement (one statement scope):
UNSAFE:
final v = maybeUser.unwrap();
```

Both forms are recognized by the linter; pick whichever reads better. The `UNSAFE` function rethrows — it adds no runtime protection.

### 2.5 Concurrency primitives

- `SafeCompleter<T>` — resolve-once completer where `isCompleted` flips **as soon as resolve is accepted** (not when the future settles). Used internally by `DI.until*` waiters.
- `TaskSequencer` — iterative queue draining (no stack overflow at 200k reentrant tasks). The lifecycle ordering inside every service is enforced by one of these.

---

## 3. `df_pod` — reactive containers

### 3.1 The Pod hierarchy

```
WeakChangeNotifier (mixin)
   ↓
DisposablePod<T> (extends WeakChangeNotifier, implements ValueListenable<T>)
   ↓
PodNotifier<T>
   ↓
RootPod<T>            ← Pod<T> is a typedef for RootPod<T>
   with GenericPodMixin<T>     →  ChildPod<TParent, TChild>   (from .map)
                                  ReducerPod<T>                (from .reduce)
                                  SharedPod<A, B>              (mirrored to SharedPreferences)
                                  SharedBoolPod / SharedIntPod / SharedStringPod /
                                  SharedStringListPod / SharedDoublePod /
                                  SharedEnumPod / SharedJsonPod
                                  ProtectedPod / SharedProtectedPod
```

```dart
final pCounter = Pod(0);
pCounter.set(1);
pCounter.update((x) => x + 1);
final value = pCounter.getValue();

// Derived
final pDoubled = pCounter.map((x) => x * 2);             // ChildPod<int, int>
final pStatus  = pCounter.map((x) => x.isEven ? 'even' : 'odd');

// Combined
final pPair = ReducerPod<(int, String)>(
  responder: () => [Some(pCounter), Some(pStatus)],
  reducer:   (vals) => Some((vals[0].unwrap() as int, vals[1].unwrap() as String)),
);
```

### 3.2 `WeakChangeNotifier`

Listeners are held by `WeakReference`. When a widget is unmounted, its listener is GC'd without manual `removeListener`. The escape hatch for non-UI listeners is `addStrongRefListener` — and the caller **must** hold the listener in a stable strong-ref (field, top-level variable, or pinned local), otherwise it is GC'd immediately and never fires.

```dart
class _SyncBridge {
  final Pod<int> source;
  final void Function(int) onChanged;
  _SyncBridge(this.source, this.onChanged) {
    source.addStrongRefListener(strongRefListener: _onTick);
  }
  void _onTick() => onChanged(source.getValue());
  // _onTick is a tear-off of an instance method → strong-ref-stable.
}
```

Anonymous closures passed to `addStrongRefListener` are a common bug (silently dead listener). The aggressive test suite in `df_pod` proves this is real.

### 3.3 Builders

`PodBuilder`, `PodListBuilder`, `PodCollectionBuilder`, `PollingPodBuilder`. Each accepts either a plain `Pod` or a `Resolvable<Pod>` for late-bound pods (e.g., a pod that lives inside a service that may not be registered yet).

For an async data pod typed `Pod<Option<Result<T>>>`, the snapshot returned to your builder is also `Option<Result<T>>`:

```dart
PodBuilder<User>(
  pod: g.pCurrentUser,    // Resolvable<Pod<Option<Result<User>>>>
  builder: (context, snapshot) {
    return snapshot.value.fold(
      ifNone: () => const CircularProgressIndicator(),   // pending
      ifSome: (result) => result.fold(
        ifOk:  (user) => Text(user.name),
        ifErr: (err)  => Text('error: $err'),
      ),
    );
  },
);
```

`snapshot.value.reduce()` is a shortcut that hands you a single value or a fallback — useful when you don't need to distinguish "loading" from "errored".

---

## 4. `df_di` — DI container + services

### 4.1 Static scopes

```dart
final class DI {
  static final root    = DI();
  static DI get global  => root.child(groupEntity: const GlobalEntity());
  static DI get session => global.child(groupEntity: const SessionEntity());
  static DI get user    => session.child(groupEntity: const UserEntity());
  // also: theme, dev, prod, test
}
```

`DI.global` is for app-lifetime dependencies. `DI.session` is for the logged-in lifetime — destroy and recreate it on logout/login. The hierarchy means `DI.session.untilSuper<RouteController>()` walks upward to find a `RouteController` registered in `DI.global`.

### 4.2 Registration

```dart
DI.global
  ..register(firebaseAuth)                          // bare instance
  ..register<WordPressApiManager>(wordPressApiManager)
  ..registerAndInitService(RemoteConfigService())   // service: also calls init()
  .unwrap();
```

Key APIs:

| API | What it does |
| --- | --- |
| `register<T>(value)` | Store `value` keyed by `TypeEntity(T)` |
| `registerAndInitService<T>(service)` | Register and run `service.init()` |
| `unregister<T>()` | Look up and drop; for `ServiceMixin` values, `dispose()` runs automatically |
| `unregisterAll(...)` | Drop every dependency in the container (used for logout) |
| `getSync<T>()` / `getSyncOrNone<T>()` | Resolve synchronously |
| `untilSuper<T>()` | `Resolvable<T>` that completes as soon as a `T` is registered anywhere on the parent chain |
| `untilLazySuper<T>()` | Same, but waits for a lazy registration |
| `untilExactlyK<T>(entity)` / `untilFactorySuper<T>()` | Match a specific entity or factory registration |

The `until*` family is the **safe way to express "I need service X before I do Y"** without race conditions. It completes the moment registration occurs, whether before or after the call.

### 4.3 `ServiceMixin` and lifecycle

Every service has the same shape:

```dart
final class MyService extends Service {  // or `with ServiceMixin` on an existing class
  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
    (_) => Async(() async { /* do init work */ return Unit(); }),
  ];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
    (_) => Async(() async { /* clean up */ return Unit(); }),
  ];

  // For services that DON'T need pause/resume, return const []:
  @override
  TServiceResolvables<Unit> providePauseListeners(void _) => const [];
  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) => const [];
}
```

> **Gotcha:** `providePauseListeners` and `provideResumeListeners` are abstract — returning `throw UnimplementedError()` (the IDE default) makes the app crash any time a parent calls `pause()`. Return `const []` instead.

Lifecycle states (`ServiceState`): `NOT_INITIALIZED` → `RUN_ATTEMPT` → `RUN_SUCCESS` / `RUN_ERROR`; `PAUSE_*`; `RESUME_*`; `DISPOSE_*`. The transitions are sequenced through a `TaskSequencer`, so two concurrent `init()` calls won't double-run listeners. `didEverInitAndSuccessfully` stays `true` after a later error or dispose, useful for "did this service ever come up?" guards.

### 4.4 `StreamServiceMixin` — managed broadcast streams

```dart
abstract class StreamService<TData extends Object> with ServiceMixin, StreamServiceMixin<TData> {}
```

Subclass override: `provideInputStream() → Stream<Result<TData>>`. The mixin wires it through a broadcast controller, manages the subscription, and forwards every event through a per-service `_pushSequencer` so listeners across emissions run in arrival order. `restartStream()` increments an internal epoch — in-flight pushes captured against the old epoch are dropped instead of landing in the new controller.

`initialData` is an `Option<Resolvable<TData>>` that resolves with the first emission (or with an `Err` if the stream stops before any data arrives — so awaiters don't hang forever).

### 4.5 `PollingStreamServiceMixin`

Drives `provideInputStream()` from a timer at `providePollingInterval()`. Auto-pauses on subscription pause; auto-resumes when the subscription resumes. Plug it into `ObservedPollingStreamService` and the Flutter lifecycle will pause polling whenever the app is backgrounded.

---

## 5. `df_flutter_services` — bridges to Flutter

### 5.1 `ObservedService`

`Service` + `WidgetsBindingObserver`. The observer is registered in init listeners (not in the constructor) and removed in dispose listeners — so constructing a service before `WidgetsFlutterBinding.ensureInitialized()` is fine, and a failed `init` won't leak a global observer.

```dart
final class MyService extends ObservedService {
  @override
  bool handlePausedState()  => true;     // pause() the service on AppLifecycleState.paused
  @override
  bool handleResumedState() => true;     // resume() it on .resumed

  @override
  TServiceResolvables<Unit> providePauseListeners(void _)  => const [];
  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) => const [];
}
```

`handleHiddenState`, `handleInactiveState`, `handleDetachedState` are also opt-in. Detached calls `dispose()` (terminal).

### 5.2 `ObservedDataStreamService<T>`

The most common subclass. Combines `StreamServiceMixin`, `HandleServiceLifecycleStateMixin`, and `ObservedDataStreamServiceMixin`, which exposes:

```dart
final RootPod<Option<Result<TData>>> pData = Pod(const None());
```

`pData` mirrors the latest emission and is **cleared back to `None` — not disposed — on dispose**. That lets consumers cache the reference across re-init cycles (e.g., relogin) without dangling pointers.

```dart
final class UserService extends ObservedDataStreamService<ModelUser> {
  UserService({required this.userId});
  final String userId;

  @override
  Stream<Result<ModelUser>> provideInputStream() async* {
    final db = await DI.session.untilSuper<DatabaseService>().toAsync().unwrap();
    yield* db.streamModel(Schema.usersRef(userId: userId), ModelUser.fromJson);
  }
}
```

### 5.3 `HandleServiceLifecycleStateMixin`

Five opt-in hooks (`handlePausedState` … `handleDetachedState`) map `AppLifecycleState` to `pause()` / `resume()` / `dispose()`. Errors from the consec'd calls go to `Log.err` and trigger a debug-only `assert(false, ...)` so dev builds notice immediately.

---

## 6. Real-world pattern: the `G` singleton

Apps in this stack expose state through a tiny `G` (for "global access") façade — never raw `DI.session.untilSuper<...>()` calls scattered across widgets.

```dart
G get g => G.instance;

final class G {
  const G._();
  static const instance = G._();

  /// Reactive accessor: returns a Resolvable<Pod<...>> for use with builders.
  Resolvable<Pod<Option<Result<ModelUser>>>> get pCurrentUser =>
      DI.session.untilSuper<UserService>().map((s) => s.pData);

  /// Snapshot: synchronously read the current value, if available.
  Option<Result<ModelUser>> get currentUserSnapshot =>
      DI.session.getSyncOrNone<UserService>()
          .map((s) => s.pData.getValue())
          .flatten();
}
```

In widgets:

```dart
PodBuilder<ModelUser>(
  pod: g.pCurrentUser,
  builder: (context, snap) => snap.value.reduce<Widget>(
    ifNone:  () => const CircularProgressIndicator(),
    ifSomeOk: (user) => Text(user.name),
    ifSomeErr: (err) => Text('error: $err'),
  ),
);
```

---

## 7. Session lifecycle (login / logout)

The pattern used by `hup-app`, `heylang`, and `jobxcel`:

```dart
// In DI.global — created once at app start.
final class LoginLogoutControlService extends SessionControlService {
  @override
  Future<void> onLogin(ModelAuthUser authUser) async {
    if (!DI.global.isRegistered<SessionService>()) {
      await DI.global.registerAndInitService(SessionService()).unwrap();
    }
    final router = await DI.global.untilSuper<RouteController>().unwrap();
    router.push(HomeScreenRouteState());
  }

  @override
  Future<void> onLogout() async {
    if (DI.global.isRegistered<SessionService>()) {
      DI.global.unregister<SessionService>().unwrap();   // cascades into SessionService.dispose()
    }
    final router = await DI.global.untilSuper<RouteController>().unwrap();
    router.resetState();
    router.push(WelcomeScreenRouteState());
  }
}

// SessionService owns the DI.session subtree.
final class SessionService extends Service {
  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
    (_) => Async(() async {
      // Defensive: previous session must have cleaned up.
      // ignore: invalid_use_of_protected_member
      final reg = DI.session.registry;
      if (reg.state.isNotEmpty) {
        Log.err('previous session leaked — clearing');
        reg.clear();
      }

      // Phase 1: fast/sync services first.
      unawaited(_asyncExec('register UserService', () =>
          DI.session.registerAndInitService(UserService(userId: g.userId)).unwrap()));

      // Phase 2: services that depend on Phase 1 — use untilSuper to wait.
      unawaited(_asyncExec('register UserSessionService', () async {
        await DI.session.untilSuper<UserService>().toAsync().unwrap();
        await DI.session.registerAndInitService(UserSessionService()).unwrap();
      }));

      return Unit();
    }),
  ];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
    (_) => Async(() async {
      DI.session.unregisterAll(
        onAfterUnregister: (v) { Log.stop('unregistered $v'); return null; },
      ).unwrap();
      return Unit();
    }),
  ];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _)  => const [];
  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) => const [];
}
```

Phasing services with `unawaited(...)` and `untilSuper` is intentional: it avoids serialising the whole login behind a single `await` chain, while still expressing the dependency order. Errors inside each phase get caught locally so one slow service doesn't block the rest of the session from coming up.

---

## 8. UI patterns

### 8.1 Single pod

```dart
PodBuilder(
  pod: permissionService.pLocationWhenInUseStatus,
  builder: (context, snap) {
    final status = snap.value;          // PermissionStatus
    return Text('Location: ${status.name}');
  },
);
```

### 8.2 Async pod with `Option<Result<T>>`

```dart
PodBuilder<User>(
  pod: g.pCurrentUser,
  builder: (context, snap) => snap.value.fold(
    ifNone:  () => const CircularProgressIndicator(),
    ifSome:  (r) => r.fold(
      ifOk:  (u) => Text(u.name),
      ifErr: (e) => Text('$e'),
    ),
  ),
);
```

### 8.3 Multi-pod (`PodListBuilder`)

Rebuilds when **any** of the listed pods fires:

```dart
PodListBuilder(
  pods: [c.pIsSearching, queryController],
  builder: (context, _) => SearchBar(
    isSearching: c.pIsSearching.getValue(),
    query:       queryController.text,
  ),
);
```

### 8.4 Dynamic inner list (`PodCollectionBuilder`)

When the *list* of pods comes from another pod (e.g., one pod per message in a chat that grows over time). Auto-attaches/detaches as the inner list mutates by identity:

```dart
PodCollectionBuilder<List<Pod<Message>>>(
  source: c.pMessagePods,
  selector: (messagePodList) => messagePodList,
  builder: (context, _) => ListView(
    children: c.pMessagePods.getValue().map(MessageTile.new).toList(),
  ),
);
```

### 8.5 Debounce & cache

`PodBuilder(... debounceDuration: ..., cacheDuration: ..., key: ValueKey('...'))` — the cache key is required if you want `cacheDuration` to mean anything.

---

## 9. Common pitfalls

1. **`throw UnimplementedError()` in `providePauseListeners` / `provideResumeListeners`.** Return `const []` for services that don't need pause/resume; otherwise the app crashes the moment Flutter (or a parent) calls `pause()`.
2. **`const None()` and equality.** `const None() == const None<Result<int>>()` is `false`. Use `.isNone()` to check, or annotate the literal: `const None<Result<int>>()`.
3. **Anonymous closure to `addStrongRefListener`.** The listener gets GC'd immediately. Hold it in a field or instance-method tear-off.
4. **Manually calling `WidgetsBinding.instance.removeObserver(this)` in a custom `provideDisposeListeners` of an `ObservedService`.** The parent already does this. Either call `super.provideDisposeListeners(null)` and prepend/append, or — if you must override — leave the observer cleanup out (it'll double-remove and the second call is a no-op, but is misleading).
5. **Constructing an `ObservedService` before `WidgetsFlutterBinding.ensureInitialized()`** used to throw. Current behaviour: safe, because the observer is registered in init listeners. If you see code adding the observer in the constructor, it's pre-0.2 and should be migrated.
6. **Using `await` in a chain of `untilSuper` calls during session init.** That serialises the whole login. Prefer `unawaited(asyncExec(...))` per service plus `untilSuper<>().toAsync().unwrap()` inside dependents.
7. **Mixing `Pod<T>` and `Pod<Option<Result<T>>>` in a single accessor.** The async/data variants always wrap; the simple variants don't. Be consistent inside `G` so callers can rely on a single unwrap pattern.
8. **Calling `pData.dispose()` from a custom `provideDisposeListeners`.** `pData` is meant to survive dispose→init cycles. The parent mixin clears it to `None` instead. Disposing it breaks reconnection on relogin.

---

## 10. Migration notes (workspace majors → published)

This guide reflects the workspace majors: `df_safer_dart 0.20`, `df_di 0.16`, `df_pod 0.20`, `df_flutter_services 0.2`, with `df_log 0.5`, `df_type 0.15`, `df_safer_dart_annotations 0.3`, `df_safer_dart_lints 0.5`.

Renames and behaviour changes that older code may still reference:

- **`DataStreamService` → `ObservedDataStreamService`.** The base type with `pData` is in `df_flutter_services`, not `df_di`. (`StreamService` without the Pod still lives in `df_di`.)
- **`ObservedService` observer registration** moved from constructor into init listeners — no public API change, but custom subclasses that called `addObserver(this)` in their constructor should remove that call.
- **`SafeCompleter.isCompleted`** now flips `true` the instant a resolve is accepted, not when the future settles. Code that relied on `!isCompleted` to detect "in-flight" must check a different signal.
- **`Outcome.end()` now returns `void`** (was `FutureOr<void>`, with `Async.end()` returning `Future<void>`). `Async.end()` detaches its cleanup via `unawaited(...)`. Code that `await`ed `.end()` should switch to `await x.value` if it really needed the value.
- **`Ok.map<R>` / `Ok.flatMap<R>` / `Ok.mapOk`** return `Result<R>` (was `Ok<R>`). A throwing callback becomes an `Err` instead of escaping. Annotate callsites as `Result<R>` instead of `Ok<R>`.

For the audit that produced the current majors and what changed inside `df_safer_dart`, see `packages/df_safer_dart/CLAUDE.md` (hardening sweep).

---

## 11. Quick reference

| Task | Use |
| --- | --- |
| Hold app-wide state | `DI.global.register*()` |
| Hold logged-in-user state | `DI.session.register*()`; destroy + recreate on login |
| Reactive value | `Pod<T>` on the service |
| Async fetched value | `ObservedDataStreamService<T>` → `pData : Pod<Option<Result<T>>>` |
| Polled value | `ObservedPollingStreamService<T>` |
| Wait for a dependency | `di.untilSuper<T>()` (resolves whenever it appears) |
| Derived state | `pBase.map(...)` or `ReducerPod(...)` |
| UI subscription | `PodBuilder` / `PodListBuilder` / `PodCollectionBuilder` |
| Errors as values | `Result<T>` returned from anything fallible |
| Sync/async unified | `Resolvable<T>` |
| Persisted value | `SharedPod` / `SharedBoolPod` / `SharedJsonPod` / … |
| Pause polling/streams when backgrounded | extend `ObservedStreamService` and override `handlePausedState() => true` |
| Logout cleanup | `DI.global.unregister<SessionService>()` — cascades through `unregisterAll` inside the session |

If you can map your problem to a row above without writing custom plumbing, you're using the stack the way it was designed.
