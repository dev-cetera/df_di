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
import 'di_base.dart';

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

  /// Default global instance of the DI class.
  static final DI global = DI();

  /// The number of dependencies registered in this instance.
  int get length => _registrationCount;

  /// Tracks the registration count, assigning a unique index number to each
  /// registration.
  var _registrationCount = 0;

  /// Creates a new instance of the DI class. Prefer using [global], unless
  /// there's a specific need for a separate instance.
  DI();

  //
  //
  //

  @override
  void registerLazySingletonService<T extends Service>(
    Constructor<T> constructor, {
    Identifier key = Identifier.defaultId,
  }) {
    registerLazySingleton(
      () => constructor().thenOr((e) => e.initService().thenOr((_) => e)),
      key: key,
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
  void registerFactoryService<T extends Service>(
    Constructor<T> constructor, {
    Identifier key = Identifier.defaultId,
  }) {
    registerFactory(
      () => constructor().thenOr((e) => e.initService().thenOr((_) => e)),
      key: key,
    );
  }

  //
  //
  //

  @protected
  @override
  void registerOr<T extends Object, R extends Object>(
    FutureOr<T> value, {
    Identifier key = Identifier.defaultId,
    OnUnregisterCallback<R>? onUnregister,
  }) {
    if (value is T) {
      reg<T>(
        dependency: Dependency(
          value: value,
          registrationIndex: _registrationCount++,
          key: key,
          onUnregister: onUnregister != null ? (e) => e is R ? onUnregister(e) : null : null,
        ),
      );
    } else {
      reg<FutureInst<T>>(
        dependency: Dependency(
          value: FutureInst(() => value),
          registrationIndex: _registrationCount++,
          key: key,
          onUnregister: onUnregister != null ? (e) => e is R ? onUnregister(e) : null : null,
        ),
      );
    }
  }

  @protected
  @override
  void registerByExactTypeOr<T extends Object, R extends Object>(
    FutureOr<T> value, {
    Identifier key = Identifier.defaultId,
    OnUnregisterCallback<R>? onUnregister,
  }) {
    if (value is T) {
      regByExactType(
        type: Identifier.typeId(T),
        dependency: Dependency(
          value: value,
          registrationIndex: _registrationCount++,
          key: key,
          onUnregister: onUnregister != null ? (e) => e is R ? onUnregister(e) : null : null,
        ),
      );
    } else {
      regByExactType(
        type: Identifier.typeId(FutureInst<T>),
        dependency: Dependency(
          value: FutureInst(() => value),
          registrationIndex: _registrationCount++,
          key: key,
          onUnregister: onUnregister != null ? (e) => e is R ? onUnregister(e) : null : null,
        ),
      );
    }
  }

  //
  //
  //

  @protected
  @override
  FutureOr<T> get<T extends Object>({
    Identifier key = Identifier.defaultId,
  }) {
    // Sync types.
    {
      final dep = registry.getDependency<T>(
        key: key,
      );
      if (dep != null) {
        final res = dep.value;
        return res;
      }
    }
    // Factory types.
    {
      final res = getFactoryOrNull<T>(
        key: key,
      );
      if (res != null) {
        return res;
      }
    }

    // Future types.
    {
      final res = _inst<T, FutureInst<T>>(
        key: key,
      );
      if (res != null) {
        return res;
      }
    }
    // Singleton types.
    {
      final res = _inst<T, SingletonInst<T>>(
        key: key,
      );
      if (res != null) {
        return res;
      }
    }

    throw DependencyNotFoundException(
      type: T,
      key: key,
    );
  }

  FutureOr<T>? _inst<T extends Object, TInst extends Inst<T>>({
    required Identifier key,
  }) {
    final dep = registry.getDependency<TInst>(
      key: key,
    );
    if (dep != null) {
      final value = dep.value;
      return value.thenOr((value) {
        return value.constructor();
      }).thenOr((newValue) {
        return reg<T>(
          dependency: dep.reassign(newValue),
          suppressDependencyAlreadyRegisteredException: true,
        );
      }).thenOr((_) {
        return registry.removeDependency<TInst>(
          key: key,
        );
      }).thenOr((_) {
        return get<T>(
          key: key,
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
    final dep = registry.getDependency<T>(
      key: dependency.key,
    );
    if (!suppressDependencyAlreadyRegisteredException && dep != null) {
      throw DependencyAlreadyRegisteredException(
        type: T,
        key: dependency.key,
      );
    }
    // Store the dependency in the type map.
    registry.setDependency<T>(
      dep: dependency,
    );
  }

  //
  //
  //

  @protected
  @override
  FutureOr<Object> getByExactType({
    required Identifier type,
    Identifier key = Identifier.defaultId,
  }) {
    // Sync types.
    {
      final dep = registry.getDependencyByExactType(
        type: type,
        key: key,
      );
      if (dep != null) {
        final res = dep.value;
        return res;
      }
    }
    // Factory types.
    {
      final genericType = Identifier.genericTypeId<FactoryInst>([type]);
      final res = getFactoryByExactTypeOrNull(
        type: genericType,
        key: key,
      );
      if (res != null) {
        return res;
      }
    }

    // Future types.
    {
      final genericType = Identifier.genericTypeId<FutureInst>([type]);
      final res = _instExactType(
        type: type,
        genericType: genericType,
        key: key,
      );
      if (res != null) {
        return res;
      }
    }
    // Singleton types.
    {
      final genericType = Identifier.genericTypeId<SingletonInst>([type]);
      final res = _instExactType(
        type: type,
        genericType: genericType,
        key: key,
      );
      if (res != null) {
        return res;
      }
    }

    throw DependencyNotFoundException(
      type: type,
      key: key,
    );
  }

  FutureOr<Object>? _instExactType({
    required Identifier type,
    required Identifier genericType,
    required Identifier key,
  }) {
    final dep = registry.getDependencyByExactType(
      type: genericType,
      key: key,
    );
    if (dep != null) {
      final value = dep.value;
      return value.thenOr((value) {
        return (value as Inst).constructor();
      }).thenOr((newValue) {
        return regByExactType(
          type: type,
          dependency: dep.reassign(newValue),
          suppressDependencyAlreadyRegisteredException: true,
        );
      }).thenOr((_) {
        return registry.removeDependencyByExactType(
          type: genericType,
          key: key,
        );
      }).thenOr((_) {
        return getByExactType(
          type: type,
          key: key,
        );
      });
    }
    return null;
  }

  @protected
  @override
  void regByExactType({
    required Identifier type,
    required Dependency<Object> dependency,
    bool suppressDependencyAlreadyRegisteredException = false,
  }) {
    final dep = registry.getDependencyByExactType(
      type: type,
      key: dependency.key,
    );
    if (!suppressDependencyAlreadyRegisteredException && dep != null) {
      throw DependencyAlreadyRegisteredException(
        type: type,
        key: dependency.key,
      );
    }
    // Store the dependency in the type map.
    registry.setDependencyByExactType(
      type: type,
      dep: dependency,
    );
  }

  //
  //
  //

  @protected
  @override
  FutureOr<T>? getFactoryOrNull<T extends Object>({
    Identifier key = Identifier.defaultId,
  }) {
    final dep = registry.getDependency<T>(
      key: key,
    );
    final result = (dep?.value as FactoryInst<T>?)?.constructor();
    return result;
  }

  @protected
  @override
  FutureOr<Object>? getFactoryByExactTypeOrNull({
    required Identifier type,
    Identifier key = Identifier.defaultId,
  }) {
    final dep = registry.getDependencyByExactType(
      type: type,
      key: key,
    );
    final result = (dep?.value as FactoryInst?)?.constructor();
    return result;
  }

  //
  //
  //

  @protected
  @override
  Dependency<Object> removeDependency<T extends Object>({
    Identifier key = Identifier.defaultId,
  }) {
    final removers = [
      () => registry.removeDependency<T>(key: key),
      () => registry.removeDependency<FutureInst<T>>(key: key),
      () => registry.removeDependency<SingletonInst<T>>(key: key),
      () => registry.removeDependency<FactoryInst<T>>(key: key),
    ];
    for (final remover in removers) {
      final dep = remover();
      if (dep != null) {
        return dep;
      }
    }
    throw DependencyNotFoundException(
      type: T,
      key: key,
    );
  }

  @protected
  @override
  Dependency<Object> removeDependencyByExactType({
    required Identifier type,
    Identifier<Object> key = Identifier.defaultId,
  }) {
    final removers = _associatedTypes(type: type).map(
      (type) => () => registry.removeDependencyByExactType(
            type: type,
            key: key,
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
      key: key,
    );
  }

  //
  //
  //

  @protected
  @override
  Dependency<Object>? getDependencyOrNull<T extends Object>({
    Identifier<Object> key = Identifier.defaultId,
  }) {
    final getters = [
      () => registry.getDependency<T>(key: key),
      () => registry.getDependency<FutureInst<T>>(key: key),
      () => registry.getDependency<SingletonInst<T>>(key: key),
      () => registry.getDependency<FactoryInst<T>>(key: key),
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
  Dependency<Object>? getDependencyByExactTypeOrNull({
    required Identifier type,
    Identifier<Object> key = Identifier.defaultId,
  }) {
    final getters = _associatedTypes(type: type).map(
      (type) => () => registry.getDependencyByExactType(
            type: type,
            key: key,
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

Iterable<Identifier> _associatedTypes({
  required Identifier type,
}) {
  return [
    type,
    Identifier.genericTypeId<FutureInst>([type]),
    Identifier.genericTypeId<SingletonInst>([type]),
    Identifier.genericTypeId<FactoryInst>([type]),
  ];
}
