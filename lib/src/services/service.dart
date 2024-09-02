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

import 'dart:async';

import 'package:df_type/df_type.dart' show CompleterOr, ThenOrOnFutureOrX;
import 'package:meta/meta.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A base class for services that require initialization and disposal management.
///
/// This class is intended to be used within a Dependency Injection [DI] system.
///
/// It provides a standardized structure for managing the lifecycle of services,
/// ensuring they are properly initialized when needed and disposed of when no
/// longer in use.
abstract base class Service {
  /// Creates an uninitialized instance. Must call [initService]
  /// before using this service.
  Service();

  final _initialized = CompleterOr<void>();

  /// Completes after initialized via [initService].
  @pragma('vm:prefer-inline')
  FutureOr<void> get initialized => _initialized.futureOr;

  /// Initializes this service. Completes [initialized], and then calls
  /// [onInitService].
  ///
  /// This method must be called before interacting with the
  /// service.
  ///
  /// Do not override this method. Instead, override [onInitService].
  @nonVirtual
  FutureOr<void> initService() {
    if (_initialized.isCompleted) {
      throw ServiceAlreadyInitializedException();
    }
    _initialized.complete();
    return onInitService();
  }

  /// Override to define any necessary initialization to be called immediately
  /// after [initService].
  ///
  /// This method should not be called directly.
  @protected
  FutureOr<void> onInitService();

  /// Disposes of this service, making it unusable and ready for garbage
  /// collection. Calls [onDispose].
  ///
  /// This method must be called when the service is no longer needed.
  ///
  /// Do not override this method. Instead, override [onDispose].
  ///
  /// Do not call this method directly. Use [DI.registerSingletonService] or
  /// [DI.registerFactoryService] which will automatically call this methid
  /// on [DI.unregister].
  @protected
  @nonVirtual
  FutureOr<void> dispose() {
    if (_disposed) {
      throw ServiceAlreadyDisposedException();
    }
    if (!_initialized.isCompleted) {
      throw ServiceNotYetInitializedException();
    }

    return onDispose().thenOr((_) => _disposed = true);
  }

  /// Whether the service has been disposed.
  @pragma('vm:prefer-inline')
  bool get disposed => _disposed;

  bool _disposed = false;

  /// Override to define any necessary disposal to be called immediately
  /// after [dispose].
  ///
  /// This method should not be called directly.
  @protected
  FutureOr<void> onDispose() {}
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Exception thrown when interacting with a service that has already been disposed.
final class ServiceAlreadyDisposedException extends DFDIPackageException {
  ServiceAlreadyDisposedException()
      : super(
          'Cannot interact with a DisposableService that has already been disposed.',
        );
}

/// Exception thrown when attempting to initialize a service that has already been initialized.
final class ServiceAlreadyInitializedException extends DFDIPackageException {
  ServiceAlreadyInitializedException()
      : super(
          'Cannot initialize a DisposableService that has already been initialized.',
        );
}

/// Exception thrown when attempting to dispose a service that has not been initialized.
final class ServiceNotYetInitializedException extends DFDIPackageException {
  ServiceNotYetInitializedException()
      : super(
          'Cannot dispose a DisposableService that has not yet been initialized.',
        );
}
