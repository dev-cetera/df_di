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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class CompleterOr<T> {
  //
  //
  //

  final Completer<T> _completer = Completer<T>();

  FutureOr<T>? _value;

  //
  //
  //

  CompleterOr();

  //
  //
  //

  /// Completes with the given value or directly stores the value.
  void complete([FutureOr<T>? value]) {
    if (!_completer.isCompleted) {
      _completer.complete(value);
    }
    _value = value;
  }

  /// Returns the value directly if available, or a Future that resolves to the value.
  FutureOr<T> get futureOr {
    if (_value != null) {
      return _value!;
    }
    return _completer.future;
  }

  /// Returns `true` if the value is already set or the completer is completed.
  bool get isCompleted => _completer.isCompleted || _value != null;
}
