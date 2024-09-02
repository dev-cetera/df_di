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
final class Dependency<T extends Object> {
  final T value;
  final Type type;
  final Identifier key;
  final Type registrationType;
  final int registrationIndex;

  final OnUnregisterCallback<Object>? onUnregister;

  Dependency({
    required this.value,
    required this.registrationIndex,
    Type? registrationType,
    this.key = Identifier.defaultId,
    required this.onUnregister,
  })  : type = value.runtimeType,
        registrationType = registrationType ?? value.runtimeType;

  /// Creates a new dependency of type [R] from the current one but with
  /// a [newValue].
  Dependency<R> reassign<R extends Object>(R newValue) {
    return Dependency<R>(
      value: newValue,
      registrationIndex: registrationIndex,
      registrationType: registrationType,
      key: key,
      onUnregister: onUnregister,
    );
  }

  Dependency<R> cast<R extends Object>() => reassign(value as R);

  @override
  String toString() => 'Dependency<$type> | Dependency<$registrationType> #$registrationIndex';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Dependency) return false;
    return registrationIndex == other.registrationIndex && type == other.type;
  }

  @override
  int get hashCode => Object.hash(registrationIndex, type);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
typedef OnUnregisterCallback<T extends Object> = FutureOr<void> Function(T value);
