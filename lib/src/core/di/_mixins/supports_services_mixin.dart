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

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base mixin SupportsServicesMixin on SupportsConstructorsMixin, SupportsMixinT {
  //
  //
  //

  @pragma('vm:prefer-inline')
  Future<TService> getServiceSingletonAsync<TService extends Service>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getSingleton<TService>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().toAsync().unwrap();
  }

  @pragma('vm:prefer-inline')
  Future<TService> getServiceFactoryAsync<TService extends Service>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getFactory<TService>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().toAsync().unwrap();
  }

  @pragma('vm:prefer-inline')
  TService getServiceSingletonSyncUnsafe<TService extends Service>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getSingleton<TService>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().toSync().unwrap();
  }

  @pragma('vm:prefer-inline')
  TService getServiceFactorySyncUnsafe<TService extends Service>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    return getFactory<TService>(
      groupEntity: groupEntity,
      traverse: traverse,
    ).unwrap().toSync().unwrap();
  }
}
