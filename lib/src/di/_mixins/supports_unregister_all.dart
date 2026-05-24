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
import '../../_callback_result.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A mixin that provides a method to unregister all dependencies.
base mixin SupportsUnregisterAll on DIBase {
  /// Unregisters all dependencies, optionally with callbacks and conditions.
  Resolvable<Unit> unregisterAll({
    Option<TOnUnregisterCallback<Dependency>> onBeforeUnregister = const None(),
    Option<TOnUnregisterCallback<Dependency>> onAfterUnregister = const None(),
    Option<bool Function(Dependency)> condition = const None(),
  }) {
    // NOTE: Built via Resolvable composition rather than `TaskSequencer`
    // because the sequencer's `seq.completion` only reflects tasks that were
    // chained synchronously — re-entrantly-queued tasks (which happen as
    // soon as ONE async step lands in the chain) update `_current` later,
    // and the caller's `await seq.completion.value` returns before they
    // drain. A direct Resolvable chain has none of that lag.
    final results = List.of(registry.reversedDependencies);
    Resolvable<Option> chain = Sync<Option>.okValue(const None());
    for (final dependency in results) {
      if (onBeforeUnregister case Some(value: final cb)) {
        chain = _nonEagerStep(
          chain,
          () => Resolvable<Option>(
            () => consec(
              awaitCallbackResult(
                cb(Ok(dependency)),
                logAndSwallowSyncErr: true,
                logContext:
                    'unregisterAll.onBeforeUnregister for '
                    '${dependency.runtimeType}',
              ),
              (_) => const None(),
            ),
          ),
        );
      }

      chain = _nonEagerStep(chain, () {
        if (condition case Some(value: final test)) {
          if (!test(dependency)) return syncNone();
        }
        // `dependency.typeEntity` is the raw registry key (e.g. `Sync<Foo>`),
        // not the inner T. `removeDependencyK` wraps its argument again, so
        // we must use `removeDependencyExact` here.
        registry
            .removeDependencyExact(
              dependency.typeEntity,
              groupEntity: dependency.metadata
                  .map((e) => e.groupEntity)
                  .unwrapOr(const DefaultEntity()),
            )
            .end();
        return switch (dependency.metadata) {
          Some(value: final metadata) => switch (metadata.onUnregister) {
              Some(value: final onUnregister) => dependency.value.then((e) {
                  return Resolvable<Resolvable<Option>>(
                    () => consec(
                      awaitCallbackResult(
                        onUnregister(Ok(e)),
                        logAndSwallowSyncErr: true,
                        logContext:
                            'unregisterAll dep onUnregister for '
                            '${dependency.runtimeType}',
                      ),
                      (_) => syncNone(),
                    ),
                  ).flatten();
                }).flatten(),
              None() => syncNone(),
            },
          None() => syncNone(),
        };
      });

      if (onAfterUnregister case Some(value: final cb)) {
        chain = _nonEagerStep(
          chain,
          () => Resolvable<Option>(
            () => consec(
              awaitCallbackResult(
                cb(Ok(dependency)),
                logAndSwallowSyncErr: true,
                logContext:
                    'unregisterAll.onAfterUnregister for '
                    '${dependency.runtimeType}',
              ),
              (_) => const None(),
            ),
          ),
        );
      }
    }
    return chain.toUnit();
  }

  /// Chains [step] after [prev], running it regardless of whether [prev]
  /// resolved to `Ok` or `Err` (non-eager semantics). The final chain's
  /// result is [step]'s result on the LAST iteration — intermediate failures
  /// are logged by the caller (via `awaitCallbackResult`) and the chain
  /// continues.
  Resolvable<Option> _nonEagerStep(
    Resolvable<Option> prev,
    Resolvable<Option> Function() step,
  ) {
    if (prev case Sync<Option>()) {
      // Sync prev: run step now regardless of prev's Result. Wrap `step` in
      // an anonymous Sync constructor body (the `@mustBeAnonymous` lint
      // forbids passing the captured ref directly).
      return Sync<Resolvable<Option>>(() => step()).flatten();
    }
    // Async prev: await, ignore the result, then run step.
    return Async<Option>(() async {
      try {
        (await prev.value).end();
      } catch (_) {
        // Non-eager: a previous step's failure does NOT stop this one.
      }
      // Surface step's own failure (the LAST step's result determines the
      // chain's terminal Resolvable; throwing here makes it an Err).
      return switch (await step().value) {
        Err<Option>(:final error) => throw error,
        Ok<Option>(value: final v) => v,
      };
    });
  }
}
