//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Convenience base class for [StreamServiceMixin]. Use this if you don't
/// need to extend another class.
abstract class StreamService<TData extends Object>
    with ServiceMixin, StreamServiceMixin<TData> {
  StreamService();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Adds a managed broadcast stream to a [ServiceMixin]. Subclasses provide an
/// input stream via [provideInputStream]; the mixin wires it through a
/// broadcast controller, exposes it via [stream], and forwards every emission
/// through [pushToStream] (which runs [provideOnPushToStreamListeners] in
/// arrival order via a single per-service sequencer).
mixin StreamServiceMixin<TData extends Object> on ServiceMixin {
  //
  //
  //

  Option<SafeCompleter<TData>> _initDataCompleter = const None();

  /// Resolves with the first data point emitted on the stream after [init].
  /// Becomes `Some(Err)` if the stream is stopped before any data arrives,
  /// so callers don't hang forever.
  Option<Resolvable<TData>> get initialData =>
      _initDataCompleter.map((e) => e.resolvable());

  Option<StreamSubscription<Result<TData>>> _streamSubscription = const None();

  Option<StreamController<Result<TData>>> _streamController = const None();

  /// The broadcast stream of [Result<TData>] events. `None` before [init] and
  /// after [dispose]; otherwise wraps a broadcast controller's stream.
  Option<Stream<Result<TData>>> get stream =>
      _streamController.map((c) => c.stream);

  /// A single sequencer for all stream emissions on this service. Using one
  /// sequencer per service (rather than per `pushToStream` call) ensures
  /// listeners across emissions run in the order events arrived.
  final _pushSequencer = TaskSequencer();

  /// Incremented every time the underlying stream is (re)started. In-flight
  /// pushes captured by closure on an older epoch are dropped instead of
  /// landing in the new completer/controller.
  int _streamEpoch = 0;

  //
  //
  //

  @override
  @mustCallSuper
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) => restartStream(),
      ];

  @override
  @mustCallSuper
  TServiceResolvables<Unit> providePauseListeners(void _) {
    return [
      (_) {
        if (_streamSubscription case Some(value: final sub)) {
          sub.pause();
        }
        return Sync.okValue(Unit());
      },
    ];
  }

  @override
  @mustCallSuper
  TServiceResolvables<Unit> provideResumeListeners(void _) {
    return [
      (_) {
        if (_streamSubscription case Some(value: final sub)) {
          sub.resume();
        }
        return Sync.okValue(Unit());
      },
    ];
  }

  @override
  @mustCallSuper
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
        (_) => stopStream(),
      ];

  //
  //
  //

  /// Tears down the current stream and immediately starts a fresh one.
  /// Increments the internal epoch so in-flight pushes from the old stream
  /// are dropped instead of landing in the new controller/completer.
  Resolvable<Unit> restartStream() {
    return stopStream().then((_) => _startStream()).flatten();
  }

  //
  //
  //

  Sync<Unit> _startStream() {
    return Sync(() {
      _streamEpoch++;
      final epoch = _streamEpoch;
      final newCompleter = SafeCompleter<TData>();
      _initDataCompleter = Some(newCompleter);
      // Pre-attach a no-op error handler so that if no caller awaits
      // `initialData`, an Err resolution (either via `pushToStream` of an
      // Err data point, or via the synthetic Err raised by `stopStream`)
      // doesn't surface as an uncaught future error in the surrounding zone.
      if (newCompleter.resolvable().value case final Future<Object?> fut) {
        _attachNoOpHandler(fut);
      }
      final controller = StreamController<Result<TData>>.broadcast();
      _streamController = Some(controller);
      _streamSubscription = Some(
        provideInputStream().listen(
          (data) {
            // Drop events from a previous epoch — they belong to a stream we
            // already stopped/restarted.
            if (epoch != _streamEpoch) return;
            pushToStream(data).end();
          },
          onError: (Object error, StackTrace stack) {
            if (epoch != _streamEpoch) return;
            controller.addError(error, stack);
          },
          onDone: () {
            if (epoch != _streamEpoch) return;
            _closeController(controller);
          },
          cancelOnError: false,
        ),
      );
      return Unit();
    });
  }

  /// Attaches a no-op error handler to [f] so an unawaited Err resolution
  /// doesn't surface as an uncaught future error in the surrounding zone.
  /// Extracted so it can be called from inside `@noFutures` Sync callbacks
  /// without the lint visiting the resulting Future expression.
  void _attachNoOpHandler(Future<Object?> f) {
    f.then<void>(
      (_) {},
      onError: (_, [__]) {},
    );
  }

  /// Closes [c] as a side effect. Extracted to keep the future-typed
  /// `close()` call out of `@noFutures` Stream-subscription callbacks.
  void _closeController(StreamController<Result<TData>> c) {
    c.close();
  }

  //
  //
  //

  /// Cancels the current input subscription, closes the broadcast controller,
  /// and resolves [initialData] with an Err (so awaiters don't hang forever).
  /// Safe to call repeatedly: subsequent calls become no-ops.
  @protected
  Resolvable<Unit> stopStream() {
    final seq = TaskSequencer();
    final prevSubscription = _streamSubscription;
    _streamSubscription = const None();
    if (prevSubscription case Some(value: final sub)) {
      seq.then((prev) {
        assert(!prev.isErr(), 'stopStream: unexpected Err in seq chain: $prev');
        return Async(() async {
          final _ = await sub.cancel();
          if (prev case Err(:final error)) throw error;
          return const None();
        });
      }).end();
    }
    final prevController = _streamController;
    _streamController = const None();
    if (prevController case Some(value: final ctrl) when !ctrl.isClosed) {
      seq.then((prev) {
        assert(!prev.isErr(), 'stopStream: unexpected Err in seq chain: $prev');
        return Async(() async {
          await ctrl.close();
          if (prev case Err(:final error)) throw error;
          return const None();
        });
      }).end();
    }
    // Complete the initialData completer with an error before clearing it.
    // This ensures any code awaiting initialData won't hang forever.
    // We also pre-attach a no-op error handler so that if no caller is
    // currently awaiting initialData, Dart's uncaught-future-error reporter
    // doesn't surface the synthetic stop error to the surrounding zone.
    final prevCompleter = _initDataCompleter;
    _initDataCompleter = const None();
    if (prevCompleter case Some(value: final c) when !c.isCompleted) {
      if (c.resolvable().value case final Future<Object?> fut) {
        fut.then<void>(
          (_) {},
          onError: (_, [__]) {},
        );
      }
      c
          .resolve(
            Sync.err(Err('Stream stopped before initial data was received.')),
          )
          .end();
    }
    return seq.completion.toUnit();
  }

  //
  //
  //

  /// Forwards a [data] event into the broadcast controller and runs every
  /// listener from [provideOnPushToStreamListeners] in arrival order via the
  /// single per-service `_pushSequencer` (so emissions never interleave with
  /// each other's listener chains).
  ///
  /// Drops the push if the service is disposed or if the stream was restarted
  /// after this call captured its epoch. With [eagerError] `true`, an erroring
  /// listener short-circuits the rest of the chain for this emission.
  Resolvable<Option> pushToStream(
    Result<TData> data, {
    bool eagerError = false,
  }) {
    // Capture epoch at call-time so a push initiated against a stream that
    // has since been restarted gets dropped instead of landing in the new
    // controller / completer.
    final epochAtCall = _streamEpoch;
    return _pushSequencer.then((prev1) {
      assert(!state.didDispose());
      if (state.didDispose() || epochAtCall != _streamEpoch) {
        return Sync.result(prev1);
      }
      _pushSequencer.then((_) {
        return Resolvable(() {
          if (epochAtCall != _streamEpoch) return const None();
          if (_streamController case Some(value: final ctrl)
              when !ctrl.isClosed) {
            ctrl.add(data);
          }
          return _initDataCompleter.map(
            (e) => e.resolve(Sync.result(data)).value,
          );
        });
      }).end();
      for (final listener in provideOnPushToStreamListeners()) {
        _pushSequencer.then((prev2) {
          if (epochAtCall != _streamEpoch) {
            return Sync.result(prev2);
          }
          if (prev2 case Err(:final error)) {
            Log.err(
              '$runtimeType.pushToStream: listener chain error: $error',
            );
            if (eagerError) {
              return Sync.result(prev2);
            }
          }
          return listener(data).then((e) => prev2).flatten2();
        }).end();
      }
      return Sync.result(prev1);
    });
  }

  //
  //
  //

  /// Subclasses return the upstream input that feeds this service. Called
  /// once per `restartStream` / `init`. May return a single-subscription or
  /// broadcast stream.
  Stream<Result<TData>> provideInputStream();

  //
  //
  //

  /// Subclasses return per-emission listeners that observe every value
  /// pushed via [pushToStream] (in arrival order). Mixins must call
  /// `super.provideOnPushToStreamListeners()` and prepend/append their own
  /// listeners.
  @mustCallSuper
  TServiceResolvables<Result<TData>> provideOnPushToStreamListeners();
}
