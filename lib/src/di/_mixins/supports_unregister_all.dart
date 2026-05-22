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

/// A mixin that provides a method to unregister all dependencies.
base mixin SupportsUnregisterAll on DIBase {
  /// Unregisters all dependencies, optionally with callbacks and conditions.
  Resolvable<Unit> unregisterAll({
    Option<TOnUnregisterCallback<Dependency>> onBeforeUnregister = const None(),
    Option<TOnUnregisterCallback<Dependency>> onAfterUnregister = const None(),
    Option<bool Function(Dependency)> condition = const None(),
  }) {
    final results = List.of(registry.reversedDependencies);
    final seq = TaskSequencer();
    for (final dependency in results) {
      if (onBeforeUnregister case Some(value: final cb)) {
        seq.then((_) {
          return Resolvable(
            () => consec(cb(Ok(dependency)), (_) => const None()),
          );
        }).end();
      }

      seq.then((_) {
        if (condition case Some(value: final test)) {
          if (!test(dependency)) {
            return syncNone();
          }
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
                () => consec(onUnregister(Ok(e)), (e) => syncNone()),
              ).flatten();
            }).flatten(),
            None() => syncNone(),
          },
          None() => syncNone(),
        };
      }).end();
      if (onAfterUnregister case Some(value: final cb)) {
        seq.then((_) {
          return Resolvable(
            () => consec(cb(Ok(dependency)), (_) => const None()),
          );
        }).end();
      }
    }
    return seq.completion.toUnit();
  }
}
