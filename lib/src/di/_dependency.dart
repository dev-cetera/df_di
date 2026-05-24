//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Represents a dependency stored within [DIRegistry]. Dependencies are wrappers
/// around values with additional [DependencyMetadata] to manage their
/// lifecycle.
final class Dependency<T extends Object> {
  final Resolvable<T> _value;

  Dependency(this._value, {this.metadata = const None()}) {
    if (metadata case Some(value: final m)) {
      if (m._initialType case None()) {
        m._initialType = Some(_value.runtimeType);
      }
    }
  }

  Dependency._internal(this._value, {required this.metadata});

  /// The value contained within this [Dependency].
  Resolvable<T> get value => _value;

  /// The metadata associated with this [Dependency].
  final Option<DependencyMetadata> metadata;

  /// The registry key for this dependency: returns
  /// [DependencyMetadata.preemptivetypeEntity] if one was supplied, otherwise
  /// the runtime type of the wrapped value.
  Entity get typeEntity => switch (metadata) {
        Some(value: final m) when !m.preemptivetypeEntity.isDefault() =>
          m.preemptivetypeEntity,
        _ => TypeEntity(_value.runtimeType),
      };

  /// Creates a new [Dependency] instance with a different value of type [R],
  /// while retaining the existing [metadata].
  Dependency<R> passNewValue<R extends Object>(Resolvable<R> newValue) {
    return Dependency<R>._internal(newValue, metadata: metadata);
  }

  /// Returns a new [Dependency] instance where the current [_value] is cast
  /// to type [R], while retaining the existing [metadata].
  Dependency<R> transf<R extends Object>() => passNewValue(_value.transf());

  /// Creates a new instance with updated fields, preserving the values of any
  /// fields not explicitly specified.
  Dependency<T> copyWith({
    Option<Resolvable<T>> value = const None(),
    Option<DependencyMetadata> metadata = const None(),
  }) {
    return Dependency<T>(
      switch (value) {
        Some(value: final v) => v,
        None() => _value,
      },
      metadata: metadata,
    );
  }

  /// Equality is hash-based by design — consistent with [Entity] / [TypeEntity]
  /// elsewhere in the package. Used only to skip no-op `setDependency`
  /// overwrites in [DIRegistry] (and so to avoid spurious `onChange`
  /// callbacks); the registry slot key is `typeEntity`, not the dep itself,
  /// so a hash collision here cannot misroute a lookup.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Dependency && hashCode == other.hashCode;
  }

  @override
  int get hashCode {
    return Object.hashAll([_value, metadata]);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Contains metadata for a [Dependency] to facilitate lifecycle management,
/// track registration details, and support dependency resolution.
class DependencyMetadata {
  DependencyMetadata({
    this.groupEntity = const DefaultEntity(),
    this.preemptivetypeEntity = const DefaultEntity(),
    this.index = const None(),
    this.onUnregister = const None(),
  });

  /// The type group to which the [Dependency] belongs. This enables
  /// dependencies of the same type to coexist in the DI container as long as
  /// they are assigned to different groups.
  final Entity groupEntity;

  /// An explicit type key for this dependency. When not [DefaultEntity], this
  /// overrides the runtime type of the wrapped value as the registry key.
  final Entity preemptivetypeEntity;

  /// The runtime type of the wrapped value at the moment the dependency was
  /// first registered. Stable across [Dependency.passNewValue] swaps, so it
  /// always reflects the original registration type.
  Option<Type> get initialType => _initialType;
  Option<Type> _initialType = const None();

  /// The index at which this dependency was registered in the dependency
  /// injection container. This helps in tracking the order of registration
  /// and ensuring proper management of dependencies.
  final Option<int> index;

  /// A callback to be invoked when this dependency is unregistered.
  final Option<TOnUnregisterCallback<Object>> onUnregister;

  /// Creates a new instance with updated fields, preserving the values of any
  /// fields not explicitly specified.
  DependencyMetadata copyWith({
    Entity groupEntity = const DefaultEntity(),
    Entity preemptivetypeEntity = const DefaultEntity(),
    Option<Type> initialType = const None(),
    Option<int> index = const None(),
    Option<TOnUnregisterCallback<Object>> onUnregister = const None(),
  }) {
    return DependencyMetadata(
      groupEntity: groupEntity.isNotDefault() ? groupEntity : this.groupEntity,
      preemptivetypeEntity: preemptivetypeEntity.isNotDefault()
          ? preemptivetypeEntity
          : this.preemptivetypeEntity,
      index: switch (index) {
        Some() => index,
        None() => this.index,
      },
      onUnregister: switch (onUnregister) {
        Some() => onUnregister,
        None() => this.onUnregister,
      },
    ).._initialType = switch (initialType) {
        Some() => initialType,
        None() => _initialType,
      };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DependencyMetadata && hashCode == other.hashCode;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      groupEntity,
      preemptivetypeEntity,
      index,
      onUnregister,
      _initialType,
    ]);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A typedef for a callback function to invoke when a dependency is
/// registered.
typedef TOnRegisterCallback<T extends Object> = FutureOr<void> Function(
  T value,
);

/// A typedef for a callback function to invoke when a dependency is
/// unregistered.
typedef TOnUnregisterCallback<T extends Object> = FutureOr<void> Function(
  Result<T> value,
);

/// A typedef for a function that evaluates the validity of a dependency.
typedef TDependencyValidator<T extends Object> = bool Function(T value);
