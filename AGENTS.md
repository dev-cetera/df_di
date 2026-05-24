# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository scope

`df_di` is the **dependency injection + service-lifecycle layer** in a four-package Flutter state-management stack. The full stack lives next to this package in `/Users/robmllze/Projects/flutter/dev_cetera/df_packages/packages/`:

| Package | Path | Role |
| --- | --- | --- |
| `df_safer_dart` | `../df_safer_dart` | Foundation: `Option<T>`, `Result<T>`, `Resolvable<T>`, `Outcome<T>`, `UNSAFE`, `SafeCompleter`, `TaskSequencer` |
| `df_di` *(this)* | `.` | DI container hierarchy (`DI.root`/`global`/`session`/`user`), `Service`/`ServiceMixin`, `StreamServiceMixin`, `PollingStreamServiceMixin`, ECS subsystem (`World`/`Component`/`System`), plugin system |
| `df_pod` | `../df_pod` | Reactive containers (`Pod<T>`, `ChildPod`, `ReducerPod`, `SharedPod`), `WeakChangeNotifier`, `PodBuilder` and friends |
| `df_flutter_services` | `../df_flutter_services` | Flutter glue: `ObservedService`, `ObservedDataStreamService`, `HandleServiceLifecycleStateMixin` |

Auxiliary direct deps: `df_safer_dart_annotations` (`@unsafeOrError`, `@noFutures`, …), `df_safer_dart_lints` (the `custom_lint` plugin that enforces them), `df_log`, `df_type`, `df_debouncer`. `pubspec_overrides.yaml` pins these siblings to local paths so edits take effect without publishing.

Cross-stack architecture (how Pods live on services, how DI scopes hold them, how Flutter lifecycle integrates) lives in **`doc/state_management_approach.md`** — the same file is mirrored in every package of the stack; keep the copies in sync.

## Commands

Run from this package directory:

```sh
dart pub get
dart analyze                                # must be 0 issues
dart run custom_lint                        # must be 0 issues
dart test                                   # 485 tests; must all pass
dart test test/pass14_audit_test.dart       # single file
dart test --plain-name "untilSuper"         # match by test name
dart fix --apply                            # auto-fix trailing commas etc.
```

Workspace-wide PowerShell helpers live one level up at `@scripts/` (e.g. `pwsh ../../@scripts/fix_and_format_all.ps1`).

## Big-picture architecture

### What lives where

- `lib/src/di/` — `DI`, `DIBase`, `DIRegistry`, `Dependency`, `DependencyMetadata`, and the `Supports*` mixins. `_di_base.dart` is the largest file; the `_mixins/` directory layers feature mixins on top.
- `lib/src/services/` — `ServiceMixin` (lifecycle state machine), `StreamServiceMixin` (broadcast streams), `PollingStreamServiceMixin` (timer-driven). `Service` / `StreamService` / `PollingStreamService` are convenience base classes.
- `lib/src/entity/` — `Entity`, `TypeEntity`, `UniqueEntity`, reserved entities (`GlobalEntity`, `SessionEntity`, etc.).
- `lib/src/ecs/` — separate ECS subsystem built **on top of** `DIRegistry`: `World`, `Component`, `Resource`, `Event`, `System`, `Bundle`, `EcsPlugin`. Components live under their owning entity's group key; resources live under a reserved group. See `doc/ecs_example.md`.
- `lib/src/plugins/` — app-level `Plugin` API: each plugin owns a fresh child `DI` scope keyed by `plugin.id`. Distinct from `EcsPlugin` (which owns a `World`, not a DI scope).
- `lib/src/_callback_result.dart` — `awaitCallbackResult(...)` helper: detects `Future` / `Resolvable<T>` returns from user callbacks and routes failures correctly (sync-Err vs async-Err vs throws). Used at every `onRegister` / `onUnregister` site.
- `lib/src/_reserved_safe_completer.dart` — `ReservedSafeCompleter<T>` that captures `(v) => v is T` at construction site (closures preserve `T` reification under dart2js release minification, unlike `is Foo<T>` checks).
- `lib/_common.dart` — internal umbrella; every `src/**.dart` imports `'/_common.dart'`. Add new ambient imports here.

