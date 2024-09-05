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
base mixin RegisterImpl on DIBase implements RegisterIface {
  @override
  void register<T extends Object>(
    FutureOr<T> value, {
    Gr? group,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    _register<T, Object, T>(
      value,
      group: group,
      onUnregister: onUnregister,
    );
  }

  @override
  void registerLazySingletonService<T extends Service<Object>>(
    Constructor<T> constructor, {
    Gr? group,
  }) {
    registerLazySingleton(
      (params) => constructor().thenOr((e) => e.initService(params).thenOr((_) => e)),
      group: group,
      onUnregister: (e) {
        return e.thenOr((e) {
          return e.initialized.thenOr((_) {
            return e.dispose();
          });
        });
      },
    );
  }

  @override
  void registerFactoryService<T extends Service<P>, P extends Object>(
    Constructor<T> constructor, {
    Gr? group,
  }) {
    registerFactory<T, P>(
      (params) => constructor().thenOr((e) => e.initService(params).thenOr((_) => e)),
      group: group,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  void registerLazySingleton<T extends Object>(
    InstConstructor<T, Object> constructor, {
    Gr? group,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    _register<SingletonInst<T, Object>, Object, T>(
      SingletonInst<T, Object>(constructor),
      group: group,
      onUnregister: onUnregister,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  void registerFactory<T extends Object, P extends Object>(
    InstConstructor<T, P> constructor, {
    Gr? group,
  }) {
    _register<FactoryInst<T, P>, P, T>(
      FactoryInst<T, P>(constructor),
      group: group,
    );
  }

  void _register<T extends Object, P extends Object, R extends Object>(
    FutureOr<T> value, {
    Gr? group,
    OnUnregisterCallback<R>? onUnregister,
    GetDependencyCondition? condition,
  }) {
    final focusGroup = preferFocusGroup(group);
    if (value is Future<T>) {
      registerDependency<FutureInst<T, P>>(
        dependency: Dependency(
          value: FutureInst<T, P>((_) => value),
          registrationIndex: registrationCount++,
          group: focusGroup,
          onUnregister: onUnregister != null ? (e) => e is R ? onUnregister(e) : null : null,
          condition: condition,
        ),
      );
    } else {
      registerDependency<T>(
        dependency: Dependency(
          value: value,
          registrationIndex: registrationCount++,
          group: focusGroup,
          onUnregister: onUnregister != null ? (e) => e is R ? onUnregister(e) : null : null,
          condition: condition,
        ),
      );
    }
    // If there's a completer waiting for this value that was registered via the until() function,
    // complete it.
    getSyncOrNull<InternalCompleterOr<T>>(group: Gr(T))?.internalValue.complete(value);
  }
}
