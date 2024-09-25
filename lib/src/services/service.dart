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

/// A base class for services that require initialization and disposal management.
///
/// This class is intended to be used within a Dependency Injection [DI] system.
///
/// It provides a standardized structure for managing the lifecycle of services,
/// ensuring they are properly initialized when needed and disposed of when no
/// longer in use.
abstract base class Service<TParams extends Object?> {
  /// Creates an uninitialized instance. Must call [initService]
  /// before using this service.
  Service();

  CompleterOr<void>? _initializedCompleter;

  /// Completes after initialized via [initService].
  @pragma('vm:prefer-inline')
  FutureOr<void> get initializedFuture => _initializedCompleter?.futureOr;

  /// Whether this service has been initialized.
  bool get initialized => _initializedCompleter?.isCompleted ?? false;

  /// Initializes this service. Calls [onInitService] then completes
  /// [initializedFuture].
  ///
  /// This method must be called before interacting with the
  /// service.
  ///
  /// Do not override this method. Instead, override [onInitService].
  @nonVirtual
  FutureOr<void> initService([TParams? params]) {
    if (initialized) {
      throw ServiceAlreadyInitializedException();
    }

    _initializedCompleter = CompleterOr<void>();
    return concur(
      concur(
        beforeOnInitService(params),
        (_) => onInitService(params),
      ),
      (_) => _initializedCompleter!.complete(null),
    );
  }

  @protected
  @nonVirtual
  FutureOr<void> beforeOnInitService(TParams? params) {}

  /// Override to define any necessary initialization to be called immediately
  /// after [initService].
  ///
  /// This method should not be called directly.
  @protected
  FutureOr<void> onInitService(TParams? params);

  /// Disposes of this service, making it unusable and ready for garbage
  /// collection. Calls [onDispose].
  ///
  /// This method must be called when the service is no longer needed.
  ///
  /// Do not override this method. Instead, override [onDispose].
  ///
  /// Do not call this method directly. Use [DI.registerService] or
  /// [DI.registerLazyService] which will automatically call this method
  /// on [DI.unregister].
  @protected
  @nonVirtual
  FutureOr<void> dispose() {
    if (disposed) {
      throw ServiceAlreadyDisposedException();
    }
    if (!initialized) {
      throw ServiceNotYetInitializedException();
    }
    return disposeAnyway();
  }

  @nonVirtual
  @protected
  FutureOr<void> disposeAnyway() {
    return concur(
      concur(
        beforeOnDispose(),
        (_) => onDispose(),
      ),
      (_) => disposed = true,
    );
  }

  @protected
  @nonVirtual
  FutureOr<void> beforeOnDispose() {}

  /// Whether the service has been disposed.
  @protected
  @nonVirtual
  bool disposed = false;

  /// Override to define any necessary disposal to be called immediately
  /// after [dispose].
  ///
  /// This method should not be called directly.
  @protected
  FutureOr<void> onDispose();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef NoParamsService = Service;
