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
      onUnregister: Some((serviceResult) {
        // Pattern-match the Result so an Err-resolved service doesn't crash
        // the unregister chain. Err path: skip dispose, but still fire the
        // user's onUnregister with the original Err so they can observe
        // the failed cleanup target.
        return switch (serviceResult) {
          Err() => _fireUserOnUnregister<TService>(
              onUnregister,
              serviceResult,
            ),
          Ok(value: final service) => consec(
              service.dispose().value,
              (disposeResult) {
                if (disposeResult case Err(:final error)) {
                  // dispose() failure is logged-and-swallowed here so the
                  // user's cleanup hook still gets a chance to run. The
                  // underlying error is preserved in the log via
                  // `service.dart::recordError`.
                  Log.err(
                    'registerAndInitService<$TService>.dispose: $error',
                  );
                }
                return _fireUserOnUnregister<TService>(
                  onUnregister,
                  serviceResult,
                );
              },
            ),
        };
      }),
      groupEntity: groupEntity,
      enableUntilExactlyK: enableUntilExactlyK,
    ).toUnit();
  }

  /// Invokes the user-supplied [onUnregister] callback if present, passing
  /// the original [serviceResult] so the user observes Ok/Err symmetrically.
  /// Errors thrown by the user's callback are logged and swallowed (cleanup
  /// is best-effort).
  FutureOr<void> _fireUserOnUnregister<TService extends ServiceMixin>(
    Option<TOnUnregisterCallback<TService>> onUnregister,
    Result<TService> serviceResult,
  ) {
    return switch (onUnregister) {
      Some(value: final userCb) => awaitCallbackResult(
          userCb(serviceResult),
          logAndSwallowSyncErr: true,
          logContext: 'registerAndInitService<$TService>.userOnUnregister',
        ),
      None() => null,
    };
  }
}
