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

class Inst<T> {
  /// Creates a new inst.
  const Inst(this.constructor);

  /// Creates a new object of type T.
  final InstConstructor<T> constructor;

  /// The type of the objects created by this inst.
  Type get type => T;

  @override
  String toString() {
    return '$runtimeType(type: $T)';
  }
}

typedef InstConstructor<T> = FutureOr<T> Function();

class FutureInst<T> extends Inst<T> {
  const FutureInst(super.constructor);
}

/// A singleton interface that also reports the type of the created objects.
class SingletonInst<T> extends Inst<T> {
  /// Creates a new singleton.
  const SingletonInst(super.constructor);
}

/// Shorthand for [Singleton].
typedef Singleton<T> = SingletonInst<T>;

/// A factory interface that also reports the type of the created objects.
class FactoryInst<T> extends Inst<T> {
  /// Creates a new factory.
  const FactoryInst(super.constructor);
}

/// Shorthand for [FactoryInst].
typedef Factory<T> = FactoryInst<T>;

/// A type alias for a function that returns an instance of type `T`.
typedef Constructor<T> = T Function();
