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

import '../utils/_type_safe_registry/type_safe_registry.dart';
import '/src/_index.g.dart';
import '/src/utils/_dependency.dart';
import '_di_parts/child/child_inter.dart';
import '_di_parts/debug/debug_inter.dart';
import '_di_parts/focus_group/focus_group_inter.dart';
import '_di_parts/get/get_inter.dart';
import '_di_parts/get_using_exact_type/get_using_exact_type_inter.dart';
import '_di_parts/get_dependency/get_dependency_inter.dart';
import '_di_parts/get_factory/get_factory_inter.dart';
import '_di_parts/is_registered/is_registered_inter.dart';
import '_di_parts/register_dependency/register_dependency_inter.dart';
import '_di_parts/remove_dependency/remove_dependency_inter.dart';
import '_di_parts/unregister/unregister_inter.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract base class DIBase
    implements
        ChildInter,
        FocusGroupInter,
        UnregisterInter,
        DebugInter,
        GetDependencyInter,
        RemoveDependencyInter,
        IsRegisteredInter,
        GetFactoryInter,
        GetInter,
        GetUsingExactTypeInter,
        RegisterDependencyInter {
  /// A type-safe registry that stores all dependencies.
  @protected
  final registry = TypeSafeRegistry();
  //
  //
  //

  @protected
  E? getFirstNonNull<E>({
    required DIBase? child,
    required DIBase? parent,
    required E? Function(DI di) test,
  }) {
    for (final di in [child, parent].nonNulls) {
      final result = test(di as DI);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  final DIBase? parent;

  @override
  Descriptor focusGroup;

  DIBase({Descriptor? focusGroup = Descriptor.defaultGroup, this.parent})
      : focusGroup = focusGroup ?? Descriptor.defaultGroup;

  /// Registers a [Service] as a singleton. When [get] is first called
  /// with [T] and [group], [DI] creates, initializes, and returns a new instance
  /// of [T]. All subsequent calls to [get] return the same instance.
  ///
  /// ```dart
  /// // Example:
  /// di.initSingletonService(FooBarService.new);
  /// final fooBarService1 = di.get<FooBarService>();
  /// final fooBarService2 = di.get<FooBarService>();
  /// print(fooBarService1 == fooBarService2); // true
  /// ```
  void registerLazySingletonService<T extends Service>(
    Constructor<T> constructor, {
    Descriptor? group,
  });

  /// Registers a [Service] as a factory. Each time [get] is called
  /// with T] and [group], [DI] creates, initializes, and returns a new instance
  /// of [T].
  ///
  /// ```dart
  /// // Example:
  /// di.registerFactoryService(FooBarService.new);
  /// final fooBarService1 = di.get<FooBarService>();
  /// final fooBarService2 = di.get<FooBarService>();
  /// print(fooBarService1 == fooBarService2); // false
  /// ```
  void registerFactoryService<T extends Service, P extends Object>(
    Constructor<T> constructor, {
    Descriptor? group,
  });

  /// Registers a singleton instance of [T] with the given [constructor]. When
  /// [get] is called with [T] and [group], the same instance will be returned.
  ///
  /// ```dart
  /// di.registerSingleton(FooBarService.new);
  /// final fooBarService1 = di.get<FooBarService>();
  /// final fooBarService2 = di.get<FooBarService>();
  /// print(fooBarService1 == fooBarService2); // true
  /// ```
  @pragma('vm:prefer-inline')
  void registerLazySingleton<T extends Object, P extends Object>(
    InstConstructor<T, P> constructor, {
    Descriptor? group,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    registerOr(
      SingletonInst<T, P>(constructor),
      group: group,
      onUnregister: onUnregister,
    );
  }

  /// Registers a factory that creates a new instance of [T] each time [get] is
  /// called with [T] and [group].
  ///
  /// ```dart
  /// di.registerFactory(FooBarService.new);
  /// final fooBarService1 = di.get<FooBarService>();
  /// final fooBarService2 = di.get<FooBarService>();
  /// print(fooBarService1 == fooBarService2); // false
  /// ```
  @pragma('vm:prefer-inline')
  void registerFactory<T extends Object, P extends Object>(
    InstConstructor<T, P> constructor, {
    Descriptor? group,
  }) {
    registerOr(
      FactoryInst<T, P>(constructor),
      group: group,
    );
  }

  /// Registers the [value] under type [T] and the specified [group], or
  /// under [Descriptor.defaultId] if no group is provided.
  ///
  /// Optionally provide an [onUnregister] callback to be called on [unregister].
  ///
  /// Throws [DependencyAlreadyRegisteredException] if a dependency with the
  /// same type [T] and [group] already exists.
  ///
  /// Consider passing [FactoryInst] or [SingletonInst] as the [value]. These
  /// types trigger a special behavious witin this class:
  ///
  /// - [FactoryInst] Creates a new instance each time [get] is called.
  /// - [SingletonInst] Creates a single instance the first time [get] is called
  /// and returns the same instance for all subsequent calls.
  ///
  /// Consider the following example:
  ///
  /// ```dart
  /// // Example.
  ///  var i = 0;
  ///  di.register(i);
  ///  i++;
  ///  print(di.get<int>()); // prints 0
  ///  di.unregister<int>();
  ///  di.register(SingletonInst<int>(() => ++i));
  ///  print(di.get<int>()); // prints 2
  ///  print(di.get<int>()); // prints 2 again
  ///  di.unregister<int>();
  ///  di.register(Factory<int>(() => ++i));
  ///  print(di.get<int>()); // prints 3
  ///  print(di.get<int>()); // prints 4
  ///  print(di.get<int>()); // prints 5
  /// ```
  void register<T extends Object>(
    FutureOr<T> value, {
    Descriptor? group,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    registerOr(
      value,
      group: group,
      onUnregister: onUnregister,
    );
  }

  /// ...
  @protected
  void registerOr<T extends Object, R extends Object>(
    FutureOr<T> value, {
    Descriptor? group,
    OnUnregisterCallback<R>? onUnregister,
  });

  /// ...
  @protected
  void registerUsingExactTypeOr<T extends Object, E extends Object>(
    FutureOr<T> value, {
    Descriptor? group,
    OnUnregisterCallback<E>? onUnregister,
  });




}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Exception thrown when attempting to register a dependency that is already registered.
final class DependencyAlreadyRegisteredException extends DFDIPackageException {
  DependencyAlreadyRegisteredException({
    required Object type,
    required Descriptor group,
  }) : super('Dependency of type $type in group $group is already registered.');
}

/// Exception thrown when a requested dependency is not found.
final class DependencyNotFoundException extends DFDIPackageException {
  DependencyNotFoundException({
    required Object type,
    required Descriptor group,
  }) : super('Dependency of type $type in group "$group" not found.');
}
