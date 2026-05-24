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

/// Adds child-container support to [DI]. Children are themselves [DI]
/// instances stored lazily under a `groupEntity` and parented to `this`, so
/// lookups in a child fall through to its parent via the existing `traverse`
/// machinery. This is what backs [DI.global] / [DI.session] / [DI.user] /
/// etc.
base mixin SupportsChildrenMixin on SupportsConstructorsMixin {
  /// Registers a fresh child [DI] container under [groupEntity]. The child
  /// is created lazily on first access and is wired to `this` as its parent.
  Resolvable<Lazy<DI>> registerChild({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final container = switch (childrenContainer) {
      Some(value: final c) => c,
      None() => () {
          final c = DI();
          childrenContainer = Some(c);
          return c;
        }(),
    };
    return container.registerLazy<DI>(
      () => Sync.okValue(DI()..parents.add(this as DI)),
      groupEntity: groupEntity,
    );
  }

  /// Returns the child registered under [groupEntity], or `None` if no child
  /// is registered or it failed to construct.
  Option<DI> getChildOrNone({Entity groupEntity = const DefaultEntity()}) {
    return switch (getChild(groupEntity: groupEntity)) {
      Some(value: Ok(value: final di)) => Some(di),
      _ => const None(),
    };
  }

  /// Returns the child registered under [groupEntity] wrapped in a `Result`,
  /// or `None` if no child is registered. The `Result` carries an `Err` if
  /// child construction failed.
  Option<Result<DI>> getChild({Entity groupEntity = const DefaultEntity()}) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (childrenContainer case Some(value: final container)) {
      // Collapse Option<Resolvable<DI>> → Option<Result<DI>>. Sync-Ok and
      // Sync-Err are direct; Async returns Err (caller can re-await
      // explicitly if they need the future shape).
      return switch (container.getLazySingleton<DI>(groupEntity: g)) {
        None() => const None(),
        Some(value: Sync(value: final result)) => Some(result),
        Some(value: Async()) =>
          Some(Err('getChild: lazy singleton resolved async, not supported.')),
      };
    }
    return const None();
  }

  /// `Type`-keyed variant of [getChild].
  Option<Result<DI>> getChildT({Entity groupEntity = const DefaultEntity()}) {
    final g = groupEntity.preferOverDefault(focusGroup);
    if (childrenContainer case Some(value: final container)) {
      return switch (container.getLazySingletonT<DI>(DI, groupEntity: g)) {
        None() => const None(),
        Some(value: Sync(value: final result)) => Some(result.transf<DI>()),
        Some(value: Async()) =>
          Some(Err('getChildT: lazy singleton resolved async, not supported.')),
      };
    }
    return const None();
  }

  /// Children are registered as `Lazy<DI>`, so unregister must remove the
  /// lazy key — `unregister<DI>` would not match under the strict-keying
  /// contract.
  Result<Option<DI>> unregisterChild({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final container = switch (childrenContainer) {
      Some(value: final c) => c,
      None() => null,
    };
    if (container == null) return Err('No child container registered.');
    // Children are registered as Sync lazies (see [registerChild]), so the
    // unregister Resolvable should always be Sync. If it isn't, that's a
    // contract violation — throw to make it visible. The previous
    // implementation panicked here via `.sync().unwrap()`; we preserve that
    // semantics so callers like `plugin.dart::uninstallPlugin` that use
    // `.end()` on the Result still get a visible crash rather than a
    // silently-dropped Err.
    return switch (container.unregister<Lazy<DI>>(groupEntity: g)) {
      Sync(value: Ok(value: Some(value: final lazy))) =>
        _ok(_eagerLazyDI(lazy)),
      Sync(value: Ok(value: None())) => const Ok(None()),
      Sync(value: Err(:final error, :final stackTrace)) =>
        Err<Option<DI>>(error, stackTrace: stackTrace),
      Async() => throw StateError(
          'unregisterChild: child unregister resolved Async, but children '
          'must be Sync. This is a programming-error contract violation.',
        ),
    };
  }

  /// `Type`-keyed variant of [unregisterChild].
  Result<Option<DI>> unregisterChildT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    final container = switch (childrenContainer) {
      Some(value: final c) => c,
      None() => null,
    };
    if (container == null) return Err('No child container registered.');
    return switch (
        container.unregisterK(TypeEntity(Lazy, [type]), groupEntity: g)) {
      Sync(value: Ok(value: Some(value: final raw))) =>
        _ok(_eagerLazyDI(raw as Lazy<DI>)),
      Sync(value: Ok(value: None())) => const Ok(None()),
      Sync(value: Err(:final error, :final stackTrace)) =>
        Err<Option<DI>>(error, stackTrace: stackTrace),
      Async() => throw StateError(
          'unregisterChildT: child unregister resolved Async, but children '
          'must be Sync. This is a programming-error contract violation.',
        ),
    };
  }

  /// Wraps [v] in `Ok(Some(v))`. Tiny helper that keeps the giant switch
  /// arms above readable.
  Ok<Option<DI>> _ok(DI v) => Ok(Some(v));

  /// Eagerly forces a `Lazy<DI>` to its synchronous singleton. Used at child
  /// unregister so the caller gets the DI instance back. If construction was
  /// async this is a logic bug — children must be sync-constructible.
  DI _eagerLazyDI(Lazy<DI> lazy) {
    UNSAFE:
    return lazy.singleton.sync().unwrap().unwrap();
  }

  /// Children are registered as `Lazy<DI>` (see [registerChild]), so probe
  /// for that exact key — `isRegistered<DI>` would not match under the
  /// strict-keying contract.
  bool isChildRegistered({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    return switch (childrenContainer) {
      Some(value: final c) => c.isRegistered<Lazy<DI>>(groupEntity: g),
      None() => false,
    };
  }

  /// `Type`-keyed variant of [isChildRegistered]. Functionally identical —
  /// kept for naming-symmetry with the rest of the T-track API.
  bool isChildRegisteredT({
    Entity groupEntity = const DefaultEntity(),
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    return switch (childrenContainer) {
      Some(value: final c) =>
        c.isRegisteredK(TypeEntity(Lazy, [DI]), groupEntity: g),
      None() => false,
    };
  }

  /// Returns the child container under [groupEntity], registering one
  /// lazily if needed. This is the convenience entry point most callers
  /// reach for — `DI.global`, `DI.session`, `DI.user`, etc. all funnel
  /// through here.
  DI child({Entity groupEntity = const DefaultEntity()}) {
    if (!isChildRegistered(groupEntity: groupEntity)) {
      registerChild(groupEntity: groupEntity).end();
    }
    return switch (getChild(groupEntity: groupEntity)) {
      Some(value: Ok(value: final di)) => di,
      Some(value: Err(:final error)) =>
        throw StateError('child(): construction failed: $error'),
      None() => throw StateError(
          'child(): registerChild succeeded but getChild returned None.',
        ),
    };
  }
}
