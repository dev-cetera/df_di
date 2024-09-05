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

@internal
abstract interface class GetIface {
  /// A shorthand for [getSync], allowing retrieval of a dependency using
  /// call syntax.
  T call<T extends Object>({
    Gr? group,
  });

  /// Gets via [get] using [T] and [group] or `null` upon any error,
  /// including but not limited to [DependencyNotFoundException].
  FutureOr<T>? getOrNull<T extends Object>({
    Gr? group,
  });

  /// Gets a dependency as either a [Future] or an instance of [T] registered
  /// under the type [T] and the specified [group], or under [Gr.defaultGroup]
  /// if no group is provided.
  ///
  /// If the dependency was registered as a lazy singleton via [registerLazySingleton]
  /// and hasn't been instantiated yet, it will be instantiated on the first call.
  /// Subsequent calls to [get] will return the already instantiated instance.
  ///
  /// If the dependency was registered via [registerFactory], a new instance
  /// will be created and returned with each call to [get].
  ///
  /// - Throws [DependencyNotFoundException] if the requested dependency cannot
  /// be found.
  FutureOr<T> get<T extends Object>({
    Gr? group,
  });

  FutureOr<T> getFactory<T extends Service<P>, P extends Object>(
    P params, {
    Gr? group,
  });
}
