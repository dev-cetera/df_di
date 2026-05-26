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

@internal
final class ReservedSafeCompleter<T extends Object> extends SafeCompleter<T> {
  //
  //
  //

  final Entity typeEntity;

  /// `is T` check captured while `T` is lexically in scope. Dart2js release
  /// strips reified generics from `.whereType<...<T>>()` and `value as T`,
  /// but a closure built with `T` in scope keeps the predicate intact.
  final bool Function(Object value) typeCheck;

  //
  //
  //

  ReservedSafeCompleter(this.typeEntity) : typeCheck = _buildTypeCheck<T>();

  static bool Function(Object) _buildTypeCheck<T>() {
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
