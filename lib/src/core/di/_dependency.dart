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
  Dependency(this.value, {this.metadata = const None()}) {
    if (this.metadata.isSome()) {
      final a = this.metadata.unwrap();
      if (a._initialType.isSome()) {
        a._initialType = Some(value.runtimeType);
      }
    }
  }

  Dependency._internal(this.value, {required this.metadata});

  /// The value contained within this [Dependency].
  final Resolvable<T> value;

  /// The metadata associated with this [Dependency].
  final Option<DependencyMetadata> metadata;

  /// Returns the `preemptivetypeEntity` of [metadata] if not `null` or the
  /// runtime type key of [value].
  Entity get typeEntity {
    final preemptivetypeEntity = metadata.unwrap().preemptivetypeEntity;
    if (preemptivetypeEntity.isDefault()) {
      return TypeEntity(value.runtimeType);
    } else {
      return preemptivetypeEntity;
    }
  }

  /// Creates a new [Dependency] instance with a different value of type [R],
  /// while retaining the existing [metadata].
  Dependency<R> passNewValue<R extends Object>(Resolvable<R> newValue) {
    return Dependency<R>._internal(newValue, metadata: metadata);
  }

  /// Returns a new [Dependency] instance where the current [value] is cast
  /// to type [R], while retaining the existing [metadata].
  Dependency<R> trans<R extends Object>() => passNewValue(value.trans());

  /// Creates a new instance with updated fields, preserving the values of any
  /// fields not explicitly specified.
  Dependency<T> copyWith({
    Option<Resolvable<T>> value = const None(),
    Option<DependencyMetadata> metadata = const None(),
  }) {
    return Dependency<T>(
      value.isNone() ? this.value : value.unwrap(),
      metadata: metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Dependency && hashCode == other.hashCode;
  }

  @override
  int get hashCode {
    return Object.hashAll([value, metadata]);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Contains metadata for a [Dependency] to facilitate lifecycle management,
/// track registration details, and support dependency resolution.
@internal
class DependencyMetadata {
  DependencyMetadata({
    this.groupEntity = const DefaultEntity(),
    this.preemptivetypeEntity = const DefaultEntity(),
    this.index = const None(),
    this.validator = const None(),
    this.onUnregister = const None(),
  });

  /// The type group to which the [Dependency] belongs. This enables
  /// dependencies of the same type to coexist in the DI container as long as
  /// they are assigned to different groups.
  final Entity groupEntity;

  /// The type key that the dependency is associated with within its group. If
  /// not `null`, it will override the default type key.
  final Entity preemptivetypeEntity;

  /// The type of [Dependency.value] at the time the [Dependency] was registered.
  /// This type remains unchanged even if [Dependency.value] is updated through
  /// [Dependency.passNewValue]. This property consistently reflects the original type
  /// with which the dependency was registered.
  Option<Type> get initialType => _initialType;
  Option<Type> _initialType = const None();

  /// The index at which this dependency was registered in the dependency
  /// injection container. This helps in tracking the order of registration
  /// and ensuring proper management of dependencies.
  final Option<int> index;

  /// A function that evaluates the validity of a dependency.
  final Option<DependencyValidator> validator;

  /// A callback to be invoked when this dependency is unregistered.
  final Option<OnUnregisterCallback<Object>> onUnregister;

  /// Creates a new instance with updated fields, preserving the values of any
  /// fields not explicitly specified.
  DependencyMetadata copyWith({
    Entity groupEntity = const DefaultEntity(),
    Entity preemptivetypeEntity = const DefaultEntity(),
    Option<Type> initialType = const None(),
    Option<int> index = const None(),
    Option<DependencyValidator> validator = const None(),
    Option<OnUnregisterCallback<Object>> onUnregister = const None(),
  }) {
    return DependencyMetadata(
      groupEntity: groupEntity.isNotDefault() ? groupEntity : this.groupEntity,
      preemptivetypeEntity:
          preemptivetypeEntity.isNotDefault() ? preemptivetypeEntity : this.preemptivetypeEntity,
      index: index.isSome() ? index : this.index,
      validator: validator.isSome() ? validator : this.validator,
      onUnregister: onUnregister.isSome() ? onUnregister : this.onUnregister,
    ).._initialType = initialType.isSome() ? initialType : _initialType;
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
typedef OnUnregisterCallback<T extends Object> = Resolvable<void> Function(T value);

/// A typedef for a function that evaluates the validity of a dependency.
@internal
typedef DependencyValidator<T extends Object> = bool Function(T value);
