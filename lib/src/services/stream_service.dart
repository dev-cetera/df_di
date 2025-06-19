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

abstract class StreamService<TData extends Object, TParams extends Object>
    extends Service<TParams> {
  //
  //
  //

  Option<SafeCompleter<TData>> _initDataCompleter = const None();
  Option<Resolvable<TData>> get initialData =>
      _initDataCompleter.map((e) => e.resolvable());

  Option<StreamSubscription<Result<TData>>> _streamSubscription = const None();

  Option<StreamController<Result<TData>>> _streamController = const None();
  Option<Stream<Result<TData>>> get stream =>
      _streamController.map((c) => c.stream);

  //
  //
  //

  StreamService();

  //
  //
  //

  @override
  @mustCallSuper
  provideInitListeners(void _) => [(_) => _startStream()];

  @override
  @mustCallSuper
  providePauseListeners(void _) {
    return [
      (_) {
        UNSAFE:
        _streamSubscription.ifSome((sub) {
          sub.unwrap().pause();
        }).end();
        return SYNC_NONE;
      },
      // Or you can do this, but its less effective:
      //(_) => _stopStream()
    ];
  }

  @override
  @mustCallSuper
  provideResumeListeners(void _) {
    return [
      (_) {
        UNSAFE:
        _streamSubscription.ifSome((sub) => sub.unwrap().resume()).end();
        return SYNC_NONE;
      },
      // Or you can do this, but its less effective:
      //(_) => _startStream()
    ];
  }

  @override
  @mustCallSuper
  provideDisposeListeners(void _) => [(_) => _stopStream()];

  //
  //
  //

  Resolvable<void> _startStream() {
    return _stopStream().map((_) {
      _initDataCompleter = Some(SafeCompleter<TData>());
      final controller = StreamController<Result<TData>>.broadcast();
      _streamController = Some(controller);
      _streamSubscription = Some(
        provideInputStream().listen(
          pushToStream,
          onError: controller.addError,
          onDone: controller.close,
          cancelOnError: false,
        ),
      );
      return const None();
    });
  }

  //
  //
  //

  Resolvable<void> _stopStream() {
    UNSAFE:
    {
      final prevSubscription = _streamSubscription;
      _streamSubscription = const None();
      if (prevSubscription.isSome()) {
        sequencer.addSafe((prev) {
          assert(!prev.isErr(), prev.err().unwrap());
          return Async(() async {
            final _ = await prevSubscription.unwrap().cancel();
            if (prev.isErr()) {
              throw prev.err().unwrap();
            }
            return const None();
          });
        }).end();
      }
      final prevController = _streamController;
      _streamController = const None();
      if (prevController.isSome() && !prevController.unwrap().isClosed) {
        sequencer.addSafe((prev) {
          assert(!prev.isErr(), prev.err().unwrap());
          return Async(() async {
            await prevController.unwrap().close();
            if (prev.isErr()) {
              throw prev.err().unwrap();
            }
            return const None();
          });
        }).end();
      }
      _initDataCompleter = const None();
      return sequencer.last;
    }
  }

  //
  //
  //

  Resolvable<Option> pushToStream(
    Result<TData> data, {
    bool eagerError = false,
  }) {
    UNSAFE:
    return sequencer.addSafe((prev1) {
      assert(!state.didDispose());
      if (state.didDispose()) {
        return Sync.value(prev1);
      }
      sequencer.addSafe((_) {
        return Resolvable(() {
          if (_streamController.isSome()) {
            _streamController.unwrap().add(data);
          }
          return _initDataCompleter.map(
            (e) => e.resolve(Sync.value(data)).value,
          );
        });
      }).end();
      provideOnPushToStreamListeners().map((listener) {
        sequencer.addSafe((prev2) {
          if (prev2.isErr()) {
            assert(prev2.isErr(), prev2.err().unwrap());
            if (eagerError) {
              return Sync.value(prev2);
            }
          }
          return listener(data).map((e) => prev2).flatten2();
        }).end();
      });
      return Sync.value(prev1);
    });
  }

  //
  //
  //

  Stream<Result<TData>> provideInputStream();

  //
  //
  //

  @mustCallSuper
  TServiceResolvables<Result<TData>> provideOnPushToStreamListeners();
}
