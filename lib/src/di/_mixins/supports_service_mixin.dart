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
import '../../_callback_result.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Adds first-class [ServiceMixin] handling to a [DI] container: services
/// register, `init()` is run, and `dispose()` is cascaded automatically when
/// the service is unregistered.
base mixin SupportsServiceMixin on DIBase {
  /// Registers [service] and drives its lifecycle:
  ///
  /// * Runs `service.init()` before the user-supplied [onRegister] fires, so
  ///   the user hook always sees a fully-initialised service.
  /// * On unregister, runs `service.dispose()` first, then [onUnregister].
  ///
  /// Pass [enableUntilExactlyK] `true` if you intend to wait on this exact
  /// registration via `untilExactlyK` / `untilExactlyT`.
  Resolvable<Unit> registerAndInitService<TService extends ServiceMixin>(
    TService service, {
    Option<TOnRegisterCallback<TService>> onRegister = const None(),
    Option<TOnUnregisterCallback<TService>> onUnregister = const None(),
    Entity groupEntity = const DefaultEntity(),
    bool enableUntilExactlyK = false,
  }) {
    UNSAFE:
    return register<TService>(
      service,
      onRegister: Some((service) {
        // Run the framework-level `init()` first, then chain the user-supplied
        // onRegister (if any). Without this chain the user's hook would never
        // observe a fully-initialised service.
        return consec(
          awaitCallbackResult(
            service.init(),
            logAndSwallowSyncErr: false,
            logContext: 'registerAndInitService<$TService>.init',
          ),
          (_) {
            return switch (onRegister) {
              Some(value: final userCb) => awaitCallbackResult(
                  userCb(service),
                  logAndSwallowSyncErr: false,
                  logContext:
                      'registerAndInitService<$TService>.userOnRegister',
                ),
              None() => null,
            };
          },
        );
      }),
      onUnregister: Some((serviceOpt) {
        final service = serviceOpt.unwrap();
        return consec(service.dispose().value, (disposeResult) {
          disposeResult.unwrap();
          // Invoke the user-supplied onUnregister AFTER dispose has settled
          // — previously this slot just `consec`-ed on the Option itself,
          // which is sync, so the user's callback was never actually called.
          return switch (onUnregister) {
            Some(value: final userCb) => awaitCallbackResult(
                userCb(serviceOpt),
                logAndSwallowSyncErr: true,
                logContext:
                    'registerAndInitService<$TService>.userOnUnregister',
              ),
            None() => null,
          };
        });
      }),
      groupEntity: groupEntity,
      enableUntilExactlyK: enableUntilExactlyK,
    ).toUnit();
  }
}
