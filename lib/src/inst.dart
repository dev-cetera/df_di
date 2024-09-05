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

@pragma('vm:keep-name') // enable string lookups
class Inst<T extends Object, P extends Object> {
  static Gr gr(Object type, Object paramsType) => Gr.fromType(
        baseType: Inst,
        subTypes: [type, paramsType],
      );

  /// Creates a new inst.
  const Inst(this.constructor);

  /// Creates a new object of type T.
  final InstConstructor<T, P> constructor;

  /// The type of the objects created by this inst.
  Gr get type => Gr(T);

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

@pragma('vm:keep-name') // enable string lookups
class FutureInst<T extends Object, P extends Object> extends Inst<T, P> {
  static Gr gr(Object type, Object paramsType) => Gr.fromType(
        baseType: FutureInst,
        subTypes: [type, paramsType],
      );

  const FutureInst(super.constructor);

  @override
  FutureInst<T2, P2> cast<T2 extends Object, P2 extends Object>() {
    return castWith<T2, P2, FutureInst<T2, P2>>(
      (c) => FutureInst<T2, P2>((e) => c(e)),
    );
  }
}

/// A singleton interface that also reports the type of the created objects.
@pragma('vm:keep-name') // enable string lookups
class SingletonInst<T extends Object, P extends Object> extends Inst<T, P> {
  static Gr gr(Object type, Object paramsType) => Gr.fromType(
        baseType: SingletonInst,
        subTypes: [type, paramsType],
      );

  /// Creates a new singleton.
  const SingletonInst(super.constructor);

  @override
  SingletonInst<T2, P2> cast<T2 extends Object, P2 extends Object>() {
    return castWith<T2, P2, SingletonInst<T2, P2>>(
      (c) => SingletonInst<T2, P2>((e) => c(e)),
    );
  }
}

/// A factory interface that also reports the type of the created objects.
@pragma('vm:keep-name') // enable string lookups
class FactoryInst<T extends Object, P extends Object> extends Inst<T, P> {
  static Gr gr(Object type, Object paramsType) => Gr.fromType(
        baseType: FactoryInst,
        subTypes: [type, paramsType],
      );

  /// Creates a new factory.
  const FactoryInst(super.constructor);

  @override
  FactoryInst<T2, P2> cast<T2 extends Object, P2 extends Object>() {
    return castWith<T2, P2, FactoryInst<T2, P2>>(
      (c) => FactoryInst<T2, P2>((e) => c(e)),
    );
  }
}

/// A type alias for a function that returns an instance of type `T`.
typedef Constructor<T> = T Function();
