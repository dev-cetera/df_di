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

import 'package:meta/meta.dart' show internal;
import 'package:collection/collection.dart' show MapEquality;

import '/src/_index.g.dart';
import '/src/utils/_dependency.dart';

import 'type_safe_registry_base.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A type-safe registry for storing and managing dependencies of various types
/// within [DI]. This class provides methods for adding, retrieving, updating,
/// and removing dependencies, as well as checking if a specific dependency
/// exists.
@internal
final class TypeSafeRegistry extends TypeSafeRegistryBase {
  //
  //
  //

  /// Dependencies, organized by their type.
  final _state = TypeSafeRegistryMap();

  void Function(TypeSafeRegistryMap state) onUpdate = (_) {};

  /// A snapshot describing the current state of the dependencies.
  TypeSafeRegistryMap get state =>
      Map<Identifier, Map<Identifier, Dependency<Object>>>.unmodifiable(_state)
          .map((k, v) => MapEntry(k, Map.unmodifiable(v)));

  @override
  @pragma('vm:prefer-inline')
  Dependency<Object>? getDependencyByExactType({
    required Identifier type,
    required Identifier key,
  }) {
    return _state[key]?[type];
  }

  @override
  Iterable<Dependency<Object>> getDependenciesByKey({
    required Identifier key,
  }) {
    return _state.entries
        .expand((entry) => entry.value.values.where((dependency) => dependency.key == key))
        .cast<Dependency<Object>>();
  }

  @override
  void setDependencyByExactType({
    required Identifier type,
    required Dependency<Object> dep,
  }) {
    final key = dep.key;
    final prev = _state[key]?[type];
    if (prev != dep) {
      (_state[key] ??= {})[type] = dep;
      onUpdate(_state);
    }
  }

  @override
  Dependency<Object>? removeDependencyByExactType({
    required Identifier type,
    required Identifier key,
  }) {
    final value = getDependencyMapByKey(key: key);
    if (value != null) {
      final dep = value.remove(key);
      if (value.isEmpty) {
        removeDependencyMapByExactType(type: type);
      } else {
        setDependencyMapByKey(
          key: key,
          value: value,
        );
      }
      return dep;
    }
    return null;
  }

  @override
  void setDependencyMapByKey({
    required Identifier key,
    required DependencyMap value,
  }) {
    final prev = _state[key];
    final equals = const MapEquality<Identifier, Dependency<Object>>().equals(prev, value);
    if (!equals) {
      _state[key] = value;
      onUpdate(_state);
    }
  }

  @override
  @pragma('vm:prefer-inline')
  DependencyMap<Object>? getDependencyMapByKey({
    required Identifier key,
  }) {
    return _state[key];
  }

  @override
  @pragma('vm:prefer-inline')
  void removeDependencyMapByExactType({
    required Identifier type,
  }) {
    _state.remove(type);
    onUpdate(_state);
  }

  @override
  @pragma('vm:prefer-inline')
  void clearRegistry() => _state.clear();
}
