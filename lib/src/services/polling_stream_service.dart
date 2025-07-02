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

abstract class PollingStreamService<TData extends Object>
    with ServiceMixin, StreamServiceMixin<TData>, PollingStreamServiceMixin<TData> {
  PollingStreamService();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

mixin PollingStreamServiceMixin<TData extends Object> on StreamServiceMixin<TData> {
  //
  //
  //

  @override
  TResultStream<TData> provideInputStream() =>
      _pollerStream<TData>(onPoll, providePollingInterval());

  Resolvable<TData> onPoll();

  Duration providePollingInterval();
}

Stream<Result<T>> _pollerStream<T extends Object>(
  Resolvable<T> Function() callback,
  Duration interval,
) {
  final controller = StreamController<Result<T>>();
  Timer? timer;
  void poll() {
    if (controller.isClosed) return;
    try {
      callback().resultMap((value) {
        if (!controller.isClosed) {
          controller.add(value);
        }
        return value;
      }).end();
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
