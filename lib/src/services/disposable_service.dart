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

import 'package:df_pod/df_pod.dart';
import 'package:meta/meta.dart';

import '/src/_index.g.dart';
import '/src/_utils/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An abstract class representing a service that can be initialized and disposed.
abstract class DisposableService {
  /// Creates an uninitialized instance of the service.
  /// Must call [initService] before using this service.
  DisposableService();

  /// Creates and initializes an instance of the service.
  /// The service cannot be re-initialized once initialized.
  DisposableService.initService() {
    initService();
  }

  final _initializedCompleter = CompleterOr<void>();

  /// A future that completes when the service has been initialized via [initService].
  FutureOr<void> get initialized => _initializedCompleter.futureOr;

  /// A flag indicating whether the service has been initialized.
  /// Initially `false`, becomes `true` after [initService] is called.
  P<bool> pInitialized = RootPod(false);

  /// Initializes the service. Sets [pInitialized] to `true` and completes
  /// [initialized]. This method must be called before interacting with the
  /// service.
  @nonVirtual
  FutureOr<void> initService() async {
    if (pInitialized.value) {
      throw ServiceAlreadyInitializedException();
    }
    pInitialized.asRootPod().set(true);
    _initializedCompleter.complete();
    return onInitService();
  }

  /// Called immediately after [initService] to perform any necessary
  /// initialization.
  ///
  /// This method should not be called directly.
  @protected
  FutureOr<void> onInitService() {}

  /// Disposes of the service, making it unusable and ready for garbage collection.
  /// This method should be called when the service is no longer needed.
  ///
  /// Do not call this method directly. Use [DI.registerSingletonService] or
  /// [DI.registerFactoryService] which will automatically call this methid
  /// on [DI.unregister].
  ///
  @protected
  @nonVirtual
  FutureOr<void> dispose() {
    if (pInitialized.asPodDisposable().isDisposed) {
      throw ServiceAlreadyDisposedException();
    }
    if (!pInitialized.value) {
      throw ServiceNotYetInitializedException();
    }

    return onDispose();
  }

  /// Called immediately after [dispose] to perform any necessary cleanup.
  ///
  /// This method should not be called directly.
  @protected
  FutureOr<void> onDispose() {}
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Exception thrown when interacting with a service that has already been disposed.
final class ServiceAlreadyDisposedException extends DFDIPackageException {
  ServiceAlreadyDisposedException()
      : super('Cannot interact with a DisposableService that has already been disposed.');
}

/// Exception thrown when attempting to initialize a service that has already been initialized.
final class ServiceAlreadyInitializedException extends DFDIPackageException {
  ServiceAlreadyInitializedException()
      : super('Cannot initialize a DisposableService that has already been initialized.');
}

/// Exception thrown when attempting to dispose a service that has not been initialized.
final class ServiceNotYetInitializedException extends DFDIPackageException {
  ServiceNotYetInitializedException()
      : super('Cannot dispose a DisposableService that has not yet been initialized.');
}
