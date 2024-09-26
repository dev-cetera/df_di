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
  //
  //
  //

  Service();

  //
  //
  //

  CompleterOr<void>? _initializedCompleter;

  /// Completes after initialized via [initService].
  @pragma('vm:prefer-inline')
  FutureOr<void> get initializedFuture => _initializedCompleter?.futureOr;

  /// Whether this service has been initialized.
  bool get initialized => _initializedCompleter?.isCompleted ?? false;

  /// Initializes this service, making it ready for use.
  @nonVirtual
  FutureOr<void> initService(TParams params) {
    if (initialized) {
      throw ServiceAlreadyInitializedException();
    }
    return _initService(params);
  }

  FutureOr<void> _initService(TParams params) {
    _initializedCompleter = CompleterOr<void>();
    return consec(
      consec(
        beforeOnInitService(params),
        (_) => onInitService(params),
      ),
      (_) => _initializedCompleter!.complete(null),
    );
  }

  /// Override to define any necessary initialization to be called immediately
  /// before [onInitService].
  ///
  /// Do not call this method directly.
  @nonVirtual
  @protected
  FutureOr<void> beforeOnInitService(TParams params) {}

  /// Override to define any necessary initialization to be called immediately
  /// after [initService].
  ///
  /// Do not call this method directly.
  @protected
  FutureOr<void> onInitService(TParams params);

  //
  //
  //

  /// Resets this service to its initial state.
  FutureOr<void> resetService(TParams params) {
    return _resetService(params);
  }

  FutureOr<void> _resetService(TParams params) {
    return consec(
      _dispose(),
      (_) {
        _disposed = false;
        _initializedCompleter = null;
        return consec(
          beforeOnReset(params),
          (_) => onResetService(params),
        );
      },
    );
  }

  /// Override to define any necessary reset to be called immediately after
  /// [resetService].
  ///
  /// Do not call this method directly.
  @protected
  FutureOr<void> onResetService(TParams params);

  /// Override to define any necessary reset to be called immediately before
  /// [onResetService].
  ///
  /// Do not call this method directly.
  @nonVirtual
  @protected
  FutureOr<void> beforeOnReset(TParams params) {}

  //
  //
  //

  /// Whether the service has been disposed.
  bool get disposed => _disposed;
  bool _disposed = false;

  /// Disposes of this service, making it unusable and ready for garbage
  /// collection.
  ///
  /// Do not call this method directly.
  @protected
  @nonVirtual
  FutureOr<void> dispose() {
    if (_disposed) {
      throw ServiceAlreadyDisposedException();
    }
    if (!initialized) {
      throw ServiceNotYetInitializedException();
    }
    return _dispose();
  }

  FutureOr<void> _dispose() {
    return consec(
      consec(
        beforeOnDispose(),
        (_) => onDispose(),
      ),
      (_) => _disposed = true,
    );
  }

  /// Override to define any necessary disposal to be called immediately
  /// before [onDispose].
  ///
  /// Do not call this method directly.
  @nonVirtual
  @protected
  FutureOr<void> beforeOnDispose() {}

  /// Override to define any necessary disposal to be called immediately
  /// after [dispose].
  ///
  /// Do not call this method directly.
  @protected
  FutureOr<void> onDispose();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef NoParamsService = Service;
