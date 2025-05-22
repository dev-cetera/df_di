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

import 'package:df_debouncer/df_debouncer.dart';

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A base class for services that require initialization and disposal
/// management.
///
/// This class is intended to be used within a Dependency Injection [DI] system.
///
/// It provides a standardized structure for managing the lifecycle of services,
/// ensuring they are properly initialized when needed and disposed of when no
/// longer in use.
abstract class Service<TParams extends Option> {
  //
  //
  //

  static Resolvable<None> unregister(Result<Service> e) {
    return Resolvable(() async {
      await e.unwrap().dispose();
      return const None();
    });
  }

  //
  //
  //

  Service();

  // Used to avoid concurrent initialization, resetting, and disposal.
  final _sequential = Sequential();

  // --- INITIALIZATION OF SERVICE ---------------------------------------------

  bool _initialized = false;
  bool get initialized => _initialized;

  /// Initializes and re-initializes this service, making it ready for use.
  @nonVirtual
  FutureOr<void> init(TParams params) {
    if (_disposed) {
      throw Err('Service has already been initialized.');
    }
    _sequential.addAll([
      // Call init listeners.
      ...provideInitListeners().map(
        (e) =>
            (_) => e(params),
      ),
      (_) {
        // Mark the service as initialized.
        _initialized = true;
      },
    ]);
    return _sequential.last;
  }

  @mustCallSuper
  ServiceListeners<TParams> provideInitListeners() => [];

  // --- RESTARTING OF SERVICE -------------------------------------------------

  late TParams _params;

  @nonVirtual
  @pragma('vm:prefer-inline')
  FutureOr<void> restartService(TParams params) async {
    _params = params;
    return _restartDebouncer.call();
  }

  // Used to avoid restarting the service multiple times in quick succession.
  late final _restartDebouncer = Debouncer(
    delay: Duration.zero,
    onWaited: () => init(_params),
  );

  // --- DISPOSAL OF SERVICE ---------------------------------------------------

  /// Whether the service has been disposed.
  @pragma('vm:prefer-inline')
  bool get disposed => _disposed;

  bool _disposed = false;

  @mustCallSuper
  ServiceListeners<void> provideDisposeListeners() => [];

  /// Disposes of this service, making it unusable and ready for garbage
  /// collection.
  ///
  /// Do not call this method directly.
  @protected
  @nonVirtual
  FutureOr<void> dispose() {
    // Throw an exception if the service has already been disposed.
    if (_disposed) {
      throw Err('Service has already been disposed.');
    }
    _sequential.addAll([
      // Call dispose listeners.
      ...provideDisposeListeners().map(
        (e) =>
            (_) => e(null),
      ),
      (_) {
        // Mark the service as disposed.
        _disposed = true;
      },
    ]);
    return _sequential.last;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef ServiceListeners<T> = List<FutureOr<void> Function(T data)>;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
