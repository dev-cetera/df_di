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

/// Defines the possible lifecycle states of a [Service].
enum ServiceState {
  /// The service has not been initialized.
  NOT_INITIALIZED,

  /// The service is currently executing its initialization logic.
  BUSY_INITIALIZING,

  /// The service has been successfully initialized and is running.
  INITIALIZED,

  /// The service is currently paused.
  PAUSED,

  /// The service is currently executing its pausing logic.
  BUSY_PAUSING,

  /// The service is currently executing its resuming logic.
  BUSY_RESUMING,

  /// The service is currently executing its disposal logic.
  BUSY_DISPOSING,

  /// The service has been disposed and cannot be used again.
  DISPOSED,
}

/// A base class for services that require a managed lifecycle.
///
/// This class provides a robust, state-managed structure for service
/// lifecycles (`init`, `pause`, `resume`, `dispose`), ensuring they are properly
/// and sequentially executed, even under concurrent access. It is intended for
/// use within a Dependency Injection (DI) system.
abstract class Service<TParams extends Option> {
  Service();

  /// A static hook for the DI system to properly dispose of the service upon unregistering.
  static Resolvable<None> unregister(Result<Service> serviceResult) {
    return serviceResult.isErr()
        ? SyncOk.value(const None()) // If service creation failed, do nothing.
        : serviceResult.unwrap().dispose().map((_) => const None());
  }

  // --- STATE MANAGEMENT ------------------------------------------------------

  ServiceState _state = ServiceState.NOT_INITIALIZED;

  /// The current state of the service.
  ServiceState get state => _state;

  /// Returns `true` if the service has been successfully initialized and is not paused.
  bool get isRunning => _state == ServiceState.INITIALIZED;

  /// Returns `true` if the service is currently paused.
  bool get isPaused => _state == ServiceState.PAUSED;

  /// Returns `true` if the service has been disposed or is in the process of disposing.
  bool get isDisposed => _state == ServiceState.DISPOSED || _state == ServiceState.BUSY_DISPOSING;

  /// Orchestrates all lifecycle operations to run sequentially, preventing race conditions.
  final _sequential = SafeSequential();
  late TParams _params;

  // --- INITIALIZATION (START) ------------------------------------------------

  /// Initializes the service with the given [params], making it ready for use.
  ///
  /// This operation is idempotent and will be ignored if the service is already
  /// initialized. It will throw a `StateError` if called on a disposed service.
  @nonVirtual
  Resolvable<None> init(TParams params) {
    if (state == ServiceState.INITIALIZED || state == ServiceState.BUSY_INITIALIZING) {
      return _sequential.last;
    }

    if (isDisposed) {
      return Sync.value(
        Err(
          'Cannot initialize a service that has been disposed.',
        ),
      );
    }

    _params = params;
    _sequential.addSafe((_) {
      _state = ServiceState.BUSY_INITIALIZING;
      final operation = SafeSequential()
        ..addAllSafe(
          provideInitListeners().map((listener) => (_) => listener(params)),
        );

      return operation.last.map((_) {
        _state = ServiceState.INITIALIZED;
        return const None();
      });
    });

    return _sequential.last;
  }

  /// Provides a list of listeners to be executed during initialization.
  /// Override this to add custom initialization logic.
  @mustCallSuper
  TServiceResolvables<TParams> provideInitListeners() => [];

  // --- PAUSE & RESUME --------------------------------------------------------

  /// Pauses the service.
  ///
  /// While paused, the service should halt its operations.
  /// This operation is idempotent.
  @nonVirtual
  Resolvable<None> pause() {
    if (state != ServiceState.INITIALIZED) {
      return Sync.value(
        Err(
          'Service can only be paused when it is initialized and running.',
        ),
      );
    }

    _sequential.addSafe((_) {
      _state = ServiceState.BUSY_PAUSING;
      final operation = SafeSequential()
        ..addAllSafe(
          providePauseListeners().map((listener) => (_) => listener(_params)),
        );

      return operation.last.map((_) {
        _state = ServiceState.PAUSED;
        return const None();
      });
    });

    return _sequential.last;
  }

  /// Provides a list of listeners to be executed when the service is paused.
  @mustCallSuper
  TServiceResolvables<TParams> providePauseListeners() => [];

  /// Resumes the service from a paused state.
  ///
  /// This operation is idempotent if the service is already running.
  @nonVirtual
  Resolvable<None> resume() {
    if (state != ServiceState.PAUSED) {
      return Sync.value(
        Err(
          'Service can only be resumed when it is paused.',
        ),
      );
    }

    _sequential.addSafe((_) {
      _state = ServiceState.BUSY_RESUMING;
      final operation = SafeSequential()
        ..addAllSafe(
          provideResumeListeners().map((listener) => (_) => listener(_params)),
        );

      return operation.last.map((_) {
        _state = ServiceState.INITIALIZED;
        return const None();
      });
    });

    return _sequential.last;
  }

  /// Provides a list of listeners to be executed when the service is resumed.
  @mustCallSuper
  TServiceResolvables<TParams> provideResumeListeners() => [];

  // --- DISPOSAL (STOP) -------------------------------------------------------

  /// Disposes of the service, releasing all resources.
  ///
  /// Once disposed, the service cannot be used again. This operation is idempotent.
  @nonVirtual
  Resolvable<None> dispose() {
    if (isDisposed) {
      return _sequential.last;
    }

    _sequential.addSafe((_) {
      _state = ServiceState.BUSY_DISPOSING;
      final operation = SafeSequential()
        ..addAllSafe(
          provideDisposeListeners().map((listener) => (_) => listener(_params)),
        );

      return operation.last.map((_) {
        _state = ServiceState.DISPOSED;
        return const None();
      });
    });
    return _sequential.last;
  }

  /// Provides a list of listeners to be executed during disposal.
  @mustCallSuper
  TServiceResolvables<TParams> provideDisposeListeners() => [];
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A type alias for a list of functions that take data and return a [Resolvable].
/// This is the required signature for all service listeners.
typedef TServiceResolvables<T> = List<Resolvable<None> Function(T data)>;
