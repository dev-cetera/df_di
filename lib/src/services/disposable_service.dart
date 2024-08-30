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

import 'package:df_cleanup/df_cleanup.dart';
import 'package:df_pod/df_pod.dart';
import 'package:meta/meta.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A service designed to be used with [DI] that can be initialized and disposed.
abstract base class DisposableService extends _DisposableService with WillDisposeMixin {
  /// Creates an uninitialized service instance. Must call [initService] before
  /// use.
  DisposableService();

  /// Creates and initializes a service instance. Cannot be re-initialized.
  DisposableService.initService() : super.initService();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract base class _DisposableService with DisposeMixin {
  //
  //
  //

  final _initializedCompleter = Completer<void>();

  /// Completes when this service has been initialized via [initService].
  Future<void> get initialized => _initializedCompleter.future;

  final _pInitialized = RootPod(false);

  /// Initially `false` then `true` after this service has been initialized  via [initService].
  P<bool> get pInitialized => _pInitialized;

  _DisposableService();

  _DisposableService.initService() {
    initService();
  }

  /// Initializes this service, setting [pInitialized] to `true` and completing
  /// [initialized]. Must be called before interacting with this service.
  @nonVirtual
  FutureOr<void> initService() async {
    _checkDisposed();
    await onBeforeInitService();
    await _pInitialized.set(true);
    _initializedCompleter.complete();
  }

  /// Called immediately before [initService]. Override to perform any necessary
  /// initialization but do not call this method directly.
  @protected
  FutureOr<void> onBeforeInitService() {}

  /// Disposes this service. Must be called when this service is no longer
  /// needed. This makes this service permanently unusable and ready for
  /// garbage collection.
  @nonVirtual
  @override
  FutureOr<void> dispose() async {
    _checkDisposed();
    await onBeforeDispose();
    _pInitialized.dispose();
  }

  /// Called immediately before [dispose]. Override to perform any necessary
  /// cleanup but do not call this method directly.
  @protected
  FutureOr<void> onBeforeDispose() {}

  void _checkDisposed() {
    if (_pInitialized.isDisposed) {
      throw ServiceDisposedException();
    }
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Exception thrown when attempting to interact with a service that has already been disposed.
final class ServiceDisposedException extends DFDIPackageException {
  ServiceDisposedException()
      : super('Cannot interact with a DisposableService that has already been disposed.');
}
