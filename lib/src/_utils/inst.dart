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

base class _Inst<T> {
  /// Creates a new inst.
  const _Inst(this.constructor);

  /// Creates a new object of type T.
  final InstConstructor<T> constructor;

  /// The type of the objects created by this inst.
  Type get type => T;

  @override
  String toString() {
    return '_Inst(type: $type)';
  }
}

/// A singleton interface that also reports the type of the created objects.
final class SingletonInst<T> extends _Inst<T> {
  /// Creates a new singleton.
  const SingletonInst(super.constructor);

  @override
  String toString() {
    return 'SingletonInst(type: $type)';
  }
}

typedef Singleton<T> = SingletonInst<T>;

/// A factory interface that also reports the type of the created objects.
final class FactoryInst<T> extends _Inst<T> {
  /// Creates a new factory.
  const FactoryInst(super.constructor);

  @override
  String toString() {
    return 'FactoryInst(type: $type)';
  }
}

typedef Factory<T> = FactoryInst<T>;

typedef InstConstructor<T> = FutureOr<T> Function();
