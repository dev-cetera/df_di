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

import '_index.g.dart';

import '_utils/dependency.dart';
import '_utils/type_safe_registry.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Shorthand for [DI.global].
DI get di => DI.global;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A simple Dependencu Injection (DI) class for managing dependencies across
/// an application.
class DI {
  //
  //
  //

  /// Dependency registry.
  final registry = TypeSafeRegistry();

  /// Default global instance of the DI class.
  static final DI global = DI.newInstance();

  /// Creates a new instance of the DI class. Prefer using [global], unless
  /// there's a specific need for a separate instance.
  DI.newInstance();

  /// Registers the [dependency] under type [T] and the specified [key], or
  /// under [DIKey.defaultKey] if no key is provided.
  ///
  /// Optionally provide an [onUnregister] callback to be called on [unregister].
  ///
  /// Throws [DependencyAlreadyRegisteredException] if a dependency with the
  /// same type [T] and [key] already exists.
  void register<T>(
    FutureOr<T> dependency, {
    DIKey key = DIKey.defaultKey,
    UnregisterDependencyCallback<T>? onUnregister,
  }) {
    if (dependency is T) {
      _register<T>(
        dependency,
        key: key,
        onUnregister: _unregToDynamic(onUnregister),
      );
    } else {
      _register<Future<T>>(
        dependency,
        key: key,
        onUnregister: _unregToDynamic(onUnregister),
      );
    }
  }

  /// Registers the [instantiator] function under type [T] and the specified
  /// [key], or under [DIKey.defaultKey] if no key is provided.
  ///
  /// The dependency will be instantiated via [instantiator] when and only when
  /// accessed for the first time.
  ///
  /// Optionally provide an [onUnregister] callback to be called on [unregister].
  ///
  /// Throws [DependencyAlreadyRegisteredException] if a dependency with the
  /// same type [T] and [key] already exists.
  void registerLazy<T>(
    _Instantiator<T> instantiator, {
    DIKey key = DIKey.defaultKey,
    UnregisterDependencyCallback<T>? onUnregister,
  }) {
    if (instantiator is T Function()) {
      _register<T Function()>(
        instantiator,
        key: key,
        onUnregister: _unregToDynamic(onUnregister),
      );
    } else if (instantiator is Future<T> Function()) {
      _register<Future<T> Function()>(
        instantiator,
        key: key,
        onUnregister: _unregToDynamic(onUnregister),
      );
    }
  }

  void _register<T>(
    T dependency, {
    DIKey key = DIKey.defaultKey,
    UnregisterDependencyCallback<T>? onUnregister,
  }) {
    final existingDependencies = registry.getAllDependenciesOfType<T>();
    final depMap = {for (var dep in existingDependencies) dep.key: dep};

    // Check if the dependency is already registered.
    if (depMap.containsKey(key)) {
      throw DependencyAlreadyRegisteredException(T, key);
    }

    // Store the dependency in the type map.
    final newDependency = Dependency<T>(
      dependency,
      key: key,
      unregister: onUnregister,
    );
    registry.setDependency<T>(key, newDependency);
  }

  /// A shorthand for [get], allowing you to retrieve a dependency using call
  /// syntax.
  T call<T>([
    DIKey key = DIKey.defaultKey,
  ]) {
    return get<T>() as T;
  }

  /// Calls [get] and returns the instance of type [T] if found, otherwise
  /// returns `null`.
  T? getOrNull<T>([
    DIKey key = DIKey.defaultKey,
  ]) {
    try {
      return get<T>(key) as T;
    } on DependencyNotFoundException {
      return null;
    }
  }

