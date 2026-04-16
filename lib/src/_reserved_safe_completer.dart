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

// ignore_for_file: invalid_use_of_visible_for_testing_member

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
final class ReservedSafeCompleter<T extends Object> extends SafeCompleter<T> {
  //
  //
  //

  final Entity typeEntity;

  /// A type-check closure captured at construction time, used to determine
  /// whether a given value is assignable to this completer's `T`.
  ///
  /// This is a dart2js release-mode workaround. In `_maybeFinish`, we
  /// previously relied on `.whereType<ReservedSafeCompleter<T>>()` plus a
  /// `value as FutureOr<T>` cast to filter out completers whose type
  /// parameter doesn't match the registered value. In dart2js release
  /// mode, generic reified types are stripped — so those filters silently
  /// passed through completers of the *wrong* type, and the first-found
  /// completer was "completed" with a garbage value, short-circuiting the
  /// iteration before the correct completer was reached.
  ///
  /// Capturing the check as a closure here — inside the constructor,
  /// where `T` is still lexically in scope — forces dart2js to compile a
  /// proper `is T` check that survives release-mode optimisation.
  final bool Function(Object value) typeCheck;

  //
  //
  //

  ReservedSafeCompleter(this.typeEntity)
      : typeCheck = _buildTypeCheck<T>();

  static bool Function(Object) _buildTypeCheck<T>() {
    // `v is T` is evaluated against the generic parameter T at the site
    // where _buildTypeCheck is instantiated. Dart2js emits a real type
    // predicate here — it's NOT erased at release compile time.
    return (Object v) => v is T;
  }

  //
  //
  //

  @override
  bool operator ==(Object other) => identical(this, other);

  //
  //
  //

  @override
  int get hashCode {
    final a = Object() is! T ? T.hashCode : typeEntity.hashCode;
    final b = (ReservedSafeCompleter).hashCode;
    return Object.hash(a, b);
  }
}