### Key invariants (read these before editing)

1. **Every lifecycle method** (`init` / `pause` / `resume` / `dispose`) routes through a per-service `TaskSequencer` — calls serialize, listeners chain via `Resolvable.then` preserving the sync fast-path.
2. **Invalid lifecycle transitions return `Err`, not silent `Ok`.** `init` after `dispose` → Err; `pause`/`resume` before `init` → Err; second `init` → Err. Idempotent calls (pause-when-paused, dispose-when-disposed) return `Ok(None)`. Mission-critical callers can check the result.
3. **`unregister<T>()` of a value that mixes `ServiceMixin` automatically cascades into `service.dispose()`** via the `ServiceMixin.unregister` static hook.
4. **`until*` waiters seed completers into the full ancestor chain** so a child waiter resolves when a parent registers. The `_seedCompleter` walks `_allAncestors().skip(1)`. Cleanup uses identity comparison so sibling waiters don't drop each other's completers.
5. **`_maybeFinish` iterates `children()` on every `register`** — `children()` filters to already-materialised lazies via `Lazy.currentInstance` (read-only probe), so an unrelated child is never force-constructed by a parent registration (C7 contract).
6. **`getDependency` / `isRegistered` carry a `visited: Set<DI>?`** for cycle detection in misconfigured parent graphs (`a.parents.add(b)` and vice versa).
7. **Concurrent registry iteration is snapshot-safe.** `children()`, `resolveAll`, and `unregisterAll` snapshot via `.toList(growable: false)` so a re-entrant register/unregister fired from a callback doesn't throw `ConcurrentModificationError`.
8. **ECS `update` is depth-tracked.** `_updateDepth` counts re-entrant calls; event buffers only clear at depth 0 so events sent before a re-entrant update remain visible to subsequent outer-tick systems.
9. **ECS events use subtype propagation.** `sendEvent` adds to a flat `_eventBuffer`; `readEvents<E>` and `onEvent<E>` filter via `event is E`. A derived event reaches base-typed listeners (Liskov).
10. **ECS `removeResource` / `despawn` / `clearEntities` / `dispose` cascade `dispose()`** on any value that mixes `ServiceMixin`, fire-and-forget (`.end()`).

### `until*` waiter family

- `untilSuper<T>` — the most common form. Resolves when any T (or subtype) is registered anywhere on the parent chain.
- `until<TSuper, TSub>` — same, with explicit subtype cast.
- `untilLazySuper<T>` / `untilLazy<TSuper, TSub>` — wait for a `Lazy<T>` registration.
- `untilExactlyK<T>(typeEntity)` / `untilSuperK<T>(typeEntity)` / `untilK<TSuper, TSub>(typeEntity)` — entity-keyed track; requires `enableUntilExactlyK: true` at registration time.
- `untilLazySingleton*` / `untilFactory*` — wait for the constructed singleton / factory function.

Use these instead of polling. They create a `ReservedSafeCompleter` that resolves the moment a matching registration occurs.

## Conventions (read before writing code)

- **Pattern matching first.** The audited convention is to use Dart `switch` / `if case` over `.unwrap()` chains. Example:
  ```dart
  // Preferred
  return switch (option) {
    Some(value: final v) => Some(transform(v)),
    None() => const None(),
  };

  // For typed inline checks, use the type-pattern directly:
  Sync(value: Ok(value: final T v)) => v,
  ```
  Passes 14 / 14b refactored the codebase to this style; UNSAFE blocks dropped from 37 → 13 and probe-then-unwrap calls dropped from 114 → 11.
