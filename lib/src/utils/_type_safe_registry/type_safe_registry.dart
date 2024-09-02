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
    return _state[type]?[key];
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
    required Identifier key,
    required Dependency<Object> dep,
  }) {
    final prev = _state[type]?[key];
    if (prev != dep) {
      (_state[type] ??= {})[key] = dep;
      onUpdate(_state);
    }
  }

  @override
  Dependency<Object>? removeDependencyByExactType({
    required Identifier type,
    required Identifier key,
  }) {
    final value = getDependencyMapByExactType(type: type);
    if (value != null) {
      final dep = value.remove(key);
      if (value.isEmpty) {
        removeDependencyMapByExactType(type: type);
      } else {
        setDependencyMapByExactType(
          type: type,
          value: value,
        );
      }
      return dep;
    }
    return null;
  }

  @override
  void setDependencyMapByExactType({
    required Identifier type,
    required DependencyMap value,
  }) {
    final prev = _state[type];
    final equals = const MapEquality<Identifier, Dependency<Object>>().equals(prev, value);
    if (!equals) {
      _state[type] = value;
      onUpdate(_state);
    }
  }

  @override
  @pragma('vm:prefer-inline')
  DependencyMap<Object>? getDependencyMapByExactType({
    required Identifier type,
  }) {
    return _state[type];
  }

  @override
  void removeDependencyMap<T extends Object>();

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

  @override
  MapEntry<Identifier, DependencyMap<T>>? getDepMapEntry<T extends Object>() {
    final entry = _state.entries.where((e) => e.key.value is T).firstOrNull;
    if (entry != null) {
      return MapEntry(
        entry.key,
        entry.value.cast(),
      );
    }
    return null;
  }
}
