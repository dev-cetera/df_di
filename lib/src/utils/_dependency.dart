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

import 'dart:async';

import 'package:meta/meta.dart' show internal;

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A class representing a registered dependency with an optional [onUnregister]
/// callback.
@internal
final class Dependency<T> {
  final T value;
  final Type type;
  final Type registrationType;
  final int registrationIndex;
  final DIKey key;
  final OnUnregisterCallback<dynamic>? onUnregister;

  const Dependency({
    required this.value,
    required this.registrationIndex,
    Type? registrationType,
    this.key = DIKey.defaultKey,
    required this.onUnregister,
  })  : type = T,
        registrationType = registrationType ?? T;

  /// Creates a new dependency of type [N] from the current one but with
  /// a [newValue].
  Dependency<N> reassignValue<N>(N newValue) {
    return Dependency<N>(
      value: newValue,
      registrationIndex: registrationIndex,
      registrationType: registrationType,
      key: key,
      onUnregister: onUnregister,
    );
  }

  @override
  String toString() => 'Dependency<$T> ($hashCode)';
}

@internal
typedef OnUnregisterCallback<T> = FutureOr<void> Function(T value);
