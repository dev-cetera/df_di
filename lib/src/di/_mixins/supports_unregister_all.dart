//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A mixin that provides a method to unregister all dependencies.
base mixin SupportsUnregisterAll on DIBase {
  /// Unregisters all dependencies, optionally with callbacks and conditions.
  Resolvable<None> unregisterAll({
    TOnUnregisterCallback<Dependency>? onBeforeUnregister,
    TOnUnregisterCallback<Dependency>? onAfterUnregister,
    bool Function(Dependency)? condition,
  }) {
    final results = List.of(registry.reversedDependencies);
    final seq = SafeSequencer();
    for (final dependency in results) {
      if (onBeforeUnregister != null) {
        seq.addSafe((_) {
          return Resolvable(
            () => consec(onBeforeUnregister(Ok(dependency)), (_) => NONE),
          );
        }).end();
      }

      seq.addSafe((_) {
        if (condition != null && !condition(dependency)) {
          return null;
        }
        registry
            .removeDependencyK(
              dependency.typeEntity,
              groupEntity: dependency.metadata
                  .map((e) => e.groupEntity)
                  .unwrapOr(const DefaultEntity()),
            )
            .end();
        final metadataOption = dependency.metadata;
        if (metadataOption.isSome()) {
          final metadata = metadataOption.unwrap();
          final onUnregisterOption = metadata.onUnregister;
          if (onUnregisterOption.isSome()) {
            final onUnregister = onUnregisterOption.unwrap();
            return dependency.value.map((e) {
              return Resolvable<Resolvable<Option>>(
                () => consec(
                  onUnregister(Ok(e)),
                  (e) => e ?? const Sync.unsafe(Ok(None())),
                ),
              ).flatten();
            }).flatten();
          }
        }
        return null;
      }).end();
      if (onAfterUnregister != null) {
        seq.addSafe((_) {
          return Resolvable(
            () => consec(onAfterUnregister(Ok(dependency)), (_) => NONE),
          );
        }).end();
      }
    }
    return seq.last.map((e) => const None());
  }
}
