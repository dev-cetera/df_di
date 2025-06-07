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

import 'dart:async';
import 'dart:core';

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A base class for services that handle streaming data and require disposal.
///
/// This class provides a standardized way to manage a stream and its lifecycle,
/// ensuring that resources are properly cleaned up when the service is
/// disposed.
abstract class StreamService<TData extends Object, TParams extends Option>
    extends Service<TParams> {
  StreamService();

  // ✅ Use SafeFinisher for the initial data event.
  SafeFinisher<TData>? _initialDataFinisher;
  StreamSubscription<TData>? _streamSubscription;
  StreamController<TData>? _streamController;

  @mustCallSuper
  @override
  TServiceListeners<TParams> provideInitListeners() {
    return [...super.provideInitListeners(), _initListener];
  }

  FutureOr<void> _initListener(TParams params) {
    return consec(_disposeStreamResources(), (_) {
      _initialDataFinisher = SafeFinisher<TData>();
      _streamController = StreamController<TData>.broadcast();
      _streamSubscription = provideInputStream(params).listen(
        pushToStream,
        onError: (Object e, StackTrace s) => onError(e, s, dispose),
        cancelOnError: false,
      );
    });
  }

  @mustCallSuper
  @override
  TServiceListeners<void> provideDisposeListeners() {
    return [
      ...super.provideDisposeListeners(),
      (_) => _disposeStreamResources(),
    ];
  }

  /// Safely disposes all stream-related resources. Idempotent.
  FutureOr<void> _disposeStreamResources() {
    final sub = _streamSubscription;
    _streamSubscription = null;

    final controller = _streamController;
    _streamController = null;
    _initialDataFinisher = null;

    return consec(sub?.cancel(), (_) {
      if (controller != null && !controller.isClosed) {
        return controller.close();
      }
    });
  }

  /// Override this to provide the input stream that this service will listen to.
  Stream<TData> provideInputStream(TParams params);

  final _listenerQueue = SafeSequential();

  /// Pushes data into the internal stream and queues listeners for execution.
  ///
  /// This method returns immediately, and listeners are processed sequentially
  /// in the background, preventing back-pressure on the source stream.
  @nonVirtual
  @mustCallSuper
  void pushToStream(TData data) {
    if (_streamController == null || _streamController!.isClosed) {
      return;
    }

    if (shouldAdd(data)) {
      _streamController!.add(data);
      // ✅ Complete the finisher with the first data event.
      _initialDataFinisher?.finish(data);
      // Resolvable<Option<T>>? Function(Result<Option> previous
      _listenerQueue.addAllSafe(
        provideOnPushToStreamListeners().map((e) {
          return (_) => Resolvable(() => consec(e(data), (_) => const None()));
        }),
      );
    }
  }

  /// Override to handle errors from the source stream.
  void onError(Object e, StackTrace s, FutureOr<void> Function() dispose) {
    print('Error in StreamService source stream for $runtimeType: $e\n$s');
  }

  /// Provides listeners to be executed when data is pushed to the stream.
  @mustCallSuper
  TServiceListeners<TData> provideOnPushToStreamListeners() => [];

  /// Override to define conditions for adding a data item to the stream.
  bool shouldAdd(TData data) => true;

  /// A `FutureOr` that completes with the first data item pushed to the stream.
  Resolvable<TData> get initialData => Resolvable(() => _initialDataFinisher!.resolvable()).comb();

  /// Provides access to the broadcast stream managed by this service.
  Stream<TData>? get stream => _streamController?.stream;
}

// //.title
// // ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// //
// // Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// // source code is governed by an MIT-style license described in the LICENSE
// // file located in this project's root directory.
// //
// // See: https://opensource.org/license/mit
// //
// // ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// //.title~

// import '/src/_common.dart';

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// /// A base class for services that handle streaming data and require disposal.
// ///
// /// This class is intended to be used within a Dependency Injection [DI] system.
// ///
// /// It provides a standardized way to manage a stream and its lifecycle,
// /// ensuring that resources are properly cleaned up when the service is
// /// disposed.
// abstract class StreamService<TData extends Object?, TParams extends Option>
//     extends Service<TParams> {
//   //
//   //
//   //

//   StreamService();

//   Finisher<TData>? _initialDataCompleter;
//   StreamSubscription<TData>? _streamSubscription;
//   StreamController<TData>? _streamController;

//   @mustCallSuper
//   @override
//   TServiceListeners<TParams> provideInitListeners() {
//     return [...super.provideInitListeners(), _initListener];
//   }

//   FutureOr<void> _initListener(TParams params) async {
//     await _disposeListener(null);
//     _initialDataCompleter = Finisher<TData>();
//     _streamController = StreamController<TData>.broadcast();
//     _streamSubscription = provideInputStream(params).listen(
//       pushToStream,
//       onError: (Object e) => onError(e, dispose),
//       // Keep the stream open even after an error. All error handling is done
//       // by onError.
//       cancelOnError: false,
//     );
//     return null;
//   }

//   @mustCallSuper
//   @override
//   TServiceListeners<void> provideDisposeListeners() {
//     return [_disposeListener, ...super.provideDisposeListeners()];
//   }

//   Future<void> _disposeListener(void _) async {
//     await _streamSubscription?.cancel();
//     await _streamController?.close();
//     _streamSubscription = null;
//     _streamController = null;
//     _initialDataCompleter = null;
//   }

//   /// Override this method to provide the input stream that this service will
//   /// listen to.
//   Stream<TData> provideInputStream(TParams params);

//   /// Pushes data into the internal stream and triggers.
//   @nonVirtual
//   @mustCallSuper
//   FutureOr<void> pushToStream(TData data) {
//     if (_streamController == null || _streamController?.isClosed == true) {
//       return null;
//     }
//     if (shouldAdd(data)) {
//       _streamController!.add(data);
//       final completed = _initialDataCompleter?.isCompleted ?? false;
//       if (!completed) {
//         _initialDataCompleter?.complete(data);
//       }
//       provideOnPushToStreamListeners().forEach((e) {
//         _sequential.add(
//           (previous) {
//             return consec(e(data), (_) => const Some(None()));
//           },
//         );
//       });
//     }
//     return _sequential.last.value;
//   }

//   final _sequential = SafeSequential();

//   /// Override this method to handle any errors that occur within the stream.
//   /// The [dispose] callback allows for immediate cleanup if necessary.
//   void onError(Object e, FutureOr<void> Function() dispose) {
//     print('[$runtimeType] $e');
//   }

//   @mustCallSuper
//   TServiceListeners<TData> provideOnPushToStreamListeners() => [];

//   /// Override this method to define the conditions under which a data item
//   /// should be added.
//   bool shouldAdd(TData data) => true;

//   /// Completes with the initial data pushed to the stream.
//   FutureOr<TData>? get initialData => _initialDataCompleter?.futureOr;

//   /// Provides access to the stream managed by this service.
//   Stream<TData>? get stream => _streamController?.stream;
// }
