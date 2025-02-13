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
  //
  //
  //

  Result<void> registerAndInitService<TService extends Service>(
    FutureOr<TService> service, {
    Object? params,
    Entity groupEntity = const DefaultEntity(),
  }) {
    return register<TService>(
      consec(
        service,
        (e) => consec(
          e.init(params),
          (_) => e,
        ),
      ),
      groupEntity: groupEntity,
    );
  }

  @pragma('vm:prefer-inline')
  Result<void> registerLazyServiceUnsafe<TService extends Service>({
    required FutureOr<TService> Function() constructor,
    Object? params,
    Entity groupEntity = const DefaultEntity(),
  }) {
    return registerLazy<TService>(
      () => Resolvable.unsafe(constructor).map((e) => e..init(params)),
      groupEntity: groupEntity,
    );
  }

  @pragma('vm:prefer-inline')
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

  @pragma('vm:prefer-inline')
  Future<TService> getServiceSingletonAsync<TService extends Service>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getServiceFactorySafe<TService>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().toAsync().unwrap();
  }

  @pragma('vm:prefer-inline')
  OptionResolvable<TService> getServiceSingletonSafe<TService extends Service>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getSingleton<TService>(
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }

  @pragma('vm:prefer-inline')
  TService getServiceFactorySync<TService extends Service>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getServiceFactorySafe<TService>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().sync().unwrap().unwrap();
  }

  @pragma('vm:prefer-inline')
  OptionResolvable<TService> getServiceFactorySafe<TService extends Service>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getFactory<TService>(
      groupEntity: groupEntity,
      traverse: traverse,
    );
  }
}
