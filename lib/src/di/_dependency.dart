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
@internal
final class Dependency<T extends Object> {
  final Resolvable<T> _value;

  Dependency(this._value, {this.metadata = const None()}) {
    UNSAFE:
    if (metadata.isSome()) {
      final a = metadata.unwrap();
      if (a._initialType.isNone()) {
        a._initialType = Some(_value.runtimeType);
      }
    }
  }

  Dependency._internal(this._value, {required this.metadata});

  /// The value contained within this [Dependency].
  Resolvable<T> get value => _value;

  // NOTE: Something like this can be used to optimize re-registration from
  // Async to Sync.
  // Async<T>? _cachedValue;

  // /// Caches the result of an asynchronous operation to prevent re-execution.
  // @protected
  // Async<T> cacheAsyncValue() {
  //   if (_cachedValue != null) {
  //     return _cachedValue!;
  //   }
  //   _cachedValue = Async(() async {
  //     final result = await _value.async().unwrap().value;
  //     _value = Sync.value(result);
  //     print(this._value);
  //     return result.unwrap();
  //   });

  //   return _cachedValue!;
  // }

  /// The metadata associated with this [Dependency].
  final Option<DependencyMetadata> metadata;

  /// Returns the `preemptivetypeEntity` of [metadata] if not `null` or the
  /// runtime type key of [_value].
  Entity get typeEntity {
    UNSAFE:
    final preemptivetypeEntity = metadata.unwrap().preemptivetypeEntity;
    if (preemptivetypeEntity.isDefault()) {
      return TypeEntity(_value.runtimeType);
    } else {
      return preemptivetypeEntity;
    }
  }

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
    UNSAFE:
    return Dependency<T>(
      value.isNone() ? _value : value.unwrap(),
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
    return Object.hashAll([_value, metadata]);
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
    this.onUnregister = const None(),
  });

  /// The type group to which the [Dependency] belongs. This enables
  /// dependencies of the same type to coexist in the DI container as long as
  /// they are assigned to different groups.
  final Entity groupEntity;

  /// The type key that the dependency is associated with within its group. If
  /// not `null`, it will override the default type key.
  final Entity preemptivetypeEntity;

  /// The type of [Dependency._value] at the time the [Dependency] was registered.
  /// This type remains unchanged even if [Dependency._value] is updated through
  /// [Dependency.passNewValue]. This property consistently reflects the original type
  /// with which the dependency was registered.
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
      index: index.isSome() ? index : this.index,
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
      onUnregister,
      _initialType,
    ]);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A typedef for a callback function to invoke when a dependency is
/// registered.
@internal
typedef TOnRegisterCallback<T extends Object> =
    FutureOr<void> Function(T value);

/// A typedef for a callback function to invoke when a dependency is
/// unregistered.
@internal
typedef TOnUnregisterCallback<T extends Object> =
    FutureOr<void> Function(Result<T> value);

/// A typedef for a function that evaluates the validity of a dependency.
@internal
typedef TDependencyValidator<T extends Object> = bool Function(T value);
