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

import 'package:df_debouncer/df_debouncer.dart';

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

  // --- STATE -----------------------------------------------------------------

  CompleterOr<void>? _initializedCompleter;
  bool _disposed = false;

  // Used to avoid concurrent initialization, resetting, and disposal.
  final _sequantial = Sequential();

  // --- INITIALIZATION OF SERVICE ---------------------------------------------

  /// Completes after initialized via [initService].
  @pragma('vm:prefer-inline')
  FutureOr<void> get initializedFuture => _initializedCompleter?.futureOr;

  /// Whether this service has been initialized.
  bool get initialized => _initializedCompleter?.isCompleted ?? false;

  /// Initializes this service, making it ready for use.
  @nonVirtual
  FutureOr<void> initService(TParams params) {
    return _sequantial.add((_) => _initService(params));
  }

  FutureOr<void> _initService(TParams params) {
    if (initialized) {
      throw ServiceAlreadyInitializedException();
    }
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

  // --- RESETTING OF SERVICE --------------------------------------------------

  /// Resets this service to its initial state.
  FutureOr<void> resetService(TParams params) {
    return _sequantial.add((_) => _resetService(params));
  }

  FutureOr<void> _resetService(TParams params) {
    _disposed = false;
    _initializedCompleter = null;
    return consec(
      beforeOnResetService(params),
      (_) => onResetService(params),
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
  FutureOr<void> beforeOnResetService(TParams params) {}

  // --- RESTARTING OF SERVICE -------------------------------------------------

  late TParams _params;

  FutureOr<void> restartService(TParams params) async {
    _params = params;
    return _restartDebouncer.call();
  }

  // Used to avoid restarting the service multiple times in quick succession.
  late final _restartDebouncer = Debouncer(
    delay: Duration.zero,
    onWaited: () {
      if (_params != null) {
        consec(
          resetService(_params),
          (_) => initService(_params),
        );
      }
    },
  );

  // --- DISPOSAL OF SERVICE ---------------------------------------------------

  /// Whether the service has been disposed.
  bool get disposed => _disposed;

  /// Disposes of this service, making it unusable and ready for garbage
  /// collection.
  ///
  /// Do not call this method directly.
  @protected
  @nonVirtual
  FutureOr<void> dispose() {
    return _sequantial.add((_) => _dispose());
  }

  FutureOr<void> _dispose() {
    if (_disposed) {
      throw ServiceAlreadyDisposedException();
    }
    if (!initialized) {
      throw ServiceNotYetInitializedException();
    }
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
