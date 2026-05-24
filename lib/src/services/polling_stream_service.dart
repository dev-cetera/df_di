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

/// Convenience base class for [PollingStreamServiceMixin]. Use this if you
/// don't need to extend another class.
abstract class PollingStreamService<TData extends Object>
    with
        ServiceMixin,
        StreamServiceMixin<TData>,
        PollingStreamServiceMixin<TData> {
  PollingStreamService();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Drives a [StreamServiceMixin]'s input stream by invoking [onPoll] on a
/// fixed [providePollingInterval]. The underlying timer is automatically
/// stopped on `pause` / `dispose` and restarted on `resume` via the
/// subscription's `onPause` / `onResume` callbacks.
mixin PollingStreamServiceMixin<TData extends Object>
    on StreamServiceMixin<TData> {
  //
  //
  //

  @override
  TResultStream<TData> provideInputStream() =>
      _pollerStream<TData>(onPoll, providePollingInterval());

  /// Subclasses implement the actual polling call (fetch / read / refresh).
  /// Invoked once on subscription and then every [providePollingInterval].
  Resolvable<TData> onPoll();

  /// Subclasses return the interval between consecutive [onPoll] invocations.
  /// The first poll fires immediately on subscription; subsequent polls fire
  /// every `providePollingInterval()` thereafter.
  Duration providePollingInterval();
}

/// Builds a single-subscription stream backed by a periodic timer. The timer
/// is driven by the controller's `onListen` / `onPause` / `onResume` /
/// `onCancel` callbacks so it pauses with the consumer and stops on cancel.
Stream<Result<T>> _pollerStream<T extends Object>(
  Resolvable<T> Function() callback,
  Duration interval,
) {
  final controller = StreamController<Result<T>>();
  Timer? timer;
  void poll() {
    if (controller.isClosed) return;
    try {
      // Bypass `Resolvable.resultMap` because `Async.resultMap` re-throws
      // on Err input and skips the callback — so an `onPoll()` that
      // resolves to Err (e.g. `Async<T>(() async { throw ... })`) would
      // silently drop the failure. Pattern-match the sealed Resolvable
      // directly so both Sync and Async paths are exhaustive and Err
      // emissions reach the listener.
      switch (callback()) {
        case Sync<T>(value: final result):
          if (!controller.isClosed) {
            controller.add(result);
          }
        case Async<T>(value: final fut):
          fut.then(
            (result) {
              if (controller.isClosed) return;
              controller.add(result);
            },
            onError: (Object e, StackTrace s) {
              if (!controller.isClosed) {
                controller.addError(e, s);
              }
            },
          );
      }
    } catch (e, s) {
      if (!controller.isClosed) {
        controller.addError(e, s);
      }
    }
  }

  void startTimer() {
    poll();
    timer = Timer.periodic(interval, (_) => poll());
  }

  void stopTimer() {
    timer?.cancel();
    timer = null;
  }

  controller
    ..onListen = startTimer
    ..onPause = stopTimer
    ..onResume = startTimer
    ..onCancel = stopTimer;
  return controller.stream;
}
