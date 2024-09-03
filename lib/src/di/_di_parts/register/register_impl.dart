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

import 'dart:async';

import 'package:df_type/df_type.dart';

import '/src/utils/_dependency.dart';
import 'package:meta/meta.dart';

import '/src/_index.g.dart';
import 'register_inter.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
base mixin RegisterImpl on DIBase implements RegisterInter {
  @override
  void register<T extends Object>(
    FutureOr<T> value, {
    Descriptor? group,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    _register(
      value,
      group: group,
      onUnregister: onUnregister,
    );
  }

  @override
  void registerLazySingletonService<T extends Service>(
    Constructor<T> constructor, {
    Descriptor? group,
  }) {
    registerLazySingleton(
      (params) => constructor().thenOr((e) => e.initService(params).thenOr((_) => e)),
      group: group,
      onUnregister: (e) {
        return e.thenOr((e) {
          return e.initialized.thenOr((_) {
            // ignore: invalid_use_of_protected_member
            return e.dispose();
          });
        });
      },
    );
  }

  @override
  void registerFactoryService<T extends Service, P extends Object>(
    Constructor<T> constructor, {
    Descriptor? group,
  }) {
    registerFactory<T, P>(
      (params) => constructor().thenOr((e) => e.initService(params).thenOr((_) => e)),
      group: group,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  void registerLazySingleton<T extends Object, P extends Object>(
    InstConstructor<T, P> constructor, {
    Descriptor? group,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    _register(
      SingletonInst<T, P>(constructor),
      group: group,
      onUnregister: onUnregister,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  void registerFactory<T extends Object, P extends Object>(
    InstConstructor<T, P> constructor, {
    Descriptor? group,
  }) {
    _register(
      FactoryInst<T, P>(constructor),
      group: group,
    );
  }

  void _register<T extends Object, R extends Object>(
    FutureOr<T> value, {
    Descriptor? group,
    OnUnregisterCallback<R>? onUnregister,
    GetDependencyCondition? condition,
  }) {
    final focusGroup = preferFocusGroup(group);
    if (value is T) {
      registerDependency<T>(
        dependency: Dependency(
          value: value,
          registrationIndex: registrationCount++,
          group: focusGroup,
          onUnregister: onUnregister != null ? (e) => e is R ? onUnregister(e) : null : null,
          condition: condition,
        ),
      );
    } else {
      registerDependency<FutureInst<T, Object>>(
        dependency: Dependency(
          value: FutureInst<T, Object>((_) => value),
          registrationIndex: registrationCount++,
          group: focusGroup,
          onUnregister: onUnregister != null ? (e) => e is R ? onUnregister(e) : null : null,
          condition: condition,
        ),
      );
    }
  }
}