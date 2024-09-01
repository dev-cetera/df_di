// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:meta/meta.dart';
import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A base class for services that handle streaming data and require disposal.
///
/// This class is intended to be used within a Dependency Injection [DI] system.
///
/// It provides a standardized way to manage a stream and its lifecycle,
/// ensuring that resources are properly cleaned up when the service is
/// disposed.
abstract base class StreamingService<T> extends Service {
  //
  //
  //

  StreamController<T>? _streamController;
  StreamSubscription<T>? _streamSubscription;

  // Provides access to the stream managed by this service.
  @protected
  Stream<T>? get stream => this._streamController?.stream;

  /// Override this method to provide the input stream that this service will
  /// listen to.
  Stream<T> provideInputStream();

  /// Override this method to handle any errors that occur within the stream.
  /// The [dispose] callback allows for immediate cleanup if necessary.
  void onError(Object? e, FutureOr<void> Function() dispose) {
    if (kDebugMode) {
      debugPrint('[$runtimeType] $e');
    }
  }

  /// Initializes the service by setting up the stream controller and starting
  /// to listen to the input stream.
  @override
  void onInitService() {
    _streamController = StreamController<T>.broadcast();
    _streamSubscription = provideInputStream().listen(
      pushToStream,
      onError: (Object? e) => onError(e, dispose),
      // Keep the stream open even after an error. All error handling is done
      // by onError.
      cancelOnError: false,
    );
  }

  /// Pushes data into the internal stream and triggers [onPushToStream].
  @nonVirtual
  @mustCallSuper
  void pushToStream(T data) {
    if (shouldAdd(data)) {
      _streamController!.add(data);
      onPushToStream(data);
    }
  }

  /// Override this method to define behavior that should occur immediately
  /// after data has been pushed to the stream.
  void onPushToStream(T data) {}

  /// Override this method to define the conditions under which a data item
  /// should be added.
  bool shouldAdd(T data) => true;

  /// Cancels the subscription to the input stream and closes the stream
  /// controller, ensuring that all resources are released. This method is
  /// called when the service is disposed.
  @override
  FutureOr<void> onDispose() async {
    await _streamSubscription?.cancel(); // Cancel the subscription
    await _streamController?.close(); // Close the stream controller
  }
}
