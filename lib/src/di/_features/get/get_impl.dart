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
base mixin GetImpl on DIBase implements GetIface {
  @override
  @pragma('vm:prefer-inline')
  T call<T extends Object>({
    Gr? group,
    bool getFromParents = true,
  }) {
    return get<T>(
      group: group,
      getFromParents: getFromParents,
    ) as T;
  }

  @override
  FutureOr<T> getInstance<T extends Object, P extends Object>(
    P params, {
    Gr? group,
    bool getFromParents = true,
  }) {
    return get<Inst<T, P>>(
      group: group,
      getFromParents: getFromParents,
    ).thenOr((e) => e.constructor(params));
  }

  FutureOr<T>? getInstanceOrNull<T extends Object, P extends Object>(
    P params, {
    Gr? group,
    bool getFromParents = true,
  }) {
    return getOrNull<Inst<T, P>>(
      group: group,
      getFromParents: getFromParents,
    )?.thenOr((e) => e.constructor(params));
  }

  @override
  FutureOr<T> getSingleton<T extends Object>({
    Gr? group,
    bool getFromParents = true,
  }) {
    return getInstance<SingletonWrapper<T>, Object>(
      Object(),
      group: group,
      getFromParents: getFromParents,
    ).thenOr((e) => e.instance);
  }

  FutureOr<T>? getSingletonOrNull<T extends Object>({
    Gr? group,
    bool getFromParents = true,
  }) {
    return getInstanceOrNull<SingletonWrapper<T>, Object>(
      Object(),
      group: group,
      getFromParents: getFromParents,
    )?.thenOr((e) => e.instance);
  }

  @override
  FutureOr<T>? getOrNull<T extends Object>({
    Gr? group,
    bool getFromParents = true,
  }) {
    final fg = preferFocusGroup(group);
    final registered = isRegistered<T, Object>(
      group: fg,
    );
    if (registered) {
      return get<T>(
        group: fg,
        getFromParents: getFromParents,
      );
    }
    return null;
  }

  @override
  FutureOr<T> get<T extends Object>({
    Gr? group,
    bool getFromParents = true,
  }) {
    final test = getSingletonOrNull<T>();
    if (test != null) {
      return test;
    }
    final fg = preferFocusGroup(group);
    final dep = _get<T, Object>(
      group: fg,
      getFromParents: getFromParents,
    );
    if (dep == null) {
      throw DependencyNotFoundException(
        type: T,
        group: fg,
      );
    }
    return dep.thenOr((e) => e.value);
  }

  FutureOr<Dependency<T>>? _get<T extends Object, P extends Object>({
    required Gr group,
    required bool getFromParents,
  }) {
    final dep = getDependencyOrNull1<T, P>(
      group: group,
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
    required Dependency<Object> dep,
    required bool getFromParents,
  }) {
    final value = (dep.value as I).cast<T, Object>();
    return value.thenOr((value) {
      return value.constructor(-1);
    }).thenOr((newValue) {
      return registerDependency<T, P>(
        dependency: dep.reassign(newValue),
        suppressDependencyAlreadyRegisteredException: true,
      );
      // }).thenOr((_) {
      //   return registry.removeDependency<I>(
      //     group: dep.group,
      //   );
    }).thenOr((_) {
      return _get<T, P>(
        group: dep.group,
        getFromParents: getFromParents,
      )!;
    });
  }
}
