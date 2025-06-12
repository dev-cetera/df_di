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

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A specialized [Service] that manages and exposes a stream of data.
///
/// This class is designed to handle streaming data from a source (like a backend API,
/// a WebSocket, or a database) and integrates seamlessly with the parent [Service]
/// lifecycle, including `pause`, `resume`, and `dispose`.
abstract class StreamService<TData extends Object, TParams extends Option>
    extends Service<TParams> {
  StreamService();

  // --- PRIVATE STREAMING MEMBERS ---------------------------------------------

  Option<SafeCompleter<TData>> _initialDataCompleter = const None();
  Option<StreamSubscription<Result<TData>>> _streamSubscription = const None();
  Option<StreamController<Result<TData>>> _streamController = const None();
  final _seq = SafeSequencer();

  // --- LIFECYCLE INTEGRATION -------------------------------------------------

  @override
  @mustCallSuper
  TServiceResolvables<TParams> provideInitListeners() {
    return [
      ...super.provideInitListeners(),
      _setupStream, // Setup stream resources on init.
    ];
  }

  @override
  @mustCallSuper
  TServiceResolvables<TParams> providePauseListeners() {
    return [
      ...super.providePauseListeners(),
      (_) {
        _streamSubscription.ifSome((sub) => sub.unwrap().pause());
        return const Sync.value(Ok(None()));
      },
    ];
  }

  @override
  @mustCallSuper
  TServiceResolvables<TParams> provideResumeListeners() {
    return [
      ...super.provideResumeListeners(),
      (_) {
        _streamSubscription.ifSome((sub) => sub.unwrap().resume());
        return const Sync.value(Ok(None()));
      },
    ];
  }

  @override
  @mustCallSuper
  TServiceResolvables<TParams> provideDisposeListeners() {
    return [_teardownStream, ...super.provideDisposeListeners()];
  }

  // --- CORE STREAMING LOGIC --------------------------------------------------

  /// Sets up the stream controller and subscription.
  Resolvable<None> _setupStream(TParams params) {
    return _teardownStream(params).map((_) {
      _initialDataCompleter = Some(SafeCompleter<TData>());
      final controller = StreamController<Result<TData>>.broadcast();
      _streamController = Some(controller);

      _streamSubscription = Some(
        provideInputStream(params).listen(
          pushToStream,
          onError: controller.addError,
          onDone: controller.close,
          cancelOnError: false,
        ),
      );
      return const None();
    });
  }

  /// **ROBUST & CORRECTED:** Cleans up all stream resources sequentially using `SafeSequencer`.
  /// This guarantees every cleanup step is attempted, even if prior steps fail,
  /// and propagates an aggregate `Err` of all failures.
  Resolvable<None> _teardownStream(TParams _) {
    final sub = _streamSubscription;
    _streamSubscription = const None();

    final controller = _streamController;
    _streamController = const None();

    _initialDataCompleter = const None();

    final seq = SafeSequencer();
    final errors = <Object>[];

    if (sub.isSome()) {
      seq.addSafe((_) {
        // This Resolvable will complete with Ok(None) on success, or Ok(Err) on failure,
        // but the error is also captured in the `errors` list.
        return Resolvable(
          () async {
            await sub.unwrap().cancel();
            return const None();
          },
          onError: (e) {
            errors.add(e!);
            return Err<None>(e);
          },
        );
      });
    }

    if (controller.isSome() && !controller.unwrap().isClosed) {
      seq.addSafe((_) {
        return Resolvable(
          () async {
            await controller.unwrap().close();
            return const None();
          },
          onError: (e) {
            errors.add(e!);
            return Err<None>(e);
          },
        );
      });
    }

    if (seq.isEmpty) {
      return const Sync.value(Ok(None()));
    }

    // <-- The key is to chain off the final result of the sequence.
    // The `map` block will only execute after all async tasks in the sequence have completed.
    return seq.last
        .map((_) {
          if (errors.isNotEmpty) {
            return Err(errors);
          }
          return const Ok(None());
        })
        .map((_) => const None());
  }

  /// The internal handler for new data from the input stream.
  void pushToStream(Result<TData> data) {
    if (isDisposed) return;
    _streamController.ifSome((e) => e.unwrap().add(data));
    _initialDataCompleter.ifSome((e) => e.unwrap().resolve(Sync.value(data)));
    _seq.addAllSafe(
      provideOnPushToStreamListeners().map(
        (e) =>
            (_) => e(data),
      ),
    );
  }

  // --- PUBLIC API & USER OVERRIDES -------------------------------------------

  ///  Provides the source stream of data.
  Stream<Result<TData>> provideInputStream(TParams params);

  /// Provides a list of listeners to be executed whenever new data is pushed.
  @mustCallSuper
  TServiceResolvables<Result<TData>> provideOnPushToStreamListeners() => [];

  /// A `Resolvable` that completes with the very first item of data from the stream.
  Resolvable<TData> get initialData {
    return _initialDataCompleter
        .map((e) => e.resolvable())
        .unwrapOr(
          Sync.value(
            Err('initialData accessed before the service was initialized.'),
          ),
        );
  }

  /// The public output stream that consumers can listen to.
  Option<Stream<Result<TData>>> get stream =>
      _streamController.map((c) => c.stream);
}