- **Errors propagate as values, not throws.** Functions returning `Result<X>` / `Resolvable<X>` return `Err`-on-failure. Throws are only used *inside* `Async()` / `Sync()` constructor bodies (where df_safer_dart absorbs them into the value channel). Do not throw out of public APIs that return a Result type.
- **`UNSAFE:` is a marker for the lint, not a safety net.** It's only correct in two places: (a) `*Unsafe` methods whose contract documents they throw, and (b) inside a `Resolvable(() => …)` factory whose outer absorption is what actually makes the throw safe. The post-14 codebase has 13 such sites; do not add new ones casually.
- **`register*()` returns `Resolvable<T>`.** Caller can pattern-match or chain. Duplicate registration returns `Sync.err(...)` instead of throwing.
- **Assertions are dev warnings, Err is the prod contract.** Lifecycle methods assert misuse in debug AND return Err in release. If your test exercises misuse, swallow `AssertionError` with try/catch — see `test/pass6_audit_test.dart::spawn after dispose` for the pattern.
- **Use `awaitCallbackResult(...)`** for any `onRegister` / `onUnregister` invocation site so `Future` / `Sync.err` / `Async.err` returns all route correctly.
- Imports use the `'/_common.dart'` relative shortcut; `prefer_relative_imports` is enforced.
- Every Dart file starts with the `▓▓▓` license banner — preserve when editing.
- `analysis_options.yaml` enables `strict-casts`, `strict-inference`, `strict-raw-types`; many normally-warning lints are upgraded to errors. `formatter.trailing_commas: preserve`. The `custom_lint` plugin runs `df_safer_dart_lints` rules.
- **Don't hand-edit `*.g.dart`** — `_src.g.dart` / `_mixins.g.dart` are indexes produced by `df_generate_dart_indexes`.

## Tests

`test/*_test.dart` — 485 tests covering containers, hierarchies, services, streams, polling, ECS, plus a large reliability regression suite. Notable files:

- `abuse_test.dart`, `adversarial_test.dart`, `callback_propagation_abuse_test.dart` — adversarial cases.
- `until_super_regression_test.dart`, `until_abuse_test.dart`, `until_exactly_k_test.dart` — `until*` race regressions.
- `pass3_audit_test.dart` … `pass14b_audit_test.dart`, `pass14_ecs_test.dart` — 14 audit passes, each demonstrating a bug that was found and fixed.
- `mission_critical_e2e_test.dart` — full boot → crash recovery → repeated open/close cycles.
- `service_lifecycle_test.dart` — full state-machine coverage.

```bash
dart test                                  # all
dart test test/pass14_audit_test.dart      # single file
dart test --plain-name "untilSuper"        # match name
```

## When investigating bugs

1. Read the relevant `pass*_audit_test.dart` files — they document the exact failure modes that were already found and fixed.
2. Reproduce with a minimal failing test BEFORE editing source.
3. The `Sync(value: Ok(value: final T v))` pattern is the canonical way to extract a known-good payload — search for it to see how existing code handles each case structurally.
4. If you find a new bug, follow the convention: write a failing test → fix → confirm test passes + no analyzer/lint regressions.

## What NOT to do

- Don't reintroduce `.unwrap()` chains where pattern matching works. The audit explicitly removed them.
- Don't add `UNSAFE:` labels to make a lint go away — restructure the code so the unwrap isn't needed.
- Don't throw out of methods that return `Result` / `Resolvable`. Return `Err` / `Sync.err` instead.
- Don't bypass the `TaskSequencer` for lifecycle methods — concurrent `init`/`dispose` race otherwise.
- Don't call `registry.removeGroup` / `registry.clear` from ECS code without going through `_cascadeDisposeGroup` first — `ServiceMixin` resources/components would leak.
- Don't compare two `Dependency` instances by identity — equality is hash-based by design (see `_dependency.dart::==`).
- Don't register async-constructed children. `registerChild` registers a Sync lazy; `unregisterChild` asserts the unregister Resolvable is Sync.
