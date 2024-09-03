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

  /// Default global group.
  static final DI global = DI();

  /// Default session group.
  static final DI session = DI();

  /// The number of dependencies registered in this instance.
  int get length => _registrationCount;

  /// Tracks the registration count, assigning a unique index number to each
  /// registration.
  var _registrationCount = 0;

  /// Creates a new instance of the DI class. Prefer using [global], unless
  /// there's a specific need for a separate instance.
  DI({super.focusGroup});

  //
  //
  //

  @override
  void registerLazySingletonService<T extends Service>(
    Constructor<T> constructor, {
    Identifier? group,
  }) {
    registerLazySingleton(
      () => constructor().thenOr((e) => e.initService().thenOr((_) => e)),
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
  void registerFactoryService<T extends Service>(
    Constructor<T> constructor, {
    Identifier? group,
  }) {
    registerFactory(
      () => constructor().thenOr((e) => e.initService().thenOr((_) => e)),
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
    Identifier? group,
    OnUnregisterCallback<R>? onUnregister,
  }) {
    final focusGroup = preferFocusGroup(group);
    if (value is T) {
      reg<T>(
        dependency: Dependency(
          value: value,
          registrationIndex: _registrationCount++,
          group: focusGroup,
          onUnregister: onUnregister != null ? (e) => e is R ? onUnregister(e) : null : null,
        ),
      );
    } else {
      reg<FutureInst<T>>(
        dependency: Dependency(
          value: FutureInst(() => value),
          registrationIndex: _registrationCount++,
          group: focusGroup,
          onUnregister: onUnregister != null ? (e) => e is R ? onUnregister(e) : null : null,
        ),
      );
    }
  }

  @protected
  @override
  void registerOfExactTypeOr<T extends Object, R extends Object>(
    FutureOr<T> value, {
    Identifier? group,
    OnUnregisterCallback<R>? onUnregister,
  }) {
    final focusGroup = preferFocusGroup(group);
    if (value is T) {
      regOfExactType(
        type: Identifier.typeId(T),
        dependency: Dependency(
          value: value,
          registrationIndex: _registrationCount++,
          group: focusGroup,
          onUnregister: onUnregister != null ? (e) => e is R ? onUnregister(e) : null : null,
        ),
      );
    } else {
      regOfExactType(
        type: Identifier.typeId(FutureInst<T>),
        dependency: Dependency(
          value: FutureInst(() => value),
          registrationIndex: _registrationCount++,
          group: focusGroup,
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
    Identifier? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    // Sync types.
    {
      final dep = registry.getDependencyOrNull<T>(
        group: focusGroup,
      );
      if (dep != null) {
        final res = dep.value;
        return res;
      }
    }
    // Factory types.
    {
      final res = getFactoryOrNull<T>(
        group: focusGroup,
      );
      if (res != null) {
        return res;
      }
    }

    // Future types.
    {
      final res = _inst<T, FutureInst<T>>(
        group: focusGroup,
      );
      if (res != null) {
        return res;
      }
    }
    // Singleton types.
    {
      final res = _inst<T, SingletonInst<T>>(
        group: focusGroup,
      );
      if (res != null) {
        return res;
      }
    }

    throw DependencyNotFoundException(
      type: T,
      group: focusGroup,
    );
  }

  FutureOr<T>? _inst<T extends Object, TInst extends Inst<T>>({
    Identifier? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final dep = registry.getDependencyOrNull<TInst>(
      group: focusGroup,
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
          group: focusGroup,
        );
      }).thenOr((_) {
        return get<T>(
          group: focusGroup,
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
  FutureOr<Object> getOfExactType({
    required Identifier type,
    Identifier? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    // Sync types.
    {
      final dep = registry.getDependencyOfExactTypeOrNull(
        type: type,
        group: focusGroup,
      );
      if (dep != null) {
        final res = dep.value;
        return res;
      }
    }
    // Factory types.
    {
      final genericType = Identifier.genericTypeId<FactoryInst>([type]);
      final res = getFactoryOfExactTypeOrNull(
        type: genericType,
        group: focusGroup,
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
        group: focusGroup,
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
        group: focusGroup,
      );
      if (res != null) {
        return res;
      }
    }

    throw DependencyNotFoundException(
      type: type,
      group: focusGroup,
    );
  }

  FutureOr<Object>? _instExactType({
    required Identifier type,
    required Identifier genericType,
    Identifier? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final dep = registry.getDependencyOfExactTypeOrNull(
      type: genericType,
      group: focusGroup,
    );
    if (dep != null) {
      final value = dep.value;
      return value.thenOr((value) {
        return (value as Inst).constructor();
      }).thenOr((newValue) {
        return regOfExactType(
          type: type,
          dependency: dep.reassign(newValue),
          suppressDependencyAlreadyRegisteredException: true,
        );
      }).thenOr((_) {
        return registry.removeDependencyOfExactType(
          type: genericType,
          group: focusGroup,
        );
      }).thenOr((_) {
        return getOfExactType(
          type: type,
          group: focusGroup,
        );
      });
    }
    return null;
  }

  @protected
  @override
  void regOfExactType({
    required Identifier type,
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
  FutureOr<T>? getFactoryOrNull<T extends Object>({
    Identifier? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final dep = registry.getDependencyOrNull<T>(
      group: focusGroup,
    );
    final result = (dep?.value as FactoryInst<T>?)?.constructor();
    return result;
  }

  @protected
  @override
  FutureOr<Object>? getFactoryOfExactTypeOrNull({
    required Identifier type,
    Identifier? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final dep = registry.getDependencyOfExactTypeOrNull(
      type: type,
      group: focusGroup,
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
    Identifier? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final removers = [
      () => registry.removeDependency<T>(group: focusGroup),
      () => registry.removeDependency<FutureInst<T>>(group: focusGroup),
      () => registry.removeDependency<SingletonInst<T>>(group: focusGroup),
      () => registry.removeDependency<FactoryInst<T>>(group: focusGroup),
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
    required Identifier type,
    Identifier? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final removers = _associatedTypes(type: type).map(
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
    Identifier? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final getters = [
      () => registry.getDependencyOrNull<T>(group: focusGroup),
      () => registry.getDependencyOrNull<FutureInst<T>>(group: focusGroup),
      () => registry.getDependencyOrNull<SingletonInst<T>>(group: focusGroup),
      () => registry.getDependencyOrNull<FactoryInst<T>>(group: focusGroup),
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
    required Identifier type,
    Identifier? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final getters = _associatedTypes(type: type).map(
      (type) => () => registry.getDependencyOfExactTypeOrNull(
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
