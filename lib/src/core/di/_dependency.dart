//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Represents a dependency stored within [DIRegistry]. Dependencies are wrappers
/// around values with additional [DependencyMetadata] to manage their
/// lifecycle.
@internal
final class Dependency<T extends Object> {
  Dependency(
    this.value, {
    this.metadata,
  }) {
    this.metadata?._initialType = value.runtimeType;
  }

  Dependency._internal(
    this.value, {
    required this.metadata,
  });

  /// The value contained within this [Dependency].
  final T value;

  /// The metadata associated with this [Dependency].
  final DependencyMetadata? metadata;

  /// Returns the `preemptivetypeEntity` of [metadata] if not `null` or the
  /// runtime type key of [value].
  Entity get typeEntity => metadata?.preemptivetypeEntity ?? Entity.obj(value.runtimeType);

  /// Creates a new [Dependency] instance with a different value of type [R],
  /// while retaining the existing [metadata].
  Dependency<R> passNewValue<R extends Object>(R newValue) {
    return Dependency<R>._internal(newValue, metadata: metadata);
  }

  /// Returns a new [Dependency] instance where the current [value] is cast
  /// to type [R], while retaining the existing [metadata].
  Dependency<R> cast<R extends Object>() => passNewValue(value as R);

  /// Creates a new instance with updated fields, preserving the values of any
  /// fields not explicitly specified.
  Dependency<T> copyWith({
    T? value,
    DependencyMetadata? metadata,
  }) {
    return Dependency<T>(
      value ?? this.value,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Dependency && hashCode == other.hashCode;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      value,
      metadata,
    ]);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Contains metadata for a [Dependency] to facilitate lifecycle management,
/// track registration details, and support dependency resolution.
@internal
class DependencyMetadata {
  DependencyMetadata({
    this.groupEntity,
    this.preemptivetypeEntity,
    this.index,
    this.validator,
    this.onUnregister,
  });

  /// The type group to which the [Dependency] belongs. This enables
  /// dependencies of the same type to coexist in the DI container as long as
  /// they are assigned to different groups.
  final Entity? groupEntity;

  /// The type key that the dependency is associated with within its group. If
  /// not `null`, it will override the default type key.
  final Entity? preemptivetypeEntity;

  /// The type of [Dependency.value] at the time the [Dependency] was registered.
  /// This type remains unchanged even if [Dependency.value] is updated through
  /// [Dependency.passNewValue]. This property consistently reflects the original type
  /// with which the dependency was registered.
  Type get initialType => _initialType!;
  Type? _initialType;

  /// The index at which this dependency was registered in the dependency
  /// injection container. This helps in tracking the order of registration
  /// and ensuring proper management of dependencies.
  final int? index;

  /// A function that evaluates the validity of a dependency.
  final DependencyValidator? validator;

  /// A callback to be invoked when this dependency is unregistered.
  final OnUnregisterCallback<Object>? onUnregister;

  /// Creates a new instance with updated fields, preserving the values of any
  /// fields not explicitly specified.
  DependencyMetadata copyWith({
    Entity? groupEntity,
    Entity? preemptivetypeEntity,
    Type? initialType,
    int? index,
    DependencyValidator? validator,
    OnUnregisterCallback<Object>? onUnregister,
  }) {
    return DependencyMetadata(
      groupEntity: groupEntity ?? this.groupEntity,
      preemptivetypeEntity: preemptivetypeEntity ?? this.preemptivetypeEntity,
      index: index ?? this.index,
      validator: validator ?? this.validator,
      onUnregister: onUnregister ?? this.onUnregister,
    ).._initialType = initialType ?? _initialType;
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
      validator,
      onUnregister,
      _initialType,
    ]);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A typedef for a callback function to invoke when a dependency is
/// unregistered. The function passes the value of the unregistered dependency
/// in order to facilitate any necessary cleanup or additional processing
/// that might be required for the [value].
@internal
typedef OnUnregisterCallback<T extends Object> = FutureOr<void> Function(
  T value,
);

/// A typedef for a function that evaluates the validity of a dependency.
@internal
typedef DependencyValidator<T extends Object> = bool Function(T value);
