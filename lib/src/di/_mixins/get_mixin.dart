//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// ignore_for_file: invalid_use_of_protected_member

import '/src/_internal.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
base mixin GetMixin on DIBase implements GetInterface {
  @override
  @pragma('vm:prefer-inline')
  T call<T extends Object>({
    DIKey? groupKey,
    bool getFromParents = true,
  }) {
    return get<T>(
      groupKey: groupKey,
      getFromParents: getFromParents,
    ) as T;
  }

  @override
  FutureOr<T> getInstance<T extends Object, P extends Object>(
    P params, {
    DIKey? groupKey,
    bool getFromParents = true,
  }) {
    return get<Inst<T, P>>(
      groupKey: groupKey,
      getFromParents: getFromParents,
    ).thenOr((e) => e.constructor(params));
  }

  FutureOr<T>? getInstanceOrNull<T extends Object, P extends Object>(
    P params, {
    DIKey? groupKey,
    bool getFromParents = true,
  }) {
    return getOrNull<Inst<T, P>>(
      groupKey: groupKey,
      getFromParents: getFromParents,
    )?.thenOr((e) => e.constructor(params));
  }

  @override
  FutureOr<T> getSingleton<T extends Object>({
    DIKey? groupKey,
    bool getFromParents = true,
  }) {
    return getInstance<SingletonWrapper<T>, Object>(
      Object(),
      groupKey: groupKey,
      getFromParents: getFromParents,
    ).thenOr((e) => e.instance);
  }

  FutureOr<T>? getSingletonOrNull<T extends Object>({
    DIKey? groupKey,
    bool getFromParents = true,
  }) {
    return getInstanceOrNull<SingletonWrapper<T>, Object>(
      Object(),
      groupKey: groupKey,
      getFromParents: getFromParents,
    )?.thenOr((e) => e.instance);
  }

  @override
  FutureOr<T>? getOrNull<T extends Object>({
    DIKey? groupKey,
    bool getFromParents = true,
  }) {
    final fg = preferFocusGroup(groupKey);
    final registered = isRegistered<T, Object>(
      groupKey: fg,
    );
    if (registered) {
      return get<T>(
        groupKey: fg,
        getFromParents: getFromParents,
      );
    }
    return null;
  }

  @override
  FutureOr<T> get<T extends Object>({
    DIKey? groupKey,
    bool getFromParents = true,
  }) {
    final test = getSingletonOrNull<T>();
    if (test != null) {
      return test;
    }
    final fg = preferFocusGroup(groupKey);
    final dep = _get<T, Object>(
      groupKey: fg,
      getFromParents: getFromParents,
    );
    if (dep == null) {
      throw DependencyNotFoundException(
        type: T,
        groupKey: fg,
      );
    }
    return dep.thenOr((e) => e.value);
  }

  FutureOr<Dependency<T>>? _get<T extends Object, P extends Object>({
    required DIKey groupKey,
    required bool getFromParents,
  }) {
    final dep = getDependencyOrNull1<T, P>(
      groupKey: groupKey,
      getFromParents: getFromParents,
    );
    if (dep != null) {
      switch (dep.value) {
        case T _:
          return dep.cast();
        case FutureOrInst<T, P> _:
          return _inst<T, P, FutureOrInst<T, P>>(
            dep: dep,
            getFromParents: getFromParents,
          );
      }
    }
    return null;
  }

  FutureOr<Dependency<T>> _inst<T extends Object, P extends Object, I extends Inst<T, P>>({
    required Dependency dep,
    required bool getFromParents,
  }) {
    final value = (dep.value as I).cast<T, Object>();
    return value.thenOr((value) {
      return value.constructor(-1);
    }).thenOr((newValue) {
      return registerDependency<T, P>(
        dependency: dep.passNewValue(newValue),
        suppressDependencyAlreadyRegisteredException: true,
      );
      // }).thenOr((_) {
      //   return registry.removeDependency<I>(
      //     groupKey: dep.groupKey,
      //   );
    }).thenOr((_) {
      return _get<T, P>(
        groupKey: dep.metadata!.groupKey!,
        getFromParents: getFromParents,
      )!;
    });
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
abstract interface class GetInterface {
  /// A shorthand for [getSync], allowing retrieval of a dependency using
  /// call syntax.
  T call<T extends Object>({
    DIKey? groupKey,
    bool getFromParents = true,
  });

  /// Gets via [get] using [T] and [groupKey] or `null` upon any error,
  /// including but not limited to [DependencyNotFoundException].
  FutureOr<T>? getOrNull<T extends Object>({
    DIKey? groupKey,
    bool getFromParents = true,
  });

  /// Gets a dependency as either a [Future] or an instance of [T] registered
  /// under the type [T] and the specified [groupKey], or under [DIKey.defaultGroup]
  /// if no groupKey is provided.
  ///
  /// If the dependency was registered as a lazy singleton via [registerLazySingleton]
  /// and hasn't been instantiated yet, it will be instantiated on the first call.
  /// Subsequent calls to [get] will return the already instantiated instance.
  ///
  /// If the dependency was registered via [registerFactory], a new instance
  /// will be created and returned with each call to [get].
  ///
  /// - Throws [DependencyNotFoundException] if the requested dependency cannot
  /// be found.
  FutureOr<T> get<T extends Object>({
    DIKey? groupKey,
  });

  FutureOr<T> getInstance<T extends Object, P extends Object>(
    P params, {
    DIKey? groupKey,
    bool getFromParents = true,
  });

  FutureOr<T> getSingleton<T extends Object>({
    DIKey? groupKey,
    bool getFromParents = true,
  });
}
