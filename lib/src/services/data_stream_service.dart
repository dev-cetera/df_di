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
abstract base class DataStreamService<TData extends Object?,
    TParams extends Object?> extends Service<TParams> {
  //
  //
  //

  DataStreamService();

  // --- STATE -----------------------------------------------------------------

  Completer<TData>? _initialDataCompleter;
  StreamSubscription<TData>? _streamSubscription;
  StreamController<TData>? _streamController;

  // --- INITIALIZATION OF SERVICE ---------------------------------------------

  /// Initializes the service by setting up the stream controller and starting
  /// to listen to the input stream.
  @nonVirtual
  @override
  // ignore: invalid_override_of_non_virtual_member
  FutureOr<void> beforeOnInitService(TParams params) {
    _initialDataCompleter = Completer<TData>();
    _streamController = StreamController<TData>.broadcast();
    _streamSubscription = provideInputStream(params).listen(
      pushToStream,
      onError: (Object e) => onError(e, dispose),
      // Keep the stream open even after an error. All error handling is done
      // by onError.
      cancelOnError: false,
    );
  }

  /// Override this method to provide the input stream that this service will
  /// listen to.
  Stream<TData> provideInputStream(TParams params);

  /// Pushes data into the internal stream and triggers [onPushToStream].
  @nonVirtual
  @mustCallSuper
  void pushToStream(TData data) {
    if (_streamController == null || _streamController?.isClosed == true) {
      return;
    }
    if (shouldAdd(data)) {
      _streamController!.add(data);
      onPushToStream(data);
      final completed = _initialDataCompleter?.isCompleted ?? false;
      if (!completed) {
        _initialDataCompleter?.complete(data);
      }
    }
  }

  /// Override this method to handle any errors that occur within the stream.
  /// The [dispose] callback allows for immediate cleanup if necessary.
  void onError(Object e, FutureOr<void> Function() dispose) {
    print('[$runtimeType] $e');
  }

  /// Override this method to define behavior that should occur immediately
  /// after data has been pushed to the stream.
  void onPushToStream(TData data) {}

  /// Override this method to define the conditions under which a data item
  /// should be added.
  bool shouldAdd(TData data) => true;

  /// Completes with the initial data pushed to the stream.
  Future<TData>? get initialData => _initialDataCompleter?.future;

  /// Provides access to the stream managed by this service.
  Stream<TData>? get stream => _streamController?.stream;

  // --- RESETTING OF SERVICE --------------------------------------------------

  @nonVirtual
  @override
  // ignore: invalid_override_of_non_virtual_member
  FutureOr<void> beforeOnResetService(TParams params) {
    _streamSubscription = null;
    _streamController = null;
    _initialDataCompleter = null;
  }

  // --- DISPOSAL OF SERVICE ---------------------------------------------------

  @nonVirtual
  @override
  // ignore: invalid_override_of_non_virtual_member
  FutureOr<void> beforeOnDispose() async {
    await _streamSubscription?.cancel();
    await _streamController?.close();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef StreamService<TData extends Object> = DataStreamService<TData, Object>;
