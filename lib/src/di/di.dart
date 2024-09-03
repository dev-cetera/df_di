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
import 'package:meta/meta.dart';

import '/src/_index.g.dart';
import '/src/utils/_dependency.dart';
import '_di_parts/_index.g.dart';
import '_di_parts/debug/debug_impl.dart';
import '_di_parts/get/get_impl.dart';
import '_di_parts/get_dependency/get_dependency_impl.dart';
import '_di_parts/get_factory/get_factory_impl.dart';
import '_di_parts/get_using_exact_type/get_using_exact_type_impl.dart';
import '_di_parts/is_registered/is_registered_impl.dart';
import '_di_parts/register_dependency/register_dependency_impl.dart';
import '_di_parts/remove_dependency/remove_dependency_impl.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A flexible and extensive Dependency Injection (DI) class for managing
/// dependencies across an application.
base class DI extends DIBase
    with
        ChildImpl,
        FocusGroupImpl,
        UnregisterImpl,
        DebugImpl,
        GetDependencyImpl,
        RemoveDependencyImpl,
        IsRegisteredImpl,
        GetFactoryImpl,
        GetImpl,
        GetUsingExactTypeImpl,
        RegisterDependencyImpl {
  //
  //
  //

  /// Default app group.
  static final app = DI.instantiate(
    onInstantiate: (di) {
      di.registerChild(group: Descriptor.globalGroup);
      di.registerChild(group: Descriptor.sessionGroup);
      di.registerChild(group: Descriptor.devGroup);
      di.registerChild(group: Descriptor.prodGroup);
      di.registerChild(group: Descriptor.testGroup);
    },
  );

  /// Default global group.
  static DI get global => app.getChild(group: Descriptor.globalGroup);
  static DI get session => app.getChild(group: Descriptor.sessionGroup);
  static DI get dev => app.getChild(group: Descriptor.devGroup);
  static DI get prod => app.getChild(group: Descriptor.prodGroup);
  static DI get test => app.getChild(group: Descriptor.testGroup);

  /// The number of dependencies registered in this instance.
  int get length => _registrationCount;

  /// Tracks the registration count, assigning a unique index number to each
  /// registration.
  var _registrationCount = 0;

  /// Creates a new instance of the DI class. Prefer using [global], unless
  /// there's a specific need for a separate instance.
  DI({
    super.focusGroup,
    @protected super.parent,
  });

  factory DI.instantiate({
    Descriptor<Object>? focusGroup = Descriptor.defaultGroup,
    DIBase? parent,
    void Function(DI di)? onInstantiate,
  }) {
    final instance = DI(
      focusGroup: focusGroup,
      parent: parent,
    );
    onInstantiate?.call(instance);
    return instance;
  }

  //
  //
  //

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

  //
  //
  //

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

  //
  //
  //

  @protected
  @override
  void registerOr<T extends Object, R extends Object>(
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
          registrationIndex: _registrationCount++,
          group: focusGroup,
          onUnregister: onUnregister != null ? (e) => e is R ? onUnregister(e) : null : null,
          condition: condition,
        ),
      );
    } else {
      registerDependency<FutureInst<T, Object>>(
        dependency: Dependency(
          value: FutureInst<T, Object>((_) => value),
          registrationIndex: _registrationCount++,
          group: focusGroup,
          onUnregister: onUnregister != null ? (e) => e is R ? onUnregister(e) : null : null,
          condition: condition,
        ),
      );
    }
  }

  @protected
  @override
  void registerUsingExactTypeOr<T extends Object, R extends Object>(
    FutureOr<T> value, {
    Descriptor? group,
    OnUnregisterCallback<R>? onUnregister,
    GetDependencyCondition? condition,
  }) {
    final focusGroup = preferFocusGroup(group);
    if (value is T) {
      registerDependencyUsingExactType(
        type: Descriptor.type(T),
        dependency: Dependency(
          value: value,
          registrationIndex: _registrationCount++,
          group: focusGroup,
          onUnregister: onUnregister != null ? (e) => e is R ? onUnregister(e) : null : null,
          condition: condition,
        ),
      );
    } else {
      registerDependencyUsingExactType(
        type: Descriptor.type(FutureInst<T, Object>),
        dependency: Dependency(
          value: FutureInst<T, Object>((_) => value),
          registrationIndex: _registrationCount++,
          group: focusGroup,
          onUnregister: onUnregister != null ? (e) => e is R ? onUnregister(e) : null : null,
          condition: condition,
        ),
      );
    }
  }

  //
  //
  //
}
