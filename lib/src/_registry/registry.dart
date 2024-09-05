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

/// A type-safe registry for storing and managing dependencies of various types
/// within [DI]. This class provides methods for adding, retrieving, updating,
/// and removing dependencies, as well as checking if a specific dependency
/// exists.
@internal
final class Registry extends RegistryBase {
  //
  //
  //

  /// Dependencies, organized by their type.
  final _state = RegistryMap();

  @protected
  void Function(RegistryMap state) onUpdate = (_) {};

  /// A snapshot describing the current state of the dependencies.
  RegistryMap get state => Map<Gr, Map<Gr, Dependency<Object>>>.unmodifiable(_state)
      .map((k, v) => MapEntry(k, Map.unmodifiable(v)));

  /// A snapshot of the current groups.
  Iterable<Gr> get groups => state.keys;

  @protected
  @override
  @pragma('vm:prefer-inline')
  Dependency<Object>? getDependencyUsingExactTypeOrNull({
    required Gr type,
    required Gr group,
  }) {
    return _state[group]?[type];
  }

  @protected
  @override
  Iterable<Dependency<Object>> getDependenciesByKey({
    required Gr group,
  }) {
    return _state.entries
        .expand(
          (entry) => entry.value.values.where((dependency) => dependency.group == group),
        )
        .cast<Dependency<Object>>();
  }

  @protected
  @override
  void setDependencyUsingExactType({
    required Gr type,
    required Dependency<Object> value,
  }) {
    final group = value.group;
    final prev = _state[group]?[type];
    if (prev != value) {
      (_state[group] ??= {})[type] = value;
      onUpdate(_state);
    }
  }

  @protected
  @override
  Dependency<Object>? removeDependencyUsingExactType({
    required Gr group,
    required Gr type,
  }) {
    final value = getDependencyMapByKey(group: group);
    if (value != null) {
      final dep = value.remove(type);
      if (value.isEmpty) {
        removeDependencyMapUsingExactType(type: type);
      } else {
        setDependencyMapByKey(
          group: group,
          value: value,
        );
      }
      return dep;
    }
    return null;
  }

  @protected
  @override
  void setDependencyMapByKey({
    required Gr group,
    required DependencyMap value,
  }) {
    final prev = _state[group];
    final equals = const MapEquality<Gr, Dependency<Object>>().equals(prev, value);
    if (!equals) {
      _state[group] = value;
      onUpdate(_state);
    }
  }

  @protected
  @override
  @pragma('vm:prefer-inline')
  DependencyMap<Object>? getDependencyMapByKey({
    required Gr group,
  }) {
    return _state[group];
  }

  @protected
  @override
  @pragma('vm:prefer-inline')
  void removeDependencyMapUsingExactType({
    required Gr type,
  }) {
    _state.remove(type);
    onUpdate(_state);
  }

  @override
  @pragma('vm:prefer-inline')
  void clearRegistry() => _state.clear();
}
