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

/// registry for storing and managing dependencies of by ther generic type,
/// runtime type and typeGroup.
final class Registry {
  //
  //
  //

  /// Dependencies, organized by their type.
  final _state = RegistryState();

  @protected
  void Function(RegistryState state) onChange = (_) {};

  /// A snapshot describing the current state of the dependencies.
  RegistryState get state => Map<DIKey, Map<DIKey, Dependency<Object>>>.unmodifiable(_state)
      .map((k, v) => MapEntry(k, Map.unmodifiable(v)));

  /// A snapshot of the current groups.
  Iterable<DIKey> get groups => state.keys;

  //
  //
  //

  /// Retrieves all dependencies associated with the specified [typeGroup].
  @protected
  Iterable<Dependency<Object>> getDependenciesByGroup({
    required DIKey typeGroup,
  }) {
    return _state.entries
        .expand(
          (entry) =>
              entry.value.values.where((dependency) => dependency.metadata.typeGroup == typeGroup),
        )
        .cast<Dependency<Object>>();
  }

  //
  //
  //

  /// Adds or overwrites the dependency of type [T] with the specified [value].
  @protected
  @pragma('vm:prefer-inline')
  void setDependency<T extends Object>({
    required Dependency<T> value,
  }) {
    setDependencyUsingExactType(
      type: DIKey(T),
      value: value,
    );
  }

  /// Adds or overwrites the dependency of the exact [type] with the specified
  /// [value].
  void setDependencyUsingExactType({
    required DIKey type,
    required Dependency<Object> value,
  }) {
    final typeGroup = value.metadata.typeGroup;
    final prev = _state[typeGroup]?[type];
    if (prev != value) {
      (_state[typeGroup] ??= {})[type] = value;
      onChange(_state);
    }
  }

  //
  //
  //

  //
  //
  //

  @protected
  @pragma('vm:prefer-inline')
  Iterable<Dependency<Object>> getAllDependenciesByKey({
    required DIKey typeGroup,
  }) {
    return getDependenciesForTypeGroup(typeGroup: typeGroup)?.values ?? const Iterable.empty();
  }

  //
  //
  //
  //
  //
  //

  /// Checks if any dependency of type [T] or subtype of [T] exists in the
  /// specified [typeGroup].
  ///
  /// Returns `true` if it does and `false` if it doesn't.
  @protected
  @pragma('vm:prefer-inline')
  bool containsDependency<T extends Object>({
    required DIKey typeGroup,
  }) {
    return getDependencyOrNull<T>(typeGroup: typeGroup) != null;
  }

  /// Checks if any dependency  of the exact [type] exists in the specified
  /// [typeGroup]. Unlike [containsDependency], this will not include any
  /// subtype of [type].
  ///
  /// Returns `true` if it does and `false` if it doesn't.
  @protected
  @pragma('vm:prefer-inline')
  bool containsDependencyOfType({
    required DIKey type,
    required DIKey typeGroup,
  }) {
    return getDependencyOfTypeOrNull(type: type, typeGroup: typeGroup) != null;
  }

  /// Gets any dependency of type [T] or subtype of [T] that is associated with
  /// the specified [typeGroup] if it exists.
  ///
  /// Returns `null` if no matching dependency is found.
  @pragma('vm:prefer-inline')
  @protected
  Dependency<Object>? getDependencyOrNull<T extends Object>({
    required DIKey typeGroup,
  }) {
    return getDependenciesByGroup(typeGroup: typeGroup).firstWhereOrNull((e) => e.value is T);
  }

  /// Gets any dependency of the exact [type] that is associated with the
  /// specified [typeGroup] if it exists. Unlike [getDependencyOrNull], this
  /// will not include any subtype of [type].
  ///
  /// Returns `null` if no matching dependency is found.
  @pragma('vm:prefer-inline')
  @protected
  Dependency<Object>? getDependencyOfTypeOrNull({
    required DIKey type,
    required DIKey typeGroup,
  }) {
    return getDependenciesByGroup(typeGroup: typeGroup)
        .firstWhereOrNull((e) => e.type == type)
        ?.cast();
  }

  /// Removes any [Dependency] of [T] or subtype of [T] that is associated with
  /// the specified [typeGroup].
  ///
  /// Returns the removed [Dependency] of [T], or `null` if it did not exist
  /// within [state].
  @protected
  Dependency<T>? removeDependency<T extends Object>({
    required DIKey typeGroup,
  }) {
    final dependency = getDependencyOrNull<T>(typeGroup: typeGroup);
    if (dependency != null) {
      final removed = removeDependencyByType(
        type: dependency.type,
        typeGroup: typeGroup,
      );
      return removed?.cast();
    }
    return null;
  }

  /// Removes any dependency of the exact [type] that is associated with the
  /// specified [typeGroup]. Unlike [removeDependency], this will not include
  /// any subtype of [type].
  ///
  /// Returns the removed [Dependency] or `null` if it did not exist within
  /// [state].
  Dependency<Object>? removeDependencyByType({
    required DIKey type,
    required DIKey typeGroup,
  }) {
    final value = getDependenciesForTypeGroup(typeGroup: typeGroup);
    if (value != null) {
      final removed = value.remove(type);
      if (value.isEmpty) {
        removeTypeGroup(typeGroup: typeGroup);
      } else {
        setDependenciesForTypeGroup(
          typeGroup: typeGroup,
          value: value,
        );
      }
      return removed;
    }
    return null;
  }

  /// Sets all dependencies within [state] for the given [typeGroup] to [value].
  void setDependenciesForTypeGroup({
    required DIKey typeGroup,
    required DependencyTypeGroup<Object> value,
  }) {
    final prev = _state[typeGroup];
    final equals = const MapEquality<DIKey, Dependency<Object>>().equals(prev, value);
    if (!equals) {
      _state[typeGroup] = value;
      onChange(_state);
    }
  }

  /// Gets all dependencies for the given [typeGroup] from [state] as a
  /// [DependencyTypeGroup] or `null` if none exist.
  @protected
  DependencyTypeGroup<Object>? getDependenciesForTypeGroup({
    required DIKey typeGroup,
  }) {
    final temp = _state[typeGroup];
    return temp != null ? DependencyTypeGroup.unmodifiable(temp) : null;
  }

  /// Removes all dependencies associated with [typeGroup] from [state].
  @protected
  @pragma('vm:prefer-inline')
  void removeTypeGroup({
    required DIKey typeGroup,
  }) {
    _state.remove(typeGroup);
    onChange(_state);
  }

  /// Clears the [state], resetting the registry and effectively restoring it
  /// to the state of a newly created [Registry] instance.
  void clearRegistry() {
    _state.clear();
    onChange(_state);
    onChange = (_) {};
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef RegistryState = Map<DIKey, DependencyTypeGroup<Object>>;

typedef DependencyTypeGroup<T extends Object> = Map<DIKey, Dependency<T>>;