  /// Gets a dependency as a [Future] or [T], registered under type [T] and the
  /// specified [key], or under [DIKey.defaultKey] if no key is provided.
  ///
  /// If the dependency was registered lazily via [registerLazy] and is not yet
  /// instantiated, it will be instantiated. Subsequent calls  of [get] will
  /// return the already instantiated instance.
  ///
  /// - Throws [DependencyNotFoundException] if the requested dependency cannot be found.
  /// - Throws [FutureTypeNotAllowedException] if [T] is a [Future]. Use a non-future type instead.
  /// - Throws [FunctionTypeNotAllowedException] if [T] is a [Function]. Use a non-function type instead.
  FutureOr<T> get<T>([
    DIKey key = DIKey.defaultKey,
  ]) {
    final try1 = registry.getDependency<T>(key);
    if (try1 != null) {
      final dependency = try1.dependency;
      return dependency;
    }

    final try2 = registry.getDependency<Future<T>>(key);
    if (try2 != null) {
      final dependency = try2.dependency;
      dependency.then((e) async {
        await unregister<Future<T>>(key);
        _register<T>(
          e,
          key: key,
          onUnregister: _unregToDynamic(try2.unregister),
        );
      });
      return dependency;
    }

    final try3 = registry.getDependency<T Function()>(key);
    if (try3 != null) {
      final instantiator = try3.dependency;
      final dependency = instantiator();
      final unreg = unregister<T Function()>(key);
      reg() => _register<T>(
            dependency,
            key: key,
            onUnregister: _unregToDynamic(try3.unregister),
          );
      if (unreg is Future<void>) {
        unreg.then((_) => reg());
      } else {
        reg();
      }
      return dependency;
    }

    final try4 = registry.getDependency<Future<T> Function()>(key);
    if (try4 != null) {
      final instantiator = try4.dependency;
      final dependency = instantiator();
      final unreg = unregister<Future<T> Function()>(key);
      reg() => register<T>(
            dependency,
            key: key,
            onUnregister: _unregToDynamic(try4.unregister),
          );
      if (unreg is Future<void>) {
        unreg.then((_) => reg());
      } else {
        reg();
      }
      dependency.then((e) async {
        await unregister<T>(key);
        _register<T>(
          e,
          key: key,
          onUnregister: _unregToDynamic(try4.unregister),
        );
      });
      return dependency;
    }

    throw DependencyNotFoundException(T, key);
  }

  /// Unregisters a dependency registered under type [T] and the
  /// specified [key], or under [DIKey.defaultKey] if no key is provided.
  ///
  /// - Throws [DependencyNotFoundException] if the dependency is not found.
  /// - Throws [FutureTypeNotAllowedException] if [T] is a [Future]. Use a non-future type instead.
  /// - Throws [FunctionTypeNotAllowedException] if [T] is a [Function]. Use a non-function type instead.
  FutureOr<void> unregister<T>([
    DIKey key = DIKey.defaultKey,
  ]) {
    final a = registry.removeDependency<T>(key);
    if (a != null) return a.unregister?.call(a.dependency);
    final b = registry.removeDependency<Future<T>>(key);
    if (b != null) return b.unregister?.call(b.dependency);
    final c = registry.removeDependency<T Function()>(key);
    if (c != null) return c.unregister?.call(c.dependency);
    final d = registry.removeDependency<Future<T> Function()>(key);
    if (d != null) return d.unregister?.call(d.dependency);
    throw DependencyNotFoundException(T, key);
  }

  Dependency<dynamic> getDependency<T>([
    DIKey key = DIKey.defaultKey,
  ]) {
    final a = registry.removeDependency<T>(key);
    if (a != null) return a;
    final b = registry.removeDependency<Future<T>>(key);
    if (b != null) return b;
    final c = registry.removeDependency<T Function()>(key);
    if (c != null) return c;
    final d = registry.removeDependency<Future<T> Function()>(key);
    if (d != null) return d;
    throw DependencyNotFoundException(T, key);
  }

  /// Clears all registered dependencies, calling the [unregister] callback for
  /// each one before removal.
  void clear() {
    for (var depMap in registry.pRegistry.value.values) {
      for (var dependency in depMap.values) {
        dependency.unregister?.call(dependency.dependency);
      }
    }
    registry.clearRegistry();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Exception thrown when attempting to register a dependency that is already registered.
final class DependencyAlreadyRegisteredException extends DFDIPackageException {
  DependencyAlreadyRegisteredException(Type type, DIKey key)
      : super('Dependency of type $type with key $key is already registered.');
}

/// Exception thrown when a requested dependency is not found.
final class DependencyNotFoundException extends DFDIPackageException {
  DependencyNotFoundException(Type type, DIKey key)
      : super('Dependency of type $type with key "$key" not found.');
}

final class FutureTypeNotAllowedException extends DFDIPackageException {
  FutureTypeNotAllowedException(Type type)
      : super(
          'Future types like  $type not allowed with "get" or "unregister".',
        );
}

final class FunctionTypeNotAllowedException extends DFDIPackageException {
  FunctionTypeNotAllowedException(Type type)
      : super(
          'Function types like $type not allowed with "get" or "unregister".',
        );
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

UnregisterDependencyCallback<dynamic>? _unregToDynamic<T>(UnregisterDependencyCallback<T>? other) {
  return other != null
      ? (dynamic dependency) async {
          await other(dependency as FutureOr<T>);
        }
      : null;
}

typedef _Instantiator<T> = FutureOr<T> Function();
