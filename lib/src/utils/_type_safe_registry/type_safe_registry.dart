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
  TypeSafeRegistryMap get state => Map<DIKey, Map<DIKey, Dependency<Object>>>.unmodifiable(_state)
      .map((k, v) => MapEntry(k, Map.unmodifiable(v)));

  @override
  @pragma('vm:prefer-inline')
  Dependency<Object>? getDependencyOfType(DIKey type, DIKey key) => _state[type]?[key];

  @override
  Iterable<Dependency<Object>> getDependenciesWithKey(DIKey key) {
    return _state.entries
        .expand((entry) => entry.value.values.where((dependency) => dependency.key == key))
        .cast<Dependency<Object>>();
  }

  @override
  void setDependencyOfType(
    DIKey type,
    DIKey key,
    Dependency<Object> dep,
  ) {
    final prev = _state[type]?[key];
    if (prev != dep) {
      (_state[type] ??= {})[key] = dep;
      onUpdate(_state);
    }
  }

  @override
  Dependency<Object>? removeDependencyOfType(DIKey type, DIKey key) {
    final depMap = getDependencyMapOfType(type);
    if (depMap != null) {
      final dep = depMap.remove(key);
      if (depMap.isEmpty) {
        removeDependencyMapOfType(type);
      } else {
        setDependencyMapOfType(type, depMap);
      }
      return dep;
    }
    return null;
  }

  @override
  void setDependencyMapOfType<T extends Object>(DIKey type, DependencyMap<T> deps) {
    final prev = _state[type];
    final equals = const MapEquality<DIKey, Dependency<Object>>().equals(prev, deps);
    if (!equals) {
      _state[type] = deps;
      onUpdate(_state);
    }
  }

  @override
  @pragma('vm:prefer-inline')
  DependencyMap<Object>? getDependencyMapOfType(DIKey type) => _state[type];

  @override
  @pragma('vm:prefer-inline')
  void removeDependencyMapOfType(DIKey type) {
    _state.remove(type);
    onUpdate(_state);
  }

  @override
  @pragma('vm:prefer-inline')
  void clearRegistry() => _state.clear();
}
