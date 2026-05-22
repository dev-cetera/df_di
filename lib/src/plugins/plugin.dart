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

/// An app-level plugin: a self-contained bundle of services, resources, and
/// behaviour that can be installed into a [DI] scope at runtime and removed
/// cleanly later. Use these to make whole features pluggable — themes, auth
/// providers, analytics backends, optional integrations, etc.
///
/// Each installed plugin owns a fresh child [DI] scope keyed by [id]. Anything
/// registered into that scope during [install] is torn down automatically on
/// uninstall — including `ServiceMixin` services, whose `dispose()` is
/// cascaded via the standard unregister hook.
///
/// Distinct from `EcsPlugin` (in `src/ecs/ecs.dart`), which bundles systems
/// and resources into an ECS [World] rather than a DI scope.
@immutable
abstract class Plugin {
  const Plugin();

  /// Identifies this plugin within a host [DI] scope. Defaults to
  /// `TypeEntity(runtimeType)`, so only one instance of a given `Plugin`
  /// subclass can be installed in the same scope at once. Override to support
  /// multiple coexisting variants (e.g. multiple `ThemePlugin`s keyed by
  /// name).
  Entity get id => TypeEntity(runtimeType);

  /// Called when this plugin is installed. [scope] is a fresh child [DI]
  /// scope owned by this plugin — register services, resources, and nested
  /// scopes here. Everything in [scope] is torn down automatically on
  /// uninstall.
  @visibleForOverriding
  Resolvable<Unit> install(DI scope) => syncUnit();

  /// Called when this plugin is uninstalled, **before** [scope] is torn down.
  /// Use this only for cleanup the registry cannot do automatically —
  /// e.g. deregistering from singletons living *outside* [scope], closing
  /// external resources not held as services.
  ///
  /// `ServiceMixin` services registered via `registerAndInitService` already
  /// have `dispose()` cascaded via the standard unregister hook, so most
  /// plugins do not need to override this.
  @visibleForOverriding
  Resolvable<Unit> uninstall(DI scope) => syncUnit();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension PluginHostX on DI {
  /// Installs [plugin] into a fresh child scope of this container keyed by
  /// `plugin.id`. Returns the child [DI] holding the plugin's registrations.
  ///
  /// Idempotent: if a plugin with the same `id` is already installed, this
  /// returns the existing scope without re-running [Plugin.install].
  Resolvable<DI> installPlugin(Plugin plugin) {
    if (hasPlugin(plugin)) {
      return Sync.okValue(child(groupEntity: plugin.id));
    }
    final scope = child(groupEntity: plugin.id);
    return plugin.install(scope).then((_) => scope);
  }

  /// Uninstalls [plugin]: invokes [Plugin.uninstall], tears down every
  /// dependency in its child scope (cascading `ServiceMixin.dispose()` via
  /// the standard unregister hook), then drops the child scope itself.
  ///
  /// No-op if [plugin] is not installed.
  Resolvable<Unit> uninstallPlugin(Plugin plugin) {
    if (!hasPlugin(plugin)) return syncUnit();
    final scope = child(groupEntity: plugin.id);
    return plugin
        .uninstall(scope)
        .then((_) => scope.unregisterAll())
        .flatten()
        .then((_) {
          unregisterChild(groupEntity: plugin.id).end();
          return Unit();
        });
  }

  /// Whether [plugin] is currently installed in this scope.
  bool hasPlugin(Plugin plugin) =>
      isChildRegistered<DI>(groupEntity: plugin.id);
}
