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

/// A base class for services that handle streaming data and require disposal.
///
/// This class is intended to be used within a Dependency Injection [DI] system.
///
/// It provides a standardized way to manage a stream and its lifecycle,
/// ensuring that resources are properly cleaned up when the service is
/// disposed.
abstract base class StreamingService<TData extends Object?,
    TParams extends Object?> extends Service<TParams> {
  //
  //
  //

  StreamController<TData>? _streamController;
  StreamSubscription<TData>? _streamSubscription;
  final initialDataCompleter = Completer<TData>();

  // Provides access to the stream managed by this service.
  @protected
  Stream<TData>? get stream => this._streamController?.stream;

  /// Override this method to provide the input stream that this service will
  /// listen to.
  Stream<TData> provideInputStream();

  /// Override this method to handle any errors that occur within the stream.
  /// The [dispose] callback allows for immediate cleanup if necessary.
  void onError(Object e, FutureOr<void> Function() dispose) {
    print('[$runtimeType] $e');
  }

  /// Initializes the service by setting up the stream controller and starting
  /// to listen to the input stream.
  @override
  void onInitService(TParams? params) {
    _streamController = StreamController<TData>.broadcast();
    _streamSubscription = provideInputStream().listen(
      pushToStream,
      onError: (Object e) => onError(e, dispose),
      // Keep the stream open even after an error. All error handling is done
      // by onError.
      cancelOnError: false,
    );
  }

  /// Pushes data into the internal stream and triggers [onPushToStream].
  @nonVirtual
  @mustCallSuper
  void pushToStream(TData data) {
    if (shouldAdd(data)) {
      _streamController!.add(data);
      onPushToStream(data);
      if (!initialDataCompleter.isCompleted) {
        initialDataCompleter.complete(data);
      }
    }
  }

  /// Override this method to define behavior that should occur immediately
  /// after data has been pushed to the stream.
  void onPushToStream(TData data) {}

  /// Override this method to define the conditions under which a data item
  /// should be added.
  bool shouldAdd(TData data) => true;

  /// Cancels the subscription to the input stream and closes the stream
  /// controller, ensuring that all resources are released. This method is
  /// called when the service is disposed.
  @override
  FutureOr<void> onDispose() async {
    await _streamSubscription?.cancel(); // Cancel the subscription
    await _streamController?.close();
    return null; // Close the stream controller
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef NoParamsStreamingService<TData extends Object>
    = StreamingService<TData, Object>;
