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

// ignore_for_file: invalid_use_of_visible_for_testing_member

import '/src/_common.dart';

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
      seq
        ..addSafe((_) {
          return onBeforeUnregister?.call(Ok(dependency));
        })
        ..addSafe((_) {
          if (condition != null && !condition(dependency)) {
            return null;
          }
          registry.removeDependencyK(
            dependency.typeEntity,
            groupEntity:
                dependency.metadata.map((e) => e.groupEntity).unwrapOr(const DefaultEntity()),
          );
          final metadataOption = dependency.metadata;
          if (metadataOption.isSome()) {
            final metadata = metadataOption.unwrap();
            final onUnregisterOption = metadata.onUnregister;
            if (onUnregisterOption.isSome()) {
              final onUnregister = onUnregisterOption.unwrap();
              return dependency.value
                  .map(
                    (e) => onUnregister(Ok(e)) ?? const Sync.value(Ok(None())),
                  )
                  .flatten();
            }
          }
          return null;
        })
        ..addSafe((_) {
          return onAfterUnregister?.call(Ok(dependency));
        });
    }
    return seq.last;
  }
}
