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

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A base class for services that handle streaming data and require disposal.
///
/// This class is intended to be used within a Dependency Injection [DI] system.
///
/// It provides a standardized way to manage a stream and its lifecycle,
/// ensuring that resources are properly cleaned up when the service is
/// disposed.
abstract base class StreamService<TData extends Object?, TParams extends Object?>
    extends Service<TParams> {
  //
  //
  //

  StreamService();

  CompleterOr<TData>? _initialDataCompleter;
  StreamSubscription<TData>? _streamSubscription;
  StreamController<TData>? _streamController;

  @mustCallSuper
  @override
  ServiceListeners<TParams> provideInitListeners() {
    return [
      ...super.provideInitListeners(),
      _initListener,
    ];
  }

  FutureOr<void> _initListener(TParams params) async {
    await _disposeListener(null);
    _initialDataCompleter = CompleterOr<TData>();
    _streamController = StreamController<TData>.broadcast();
    _streamSubscription = provideInputStream(params).listen(
      pushToStream,
      onError: (Object e) => onError(e, dispose),
      // Keep the stream open even after an error. All error handling is done
      // by onError.
      cancelOnError: false,
    );
    return null;
  }

  @mustCallSuper
  @override
  ServiceListeners<void> provideDisposeListeners() {
    return [
      ...super.provideDisposeListeners(),
      _disposeListener,
    ];
  }

  Future<void> _disposeListener(void _) async {
    await _streamSubscription?.cancel();
    await _streamController?.close();
    _streamSubscription = null;
    _streamController = null;
    _initialDataCompleter = null;
  }

  /// Override this method to provide the input stream that this service will
  /// listen to.
  Stream<TData> provideInputStream(TParams params);

  /// Pushes data into the internal stream and triggers.
  @nonVirtual
  @mustCallSuper
  void pushToStream(TData data) {
    if (_streamController == null || _streamController?.isClosed == true) {
      return;
    }
    if (shouldAdd(data)) {
      _streamController!.add(data);
      final completed = _initialDataCompleter?.isCompleted ?? false;
      if (!completed) {
        _initialDataCompleter?.complete(data);
      }
      provideOnPushToStreamListeners().forEach((e) => e(data));
    }
  }

  /// Override this method to handle any errors that occur within the stream.
  /// The [dispose] callback allows for immediate cleanup if necessary.
  void onError(Object e, FutureOr<void> Function() dispose) {
    print('[$runtimeType] $e');
  }

  @mustCallSuper
  ServiceListeners<TData> provideOnPushToStreamListeners();

  /// Override this method to define the conditions under which a data item
  /// should be added.
  bool shouldAdd(TData data) => true;

  /// Completes with the initial data pushed to the stream.
  FutureOr<TData>? get initialData => _initialDataCompleter?.futureOr;

  /// Provides access to the stream managed by this service.
  Stream<TData>? get stream => _streamController?.stream;
}
