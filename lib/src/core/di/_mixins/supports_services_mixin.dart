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

// ignore_for_file: invalid_use_of_protected_member

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base mixin SupportsServicesMixin on SupportsConstructorsMixin, SupportsMixinT {
  Result<Resolvable<TService>> registerService<TService extends Service>({
    required FutureOr<TService> Function() unsafe,
    Object? params,
    Entity groupEntity = const DefaultEntity(),
  }) {
    return register<TService>(
      unsafe: () {
        return consec(
          unsafe(),
          (e) => consec(
            e.init(params),
            (_) => e,
          ),
        );
      },
      groupEntity: groupEntity,
    );
  }

  Result<void> registerLazyService<TService extends Service>({
    required Resolvable<TService> Function() constructor,
    Object? params,
    Entity groupEntity = const DefaultEntity(),
  }) {
    return registerLazy<TService>(
      () => constructor().map((e) => e..init(params)),
      groupEntity: groupEntity,
    );
  }

  Resolvable<Option<TService>> getServiceSingleton<TService extends Service>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getSingleton<TService>(
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  Resolvable<Option<TService>> getServiceFactory<TService extends Service>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getFactory<TService>(
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }
}
