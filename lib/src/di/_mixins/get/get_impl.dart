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
  }) {
    return getSync<T>(group: group);
  }

  @override
  T? getSyncOrNull<T extends Object>({
    Gr? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final registered = isRegistered<T>(
      group: focusGroup,
    );
    if (registered) {
      try {
        return getSync<T>(group: focusGroup);
      } catch (_) {}
    }
    return null;
  }

  @override
  T getSync<T extends Object>({
    Gr? group,
  }) {
    final value = get<T>(group: group);
    if (value is Future<T>) {
      throw TypeError();
    }
    return value;
  }

  @override
  Future<T>? getAsyncOrNull<T extends Object>({
    Gr? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final registered = isRegistered<T>(
      group: focusGroup,
    );
    if (registered) {
      try {
        return getAsync<T>(group: focusGroup);
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<T> getAsync<T extends Object>({
    Gr? group,
  }) async {
    final value = await get<T>(group: group);
    return value;
  }

  @override
  FutureOr<T?> getOrNull<T extends Object>({
    Gr? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final registered = isRegistered<T>(
      group: focusGroup,
    );
    if (registered) {
      return get<T>(group: focusGroup);
    }
    return null;
  }

  @override
  FutureOr<T> get<T extends Object>({
    Gr? group,
  }) {
    focusGroup = preferFocusGroup(group);
    final dep = _get<T>(group: focusGroup);
    if (dep == null) {
      throw DependencyNotFoundException(
        type: T,
        group: focusGroup,
      );
    }
    return dep.thenOr((e) => e.value);
  }

  @protected
  FutureOr<Dependency<T>>? _get<T extends Object>({
    required Gr group,
  }) {
    final dep = getDependencyOrNull1<T>(group: group);
    if (dep != null) {
      switch (dep.value) {
        case T _:
          return dep.cast();
        case FutureInst<T> _:
          return _inst<T, FutureInst<T>>(dep);
        case SingletonInst<T> _:
          return _inst<T, SingletonInst<T>>(dep);
      }
    }
    return null;
  }

  FutureOr<Dependency<T>>
      _inst<T extends Object, TInst extends Inst<T, Object>>(
    Dependency<Object> dep,
  ) {
    final value = (dep.value as TInst).cast<T, Object>();
    return value.thenOr((value) {
      return value.constructor(-1);
    }).thenOr((newValue) {
      return registerDependency<T>(
        dependency: dep.reassign(newValue),
        suppressDependencyAlreadyRegisteredException: true,
      );
    }).thenOr((_) {
      return registry.removeDependency<TInst>(
        group: dep.group,
      );
    }).thenOr((_) {
      return _get<T>(
        group: dep.group,
      )!;
    });
  }
}
