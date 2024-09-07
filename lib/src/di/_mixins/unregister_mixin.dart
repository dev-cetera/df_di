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

import '/src/_internal.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
base mixin UnregisterMixin on DIBase implements UnregisterInterface {
  @override
  FutureOr<void> unregisterAll({
    void Function(Dependency<Object> dependency)? onUnregister,
  }) {
    final foc = FutureOrController<void>();
    final dependencies =
        registry.state.values.fold(<Dependency<Object>>[], (buffer, e) => buffer..addAll(e.values));
    dependencies.sort((a, b) => b.metadata.index.compareTo(a.metadata.index));
    for (final dependency in dependencies) {
      final a = dependency.metadata.onUnregister;
      final b = onUnregister;
      foc.addAll([
        if (a != null) (_) => a(dependency.value),
        if (b != null) (_) => b(dependency),
      ]);
    }
    foc.add((_) => registry.clearRegistry());
    return foc.complete();
  }

  @override
  FutureOr<void> unregister<T extends Object>({
    DIKey? typeGroup,
  }) {
    return unregisterUsingExactType(
      type: DIKey(T),
      paramsType: DIKey(Object),
      typeGroup: typeGroup,
    );
  }

  @protected
  @override
  FutureOr<void> unregisterUsingExactType({
    required DIKey type,
    DIKey? paramsType,
    DIKey? typeGroup,
  }) {
    final dep = removeDependencyUsingExactType(
      type: type,
      paramsType: paramsType,
      typeGroup: typeGroup,
    );
    return dep.metadata.onUnregister?.call(dep.value);
  }

  @override
  FutureOr<void> unregisterUsingRuntimeType(
    Type type, {
    DIKey? paramsType,
    DIKey? typeGroup,
  }) {
    return unregisterUsingExactType(
      type: DIKey(type),
      paramsType: paramsType,
      typeGroup: typeGroup,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
abstract interface class UnregisterInterface {
  /// Unregisters all dependencies in the reverse order of their registration,
  /// effectively resetting this instance of [DI].
  FutureOr<void> unregisterAll({
    void Function(Dependency<Object> dependency)? onUnregister,
  });

  /// Unregisters a dependency registered under type [T] and the
  /// specified [typeGroup], or under [DIKey.defaultGroup] if no typeGroup is provided.
  ///
  /// - Throws [DependencyNotFoundException] if the dependency is not found.
  FutureOr<void> unregister<T extends Object>({
    DIKey? typeGroup,
  });

  FutureOr<void> unregisterUsingExactType({
    required DIKey type,
    DIKey? paramsType,
    DIKey? typeGroup,
  });

  FutureOr<void> unregisterUsingRuntimeType(
    Type type, {
    DIKey? paramsType,
    DIKey? typeGroup,
  });
}
