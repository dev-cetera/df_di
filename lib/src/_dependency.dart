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

/// Represents a dependency stored within [Registry]. Dependencies are wrappers
/// around values with additional [DependencyMetadata] to manage their
/// lifecycle.
@internal
final class Dependency<T extends Object> {
  const Dependency({
    required this.value,
    required this.metadata,
  });

  /// The value contained within this [Dependency].
  final T value;

  /// The metadata associated with this [Dependency].
  final DependencyMetadata metadata;

  /// The runtime type of the [value] contained within this [Dependency].
  DIKey get type => DIKey(value.runtimeType);

  /// Creates a new [Dependency] instance with a different value of type [R],
  /// while retaining the existing [metadata].
  Dependency<R> passNewValue<R extends Object>(R newValue) {
    return Dependency<R>(value: newValue, metadata: metadata);
  }

  /// Returns a new [Dependency] instance where the current [value] is cast
  /// to type [R], while retaining the existing [metadata].
  Dependency<R> cast<R extends Object>() => passNewValue(value as R);

  @override
  String toString() => 'Dependency<$type> #${metadata.index}';
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Contains metadata for a [Dependency] to facilitate lifecycle management,
/// track registration details, and support dependency resolution.
@internal
class DependencyMetadata {
  const DependencyMetadata({
    required this.initialType,
    required this.index,
    required this.typeGroup,
    required this.condition,
    required this.onUnregister,
  });

  /// The type of [Dependency.value] at the time the [Dependency] was registered.
  /// This type remains unchanged even if [Dependency.value] is updated through
  /// [Dependency.passNewValue]. This property consistently reflects the original type
  /// with which the dependency was registered.
  final Type initialType;

  /// The type group to which the [Dependency] belongs. This enables
  /// dependencies of the same type to coexist in the DI container as long as
  /// they are assigned to different groups.
  final DIKey typeGroup;

  /// The index at which this dependency was registered in the dependency
  /// injection container. This helps in tracking the order of registration
  /// and ensuring proper management of dependencies.
  final int index;

  /// A condition to determine if the dependency is considered valid or not
  /// so which will cuause errors the be thropwn when getting the dependency if
  /// inva;id.
  final DependencyValidator? condition;

  /// A callback to be invoked when this dependency is unregistered.
  final OnUnregisterCallback<Object>? onUnregister;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A typedef for a callback function that is invoked when a dependency is
/// unregistered. The function passes the value of the unregistered dependency
/// in order to facilitate any necessary cleanup or additional processing
/// that might be required for the [value].
@internal
typedef OnUnregisterCallback<T extends Object> = FutureOr<void> Function(
  T value,
);

/// A typedef for a function that evaluates the validity of a dependency based
/// on the current state of a [DI] container.
@internal
typedef DependencyValidator = bool Function(DIBase di);
