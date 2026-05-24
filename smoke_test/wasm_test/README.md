# df_di wasm/dart2js harness

A small Flutter Web app that exercises the `until` / `untilSuper` /
`untilExactlyK` paths on dart2js **and** dart2wasm release builds, in a
browser, with PASS/FAIL printed on screen.

The point: the VM-target `dart test` suite already covers the contract, but
generic-parameter reification differs between the VM, dart2js release, and
dart2wasm release. That difference is what surfaced the original
`untilSuper` hang on dart2js — see `df_di-REVIEW.md`. This harness keeps a
runnable regression in the actual release pipelines so future changes can be
verified end-to-end.

## What it covers

- `untilSuper<T>()` resolves on later register.
- `untilSuper<X>()` is **not** completed when `Y` is registered (the
  dart2js cross-fire regression).
- `untilSuper<Animal>()` resolves when a `Cat` subtype is registered.
- `until<Animal, Cat>()`.
- `untilExactlyK<T>(TypeEntity(T))` on exact-typeEntity match.
- `untilExactlyK` registration-epoch guard: register → unregister →
  re-register, the waiter ends up with the fresh value, not a stale one.

## Run

```bash
cd packages/df_di/smoke_test/wasm_test

# Debug (VM-like generics)
flutter run -d chrome

# dart2js release
flutter build web
# then serve build/web with any static server

# dart2wasm release
flutter build web --wasm
# then serve build/web with any static server
```

A green status bar means every scenario passed on the active compiler. A red
bar shows the first scenario that broke and the captured error/stack.
