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
import '/src/utils/_type_safe_registry/type_safe_registry.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A flexible and extensive Dependency Injection (DI) class for managing
/// dependencies across an application.
base class DI extends DIBase {
  //
  //
  //

  /// A type-safe registry that stores all dependencies.
  @protected
  final registry = TypeSafeRegistry();

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
      reg<T>(
        dependency: Dependency(
          value: value,
          registrationIndex: _registrationCount++,
          group: focusGroup,
          onUnregister: onUnregister != null ? (e) => e is R ? onUnregister(e) : null : null,
          condition: condition,
        ),
      );
    } else {
      reg<FutureInst<T, Object>>(
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
  void registerOfExactTypeOr<T extends Object, R extends Object>(
    FutureOr<T> value, {
    Descriptor? group,
    OnUnregisterCallback<R>? onUnregister,
    GetDependencyCondition? condition,
  }) {
    final focusGroup = preferFocusGroup(group);
    if (value is T) {
      regOfExactType(
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
      regOfExactType(
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

  @protected
  @override
  FutureOr<Dependency<T>> getInternal<T extends Object>({
    Descriptor? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final result = _execOrNull(
      (di) => _getInternal<T>(
        di: di,
        group: focusGroup,
      ),
    );
    if (result == null) {
      throw DependencyNotFoundException(
        type: T,
        group: focusGroup,
      );
    }
    return result;
  }

  static FutureOr<Dependency<T>>? _getInternal<T extends Object>({
    required DI di,
    required Descriptor group,
  }) {
    // Sync types.
    {
      final dep = di.registry.getDependencyOrNull<T>(
        group: group,
      );
      if (dep != null) {
        return dep.cast();
      }
    }
    // Future types.
    {
      final res = _inst<T, FutureInst<T, Object>>(
        di: di,
        group: group,
      );
      if (res != null) {
        return res;
      }
    }
    // Singleton types.
    {
      final res = _inst<T, SingletonInst<T, Object>>(
        di: di,
        group: group,
      );
      if (res != null) {
        return res;
      }
    }
    return null;
  }

  static FutureOr<Dependency<T>>? _inst<T extends Object, TInst extends Inst<T, Object>>({
    required DI di,
    required Descriptor group,
  }) {
    final dep = di.registry.getDependencyOrNull<TInst>(
      group: group,
    );
    if (dep != null) {
      final value = (dep.value as TInst).cast<T, Object>();
      return value.thenOr((value) {
        return value.constructor(-1);
      }).thenOr((newValue) {
        return di.reg<T>(
          dependency: dep.reassign(newValue),
          suppressDependencyAlreadyRegisteredException: true,
        );
      }).thenOr((_) {
        return di.registry.removeDependency<TInst>(
          group: group,
        );
      }).thenOr((_) {
        return di.getInternal<T>(
          group: group,
        );
      });
    }
    return null;
  }

  @protected
  @override
  void reg<T extends Object>({
    required Dependency<T> dependency,
    bool suppressDependencyAlreadyRegisteredException = false,
  }) {
    final group = dependency.group;
    final dep = registry.getDependencyOrNull<T>(
      group: group,
    );
    if (!suppressDependencyAlreadyRegisteredException && dep != null) {
      throw DependencyAlreadyRegisteredException(
        type: T,
        group: group,
      );
    }
    // Store the dependency in the type map.
    registry.setDependency<T>(
      value: dependency,
    );
  }

  //
  //
  //

  @protected
  @override
  FutureOr<Dependency<Object>> getOfExactTypeInternal({
    required Descriptor type,
    Descriptor? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final result = _execOrNull(
      (di) => _getOfExactTypeInternal(
        di: di,
        type: type,
        group: focusGroup,
      ),
    );
    if (result == null) {
      throw DependencyNotFoundException(
        type: type,
        group: focusGroup,
      );
    }
    return result;
  }

  static FutureOr<Dependency<Object>>? _getOfExactTypeInternal({
    required DI di,
    required Descriptor type,
    required Descriptor group,
  }) {
    // Sync types.
    {
      final dep = di.registry.getDependencyOfExactTypeOrNull(
        type: type,
        group: group,
      );
      if (dep != null) {
        return dep;
      }
    }
    // Future types.
    {
      final genericType = Descriptor.genericType<FutureInst>([type]);
      final res = _instExactType(
        di: di,
        type: type,
        genericType: genericType,
        group: group,
      );
      if (res != null) {
        return res;
      }
    }
    // Singleton types.
    {
      final genericType = Descriptor.genericType<SingletonInst>([type]);
      final res = _instExactType(
        di: di,
        type: type,
        genericType: genericType,
        group: group,
      );
      if (res != null) {
        return res;
      }
    }
    return null;
  }

  static FutureOr<Dependency<Object>>? _instExactType({
    required DI di,
    required Descriptor type,
    required Descriptor genericType,
    required Descriptor group,
  }) {
    final dep = di.registry.getDependencyOfExactTypeOrNull(
      type: genericType,
      group: group,
    );
    if (dep != null) {
      final value = dep.value;
      return value.thenOr((value) {
        return (value as Inst).constructor(-1);
      }).thenOr((newValue) {
        return di.regOfExactType(
          type: type,
          dependency: dep.reassign(newValue),
          suppressDependencyAlreadyRegisteredException: true,
        );
      }).thenOr((_) {
        return di.registry.removeDependencyOfExactType(
          type: genericType,
          group: group,
        );
      }).thenOr((_) {
        return di.getOfExactTypeInternal(
          type: type,
          group: group,
        );
      });
    }
    return null;
  }

  @protected
  @override
  void regOfExactType({
    required Descriptor type,
    required Dependency<Object> dependency,
    bool suppressDependencyAlreadyRegisteredException = false,
  }) {
    final group = dependency.group;
    final dep = registry.getDependencyOfExactTypeOrNull(
      type: type,
      group: group,
    );
    if (!suppressDependencyAlreadyRegisteredException && dep != null) {
      throw DependencyAlreadyRegisteredException(
        type: type,
        group: group,
      );
    }
    // Store the dependency in the type map.
    registry.setDependencyOfExactType(
      type: type,
      value: dependency,
    );
  }

  //
  //
  //

  @protected
  @override
  FutureOr<T>? getFactoryOrNull<T extends Object, P extends Object>(
    P params, {
    Descriptor? group,
  }) {
    return _execOrNull(
      (di) => _getFactoryOrNull<T, P>(
        di: di,
        params: params,
        group: group,
      ),
    );
  }

  static FutureOr<T>? _getFactoryOrNull<T extends Object, P extends Object>({
    required DI di,
    required P params,
    Descriptor? group,
  }) {
    final focusGroup = di.preferFocusGroup(group);
    final dep = di.registry.getDependencyOrNull<FactoryInst<T, P>>(
      group: focusGroup,
    );
    final casted = (dep?.value as FactoryInst?)?.cast<T, P>();
    final result = casted?.constructor(params);
    return result;
  }

  @protected
  @override
  FutureOr<Object>? getFactoryOfExactTypeOrNull({
    required Descriptor type,
    required Object params,
    Descriptor? group,
  }) {
    return _execOrNull(
      (di) => _getFactoryOfExactTypeOrNull(
        di: di,
        params: params,
        type: type,
        group: group,
      ),
    );
  }

  static FutureOr<Object>? _getFactoryOfExactTypeOrNull({
    required DI di,
    required Object params,
    required Descriptor type,
    Descriptor? group,
  }) {
    final focusGroup = di.preferFocusGroup(group);
    final dep = di.registry.getDependencyOfExactTypeOrNull(
      type: type,
      group: focusGroup,
    );
    final result = (dep?.value as FactoryInst?)?.constructor(params);
    return result;
  }

  //
  //
  //

  @protected
  @override
  Dependency<Object> removeDependency<T extends Object>({
    Descriptor? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final removers = [
      () => registry.removeDependency<T>(group: focusGroup),
      () => registry.removeDependency<FutureInst<T, Object>>(group: focusGroup),
      () => registry.removeDependency<SingletonInst<T, Object>>(group: focusGroup),
      () => registry.removeDependency<FactoryInst<T, Object>>(group: focusGroup),
    ];
    for (final remover in removers) {
      final dep = remover();
      if (dep != null) {
        return dep;
      }
    }
    throw DependencyNotFoundException(
      type: T,
      group: focusGroup,
    );
  }

  @protected
  @override
  Dependency<Object> removeDependencyOfExactType({
    required Descriptor type,
    required Descriptor paramsType,
    Descriptor? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final removers = _associatedTypes(type: type, paramsType: paramsType).map(
      (type) => () => registry.removeDependencyOfExactType(
            type: type,
            group: focusGroup,
          ),
    );
    for (final remover in removers) {
      final dep = remover();
      if (dep != null) {
        return dep;
      }
    }
    throw DependencyNotFoundException(
      type: type,
      group: focusGroup,
    );
  }

  //
  //
  //

  @protected
  @override
  Dependency<Object>? getDependencyOrNull<T extends Object>({
    Descriptor? group,
  }) {
    return _execOrNull(
      (di) => _getDependencyOrNull<T>(
        di: di,
        group: group,
      ),
    );
  }

  static Dependency<Object>? _getDependencyOrNull<T extends Object>({
    required DI di,
    required Descriptor? group,
  }) {
    final focusGroup = di.preferFocusGroup(group);
    final getters = [
      () => di.registry.getDependencyOrNull<T>(group: focusGroup),
      () => di.registry.getDependencyOrNull<FutureInst<T, Object>>(group: focusGroup),
      () => di.registry.getDependencyOrNull<SingletonInst<T, Object>>(group: focusGroup),
      () => di.registry.getDependencyOrNull<FactoryInst<T, Object>>(group: focusGroup),
    ];
    for (final getter in getters) {
      final dep = getter();
      if (dep != null) {
        return dep;
      }
    }
    return null;
  }

  @protected
  @override
  Dependency<Object>? getDependencyOfExactTypeOrNull({
    required Descriptor type,
    required Descriptor paramsType,
    Descriptor? group,
  }) {
    return _execOrNull(
      (di) => _getDependencyOfExactTypeOrNull(
        di: di,
        type: type,
        paramsType: paramsType,
        group: group,
      ),
    );
  }

  static Dependency<Object>? _getDependencyOfExactTypeOrNull({
    required DI di,
    required Descriptor type,
    required Descriptor paramsType,
    required Descriptor? group,
  }) {
    final focusGroup = di.preferFocusGroup(group);
    final getters = _associatedTypes(type: type, paramsType: paramsType).map(
      (type) => () => di.registry.getDependencyOfExactTypeOrNull(
            type: type,
            group: focusGroup,
          ),
    );
    for (final getter in getters) {
      final dep = getter();
      if (dep != null) {
        return dep;
      }
    }
    return null;
  }

  E? _execOrNull<E>(E? Function(DI di) tester) {
    for (final di in [this, parent as DI?].nonNulls) {
      final test = tester(di);
      if (test != null) {
        return test;
      }
    }
    return null;
  }

  //
  //
  //

  @override
  FutureOr<void> unregisterAll({
    void Function(Dependency<Object> dep)? onUnregister,
  }) {
    final foc = FutureOrController<void>();
    final dependencies =
        registry.state.values.fold(<Dependency<Object>>[], (buffer, e) => buffer..addAll(e.values));
    dependencies.sort((a, b) => b.registrationIndex.compareTo(a.registrationIndex));
    for (final dep in dependencies) {
      final a = dep.onUnregister;
      final b = onUnregister;
      foc.addAll([
        if (a != null) (_) => a(dep.value),
        if (b != null) (_) => b(dep),
      ]);
    }
    foc.add((_) => registry.clearRegistry());
    return foc.complete();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Iterable<Descriptor> _associatedTypes({
  required Descriptor type,
  required Descriptor paramsType,
}) {
  return [
    type,
    Descriptor.genericType<FutureInst>([type, paramsType]),
    Descriptor.genericType<SingletonInst>([type, paramsType]),
    Descriptor.genericType<FactoryInst>([type, paramsType]),
  ];
}
