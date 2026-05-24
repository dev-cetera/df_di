# CLAUDE.md — df_di

Working notes for AI agents collaborating on this package.

## Role in the state-management stack

`df_di` is the **dependency injection + service-lifecycle layer** in a four-package Flutter state-management stack. The full stack lives next to this package in `/Users/robmllze/Projects/flutter/dev_cetera/df_packages/packages/`:

| Package | Path | Role |
| --- | --- | --- |
| `df_safer_dart` | `../df_safer_dart` | Foundation: `Option<T>`, `Result<T>`, `Resolvable<T>`, `Outcome<T>`, `UNSAFE`, `SafeCompleter`, `TaskSequencer` |
| `df_di` *(this)* | `.` | DI container hierarchy (`DI.root`/`global`/`session`/`user`), `Service`/`ServiceMixin`, `StreamServiceMixin`, `PollingStreamServiceMixin`, ECS subsystem (`World`/`Component`/`System`) |
| `df_pod` | `../df_pod` | Reactive containers (`Pod<T>`, `ChildPod`, `ReducerPod`, `SharedPod`), `WeakChangeNotifier`, `PodBuilder` and friends |
| `df_flutter_services` | `../df_flutter_services` | Glue + Flutter app-lifecycle: `ObservedService`, `ObservedDataStreamService`, `HandleServiceLifecycleStateMixin` |

Auxiliary packages this package depends on:
- `df_safer_dart_annotations` (`../df_safer_dart_annotations`) — `@unsafeOrError`, `@noFutures`, etc.
- `df_safer_dart_lints` (`../df_safer_dart_lints`) — `custom_lint` plugin enforcing them
- `df_log` (`../df_log`), `df_type` (`../df_type`), `df_debouncer` (`../df_debouncer`) — utilities

`pubspec_overrides.yaml` pins these siblings to local paths. Edits to siblings take effect without publishing.

## State-management guide

For the cross-package architecture (how Pods live on services, how DI scopes hold them, how Flutter lifecycle integrates) read **`doc/state_management_approach.md`**. The same file is mirrored in every package of the stack (`df_safer_dart`, `df_di`, `df_pod`, `df_flutter_services`) — keep the copies in sync when editing.

## What lives in this package

- `lib/src/di/` — `DI`, `DIBase`, `DIRegistry`, `Dependency`, `DependencyMetadata`, the `SupportsXxx` mixins, the `until*` waiter family.
- `lib/src/services/` — `ServiceMixin` (lifecycle state machine), `StreamServiceMixin` (broadcast streams), `PollingStreamServiceMixin` (timer-driven).
- `lib/src/entity/` — `Entity`, `TypeEntity`, `UniqueEntity`, reserved entities (`GlobalEntity`, `SessionEntity`, etc.).
- `lib/src/ecs/` — separate ECS subsystem (`World`, `Component`, `Resource`, `Event`, `System`, `Plugin`). Independent of the rest; used when you want entity-component-system semantics on top of the DI registry. See `doc/ecs_example.md`.

## Conventions specific to df_di

- Every lifecycle method (`init`, `pause`, `resume`, `dispose`) routes through a per-service `TaskSequencer` — calls serialize, listeners chain via `Resolvable.then` preserving the sync fast-path.
- `until*` (`untilSuper`, `untilLazySuper`, `untilExactlyK`, `untilFactorySuper`) creates a `ReservedSafeCompleter` that resolves the moment a matching registration occurs. Use these instead of polling.
- `register*()` returns `Result<Resolvable<T>>`. Unwrap with `.unwrap()` only inside `UNSAFE { ... }` or after an explicit `isOk()` check.
- `unregister<T>()` of a value that mixes `ServiceMixin` cascades into `service.dispose()` automatically (`ServiceMixin.unregister` static hook).
- The `UNSAFE:` label form is recognized by `df_safer_dart_lints` as equivalent to wrapping the statement in `UNSAFE(() => ...)` — used heavily here for terseness inside `_di_base.dart`.

## Tests

`test/*_test.dart` — 310 tests covering containers, hierarchies, services, streams, polling, ECS, plus a large abuse/adversarial/until-race regression suite (`abuse_test.dart`, `until_abuse_test.dart`, `until_super_regression_test.dart`).

```bash
dart test                                # all
dart test test/service_lifecycle_test.dart
dart test --plain-name "untilSuper"
```