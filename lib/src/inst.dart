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

import 'package:meta/meta.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class Inst<T extends Object, P extends Object> {
  /// Creates a new inst.
  const Inst(this.constructor);

  /// Creates a new object of type T.
  final InstConstructor<T, P> constructor;

  /// The type of the objects created by this inst.
  Descriptor get type => Descriptor.type(T);

  @override
  String toString() {
    return '$runtimeType(type: $T)';
  }

  Inst<T2, P2> cast<T2 extends Object, P2 extends Object>() {
    return castWith<T2, P2, Inst<T2, P2>>((c) => Inst<T2, P2>((e) => c(e)));
  }

  @protected
  I castWith<T2 extends Object, P2 extends Object, I extends Inst<T2, P2>>(
    I Function(InstConstructor<T2, P2> constructor) caster,
  ) {
    return caster((e) => constructor(e as P) as FutureOr<T2>);
  }
}

typedef InstConstructor<T extends Object, P extends Object> = FutureOr<T> Function(P params);

typedef FutureInst<T extends Object> = _FutureInst<T, Object>;

class _FutureInst<T extends Object, P extends Object> extends Inst<T, P> {
  const _FutureInst(super.constructor);

  @override
  _FutureInst<T2, P2> cast<T2 extends Object, P2 extends Object>() {
    return castWith<T2, P2, _FutureInst<T2, P2>>((c) => _FutureInst<T2, P2>((e) => c(e)));
  }
}

typedef SingletonInst<T extends Object> = _SingletonInst<T, Object>;

/// A singleton interface that also reports the type of the created objects.
class _SingletonInst<T extends Object, P extends Object> extends Inst<T, P> {
  /// Creates a new singleton.
  const _SingletonInst(super.constructor);

  @override
  _SingletonInst<T2, P2> cast<T2 extends Object, P2 extends Object>() {
    return castWith<T2, P2, _SingletonInst<T2, P2>>((c) => _SingletonInst<T2, P2>((e) => c(e)));
  }
}

/// A factory interface that also reports the type of the created objects.
class FactoryInst<T extends Object, P extends Object> extends Inst<T, P> {
  /// Creates a new factory.
  const FactoryInst(super.constructor);

  @override
  FactoryInst<T2, P2> cast<T2 extends Object, P2 extends Object>() {
    return castWith<T2, P2, FactoryInst<T2, P2>>((c) => FactoryInst<T2, P2>((e) => c(e)));
  }
}

/// A type alias for a function that returns an instance of type `T`.
typedef Constructor<T> = T Function();
