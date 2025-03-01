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

// ignore_for_file: invalid_use_of_visible_for_testing_member

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
final class ReservedSafeFinisher<T extends Object> extends SafeFinisher<T> {
  final Entity typeEntity;
  ReservedSafeFinisher(this.typeEntity);

  @override
  bool operator ==(Object other) => identical(this, other);

  // static ReservedSafeFinisher<T> castFrom<T extends Object, E extends Object>(
  //   ReservedSafeFinisher<E> input,
  // ) {
  //   final test = <ReservedSafeFinisher<E>>[input];
  //   return test.cast<ReservedSafeFinisher<T>>().first;
  // }

  // ReservedSafeFinisher<E> castTo<E extends Object>() {
  //   return ReservedSafeFinisher.castFrom<E, T>(this);
  // }

  @override
  int get hashCode {
    final a = Object() is! T ? T.hashCode : typeEntity.hashCode;
    final b = (ReservedSafeFinisher).hashCode;
    return Object.hash(a, b);
  }
}
