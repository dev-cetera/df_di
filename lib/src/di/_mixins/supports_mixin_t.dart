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

/// A mixin that provides methods for working with dependencies,
/// using `Type` for type resolution.
base mixin SupportsMixinT on SupportsMixinK {
  /// Retrieves the synchronous dependency unsafely, returning the instance
  /// directly.
  @pragma('vm:prefer-inline')
  T getSyncUnsafeT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getSyncUnsafeK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Retrieves the synchronous dependency.
  @pragma('vm:prefer-inline')
  Option<Sync<T>> getSyncT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getSyncK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Retrieves an asynchronous dependency unsafely, returning a future of the
  /// instance, directly or throwing an error if not found.
  @pragma('vm:prefer-inline')
  Future<T> getAsyncUnsafeT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getAsyncUnsafeK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Retrieves an asynchronous dependency.
  @pragma('vm:prefer-inline')
  Option<Async<T>> getAsyncT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getAsyncK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Retrieves a dependency unsafely, returning it directly or throwing an
  /// error if not found.
  @pragma('vm:prefer-inline')
  FutureOr<T> getUnsafeT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getUnsafeK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Retrieves the synchronous dependency or `None` if not found or async.
  @pragma('vm:prefer-inline')
  Option<T> getSyncOrNoneT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getSyncOrNoneK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Retrieves the dependency.
  @pragma('vm:prefer-inline')
  Option<Resolvable<T>> getT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Retrieves the underlying `Dependency` object.
  @pragma('vm:prefer-inline')
  Option<Result<Dependency<T>>> getDependencyT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getDependencyK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Unregisters a dependency. Mirrors [unregisterK]'s contract — see there
  /// for `traverse`, `removeAll`, and `triggerOnUnregisterCallbacks`.
  @pragma('vm:prefer-inline')
  Resolvable<Option> unregisterT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
    bool removeAll = true,
    bool triggerOnUnregisterCallbacks = true,
  }) {
    return unregisterK(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
      removeAll: removeAll,
      triggerOnUnregisterCallbacks: triggerOnUnregisterCallbacks,
    );
  }

  /// Removes a dependency from the registry. Mirrors [removeDependencyK] —
  /// public on this track for parity with the plain and K variants.
  @pragma('vm:prefer-inline')
  Option<Dependency> removeDependencyT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
  }) {
    return removeDependencyK<T>(TypeEntity(type), groupEntity: groupEntity);
  }

  /// Checks if a dependency is registered.
  @pragma('vm:prefer-inline')
  bool isRegisteredT(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return isRegisteredK(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Waits until a dependency with the exact `typeEntity` is registered.
  /// The result is cast to `T`.
  ///
  /// **Note:** Requires `enableUntilExactlyK: true` during registration.
  /// If `typeEntity` doesn't match an existing or future registration exactly,
  /// this will not resolve.
  @pragma('vm:prefer-inline')
  Resolvable<T> untilExactlyT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilExactlyK<T>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Alias for [untilExactlyT] that exists for naming-symmetry with the plain
  /// `untilSuper<T>` track. The T (Type-keyed) track is exact-match by design
  /// (a `Type` is wrapped in a `TypeEntity` and looked up by equality), so
  /// "Super" here is purely an API-naming convenience — subtype relationships
  /// between Dart types are NOT considered. Requires `enableUntilExactlyK:
  /// true` at registration time.
  @pragma('vm:prefer-inline')
  Resolvable<T> untilSuperT<T extends Object>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilExactlyT<T>(
      type,
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  /// Counterpart to `until<TSuper, TSub>` on the T (Type-keyed) track. Waits
  /// exact-match on [type] (T is exact-only by design — see [untilSuperT])
  /// and casts the resolved value to [TSub]. Requires `enableUntilExactlyK:
  /// true` at registration time.
  @pragma('vm:prefer-inline')
  Resolvable<TSub> untilT<TSuper extends Object, TSub extends TSuper>(
    Type type, {
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return untilK<TSuper, TSub>(
      TypeEntity(type),
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }
}
