# Changelog

## 0.16.0

- breaking: `ServiceMixin.init` / `pause` / `resume` return `Err` on invalid lifecycle transitions (`init` after `dispose`, second `init`, `pause` / `resume` before `init`) instead of silently resolving Ok. Idempotent calls (pause-when-paused, resume-when-resumed, dispose-when-disposed) still return `Ok(None)`.
- breaking: ECS events use subtype propagation — `readEvents<E>` and `World.onEvent<E>` now match via `event is E`, so a derived event reaches base-typed readers. Previously buffers and listener maps were keyed by exact runtime type and base-typed readers saw nothing.
- feat: ECS `despawn`, `clearEntities`, `removeResource`, and `World.dispose` cascade `dispose()` (fire-and-forget) to component / resource values that mix `ServiceMixin`, so subscriptions and timers no longer leak past the world's lifetime.
- feat: ECS `update` is re-entrant safe — a system calling `world.update` recursively shares the outer tick's event buffer; only the outermost return drains it.
- fix: `register<T>`, `until*`, and `untilExactlyK` return an `Err` `Resolvable` instead of throwing when a concurrent unregister wipes the slot between resolution and the post-resolution lookup.
- fix: `registerAndInitService` now fires the user-supplied `onUnregister` callback even when the service's `dispose()` resolves to `Err` or the registered slot resolved to `Err`.
- fix: `unregisterChild` / `unregisterChildT` propagate child-construction failure as `Err` in the returned `Result` instead of throwing.
- fix: `DIRegistry.removeWhere` now prunes empty groups and fires the change listener — previously it leaked ghost group keys and skipped change notifications.
- fix: `children()` and `resolveAll` snapshot the registry so re-entrant register / unregister fired from an `onRegister` / `onUnregister` callback no longer throws `ConcurrentModificationError`.
