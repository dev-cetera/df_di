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
abstract interface class GetFactoryIface {
  /// Gets a dependency registered via [registerFactory] as either a
  /// [Future] or an instance of [T] under the specified [group], or under
  /// [Id.defaultId] if no group is provided.
  ///
  /// This method returns a new instance of the dependency each time it is
  /// called.
  ///
  /// - Throws [DependencyNotFoundException] if no factory is found for the
  ///   requested type [T] and [group].
  FutureOr<T> getFactory<T extends Object, P extends Object>(
    P params, {
    Id? group,
  });

  /// ...
  @protected
  FutureOr<T>? getFactoryOrNull<T extends Object, P extends Object>(
    P params, {
    Id? group,
  });

  /// ...
  @protected
  FutureOr<Object> getFactoryUsingExactType({
    required Id type,
    required Object params,
    Id? group,
  });

  /// ...
  @protected
  FutureOr<Object> getFactoryUsingRuntimeType(
    Type type, {
    required Object params,
    Id? group,
  });

  /// ...
  @protected
  FutureOr<Object>? getFactoryUsingExactTypeOrNull({
    required Id type,
    required Object params,
    Id? group,
  });

  /// ...
  @protected
  FutureOr<Object>? getFactoryUsingRuntimeTypeOrNull(
    Type type, {
    required Object params,
    Id? group,
  });
}
