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

import '/src/_common.dart';

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

  // Used to avoid concurrent initialization, resetting, and disposal.
  final _sequantial = Sequential();

  // --- INITIALIZATION OF SERVICE ---------------------------------------------

  /// Whether this service has been initialized.
  bool get initialized => _initCompleter?.isCompleted ?? false;

  /// Completes after initialized via [initService].
  @pragma('vm:prefer-inline')
  FutureOr<void> get initializedFuture => _initCompleter?.futureOr;

  CompleterOr<void>? _initCompleter;

  /// Initializes and re-initializes this service, making it ready for use.
  @nonVirtual
  FutureOr<void> initService(TParams params) {
    if (_disposed) {
      throw ServiceAlreadyDisposedException();
    }
    _sequantial.addAll([
      (_) {
        // Finish completing previous initialization before starting a new one.
        return _initCompleter == null || _initCompleter!.isCompleted
            ? null
            : _initCompleter!.futureOr;
      },
      (_) {
        // Create a new initialization completer.
        return _initCompleter = CompleterOr();
      },
      (_) {
        // Initialize the service.
        _initNotifier.removeAllListeners();
        _initNotifier.addAllListeners(provideInitListeners());
        return _initNotifier.notifyListeners(params);
      },
      (_) {
        // Complete the initialization completer.
        _initCompleter!.complete(null);
      },
    ]);
    return _sequantial.last;
  }

  final _initNotifier = ServiceChangeNotifier<TParams>();

  @mustCallSuper
  List<ServiceCallback<TParams>> provideInitListeners();

  // --- RESTARTING OF SERVICE -------------------------------------------------

  late TParams _params;

  FutureOr<void> restartService(TParams params) async {
    _params = params;
    return _restartDebouncer.call();
  }

  // Used to avoid restarting the service multiple times in quick succession.
  late final _restartDebouncer = Debouncer(
    delay: Duration.zero,
    onWaited: () => initService(_params),
  );

  // --- DISPOSAL OF SERVICE ---------------------------------------------------

  /// Whether the service has been disposed.
  bool get disposed => _disposed;

  bool _disposed = false;

  final _disposeNotifier = ServiceChangeNotifier<void>();

  @mustCallSuper
  List<ServiceCallback<void>> provideDisposeListeners();

  /// Disposes of this service, making it unusable and ready for garbage
  /// collection.
  ///
  /// Do not call this method directly.
  @protected
  @nonVirtual
  FutureOr<void> dispose() {
    // Throw an exception if the service has already been disposed.
    if (_disposed) {
      throw ServiceAlreadyDisposedException();
    }
    // Throw an exception if the service has not been initialized.
    if (!initialized) {
      throw ServiceNotYetInitializedException();
    }
    _sequantial.addAll([
      (_) {
        // Finish initializing the service before attempting to dispose it.
        return _initNotifier.last;
      },
      (_) {
        // Dispose the service.
        _disposeNotifier.removeAllListeners();
        _disposeNotifier.addAllListeners(provideDisposeListeners());
        return _disposeNotifier.notifyListeners(null);
      },
      (_) {
        // Mark the service as disposed.
        _disposed = true;
      }
    ]);
    return _sequantial.last;
  }
}
