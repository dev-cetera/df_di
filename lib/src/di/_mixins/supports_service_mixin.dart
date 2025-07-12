//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base mixin SupportsServiceMixin on DIBase {
  Resolvable<Unit> registerAndInitService<TService extends ServiceMixin>(
    TService service, {
    TOnRegisterCallback<TService>? onRegister,
    TOnUnregisterCallback<TService>? onUnregister,
    Entity groupEntity = const DefaultEntity(),
    bool enableUntilExactlyK = false,
  }) {
    UNSAFE:
    return register<TService>(
      service,
      onRegister: (service) {
        return service.init().unwrap();
      },
      onUnregister: (serviceOpt) {
        final service = serviceOpt.unwrap();
        return consec(service.dispose().value, (disposeResult) {
          disposeResult.unwrap();
          return consec(onUnregister, (_) => service);
        });
      },
      groupEntity: groupEntity,
      enableUntilExactlyK: enableUntilExactlyK,
    ).toUnit();
  }
}
