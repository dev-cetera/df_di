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

/// Convenience base class for [ServiceMixin]. Use this if you don't need to
/// extend another class; otherwise mix in [ServiceMixin] directly.
abstract class Service with ServiceMixin {
  Service();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Adds a sequenced lifecycle (init → pause/resume* → dispose) to any class.
///
/// Subclasses provide listeners via the `provideX` hooks; the [init], [pause],
/// [resume] and [dispose] driver methods invoke them in order through a
/// [TaskSequencer] so concurrent lifecycle calls serialize cleanly.
mixin ServiceMixin {
  /// A static hook for the DI system to properly dispose of the service upon
  /// unregistering.
  static Resolvable<Unit> unregister(Result<ServiceMixin> serviceResult) {
    if (serviceResult.isErr()) {
      return syncUnit();
    }
    UNSAFE:
    return serviceResult.unwrap().dispose();
  }

  ServiceState _state = ServiceState.NOT_INITIALIZED;

  /// The current state of the service.
  ServiceState get state => _state;

  final _sequencer = TaskSequencer();

  var _didEverInitAndSuccessfully = false;

  /// `true` once [init] has completed successfully at least once for this
  /// service instance. Stays `true` even after a subsequent error or dispose.
  bool get didEverInitAndSuccessfully => _didEverInitAndSuccessfully;

  //
  //
  //

  /// Drives the service from [ServiceState.NOT_INITIALIZED] to
  /// [ServiceState.RUN_SUCCESS] by running every listener from
  /// [provideInitListeners] sequentially.
  ///
  /// Idempotent: a second call (or any call after [dispose]) returns without
  /// re-running listeners. If [eagerError] is `true` (default for init), the
  /// chain short-circuits on the first listener error; otherwise the chain
  /// continues but the final state is still [ServiceState.RUN_ERROR].
  @nonVirtual
  Resolvable<Unit> init({bool eagerError = true}) {
    return _sequencer.then((prev) {
      // Idempotency: in release (asserts stripped) we still must not re-run
      // init listeners if the service has already moved past NOT_INITIALIZED,
      // otherwise streams get double-subscribed, observers double-registered,
      // etc.
      assert(!state.didDispose());
      if (state.didDispose()) {
        return Sync.result(prev);
      }
      assert(state == ServiceState.NOT_INITIALIZED);
      if (state != ServiceState.NOT_INITIALIZED) {
        return Sync.result(prev);
      }
      return _updateState(
        providerFunction: provideInitListeners,
        eagerError: eagerError,
        attemptState: ServiceState.RUN_ATTEMPT,
        successState: ServiceState.RUN_SUCCESS,
        errorState: ServiceState.RUN_ERROR,
        phaseName: 'init',
        onSuccessMustNotThrow: Some(() {
          _didEverInitAndSuccessfully = true;
        }),
      );
    }).toUnit();
  }

  /// Subclasses return the listeners to run when [init] is called. Mixins
  /// must call `super.provideInitListeners(null)` and prepend/append their
  /// own listeners.
  @mustCallSuper
  TServiceResolvables<Unit> provideInitListeners(void _);

  //
  //
  //

  /// Transitions the service into [ServiceState.PAUSE_SUCCESS] by running
  /// listeners from [providePauseListeners]. No-op if the service is already
  /// paused or disposed. With [eagerError] `false` (default), all listeners
  /// run even if earlier ones error.
  @nonVirtual
  Resolvable<Unit> pause({bool eagerError = false}) {
    return _sequencer.then((prev) {
      assert(!state.didDispose());
      if (state.didDispose()) {
        return Sync.result(prev);
      }
      //assert(!state.didPause());
      if (state.didPause()) {
        return Sync.result(prev);
      }
      return _updateState(
        providerFunction: providePauseListeners,
        eagerError: eagerError,
        attemptState: ServiceState.PAUSE_ATTEMPT,
        successState: ServiceState.PAUSE_SUCCESS,
        errorState: ServiceState.PAUSE_ERROR,
        phaseName: 'pause',
      );
    }).toUnit();
  }

  /// Subclasses return the listeners to run when [pause] is called. Mixins
  /// must call `super.providePauseListeners(null)` and prepend/append their
  /// own listeners.
  @mustCallSuper
  TServiceResolvables<Unit> providePauseListeners(void _);

  //
  //
  //

  /// Transitions the service into [ServiceState.RESUME_SUCCESS] by running
  /// listeners from [provideResumeListeners]. No-op if the service is already
  /// in a resumed state or disposed.
  @nonVirtual
  Resolvable<Unit> resume({bool eagerError = false}) {
    return _sequencer.then((prev) {
      assert(!state.didDispose());
      if (state.didDispose()) {
        return Sync.result(prev);
      }
      //assert(!state.didResume());
      if (state.didResume()) {
        return Sync.result(prev);
      }
      return _updateState(
        providerFunction: provideResumeListeners,
        eagerError: eagerError,
        attemptState: ServiceState.RESUME_ATTEMPT,
        successState: ServiceState.RESUME_SUCCESS,
        errorState: ServiceState.RESUME_ERROR,
        phaseName: 'resume',
      );
    }).toUnit();
  }

  /// Subclasses return the listeners to run when [resume] is called. Mixins
  /// must call `super.provideResumeListeners(null)` and prepend/append their
  /// own listeners.
  @mustCallSuper
  TServiceResolvables<Unit> provideResumeListeners(void _);

  //
  //
  //

  /// Drives the service into [ServiceState.DISPOSE_SUCCESS] by running
  /// listeners from [provideDisposeListeners]. Idempotent: a second call is
  /// a no-op. Once disposed, [init]/[pause]/[resume] are all rejected.
  @nonVirtual
  Resolvable<Unit> dispose({bool eagerError = false}) {
    return _sequencer.then((prev) {
      assert(!state.didDispose());
      if (state.didDispose()) {
        return Sync.result(prev);
      }
      return _updateState(
        providerFunction: provideDisposeListeners,
        eagerError: eagerError,
        attemptState: ServiceState.DISPOSE_ATTEMPT,
        successState: ServiceState.DISPOSE_SUCCESS,
        errorState: ServiceState.DISPOSE_ERROR,
        phaseName: 'dispose',
      );
    }).toUnit();
  }

  /// Subclasses return the listeners to run when [dispose] is called. Mixins
  /// must call `super.provideDisposeListeners(null)` and prepend/append their
  /// own listeners (typically prepending teardown ahead of `super`'s base
  /// cleanup).
  @mustCallSuper
  TServiceResolvables<Unit> provideDisposeListeners(void _);

  //
  //
  //

  Resolvable<Option> _updateState({
    required TServiceResolvables<Unit> Function(void) providerFunction,
    required bool eagerError,
    required ServiceState attemptState,
    required ServiceState successState,
    required ServiceState errorState,
    required String phaseName,
    Option<void Function()> onSuccessMustNotThrow = const None(),
  }) {
    // NOTE: Do NOT wrap this body in another `_sequencer.then(...)` —
    // `init() / pause() / resume() / dispose()` already do that, so a second
    // sequencer hop here re-enters the same sequencer while the outer task
    // is mid-`_executeStep`. Inside that nested call `_sequencer.then` would
    // return the OUTER `_current` (a lazy Async that's currently computing),
    // and `combine2` would try to await it — a self-referential deadlock that
    // only triggers when there's a previously-resolved Async in `_current`
    // (i.e. after an awaited prior lifecycle phase). Listeners are chained
    // via Resolvable composition instead.
    _state = attemptState;
    Option<Object> firstError = const None();

    void recordError(Object error) {
      if (firstError case None()) {
        firstError = Some(error);
        // Surface listener failures even in release (asserts stripped).
        Log.err(
          '$runtimeType.$phaseName: listener failed: $error',
        );
      }
      // Transition state immediately so that even if the assert below
      // throws in debug, callers (and the surrounding chain) still see the
      // correct error state.
      _state = errorState;
      assert(false, error);
    }

    Resolvable<Unit> chain = Sync.okValue(Unit());
    for (final listener in providerFunction(null)) {
      final l = listener;
      chain = _chainListener(
        prev: chain,
        listener: l,
        eagerError: eagerError,
        recordError: recordError,
      );
    }

    // Final transition: depends on the chain's resolved state.
    return _finalizeChain(
      chain: chain,
      recordError: recordError,
      firstError: () => firstError,
      attemptState: attemptState,
      successState: successState,
      errorState: errorState,
      onSuccessMustNotThrow: onSuccessMustNotThrow,
    );
  }

  /// Chains [listener] onto [prev], handling [prev]'s Result for both
  /// `Ok` and `Err`. `Async.resultMap` and `Async.then` re-throw on Err
  /// without firing their callback — this helper splits the Sync and
  /// Async paths so `recordError` fires for both cases without adding
  /// unnecessary microtasks on the Sync fast-path.
  Resolvable<Unit> _chainListener({
    required Resolvable<Unit> prev,
    required Resolvable<Unit> Function(Unit) listener,
    required bool eagerError,
    required void Function(Object) recordError,
  }) {
    if (prev is Sync<Unit>) {
      // Sync.resultMap fires the callback for Ok AND Err. Use it to keep
      // the fast path identical to the pre-fix behaviour. Call `.then`
      // through `asResolvable()` so the compile-time dispatch goes to
      // `Resolvable.then` (public) rather than `Sync.then` (protected).
      return prev
          .resultMap<Unit>((prevResult) {
            if (prevResult.isErr()) {
              UNSAFE:
              recordError(prevResult.err().unwrap());
              if (eagerError) {
                return prevResult;
              }
              return Ok(Unit());
            }
            return prevResult;
          })
          .asResolvable()
          .then((_) => listener(Unit()))
          .flatten();
    }
    // Async prev. Async.resultMap / Async.then re-throw on Err WITHOUT
    // firing their callback, so we must unwrap the Future manually to
    // record the Err and (in non-eager mode) continue the chain.
    return Async<Unit>(() async {
      final prevResult = await prev.value;
      if (prevResult.isErr()) {
        UNSAFE:
        recordError(prevResult.err().unwrap());
        if (eagerError) {
          UNSAFE:
          throw prevResult.err().unwrap();
        }
      }
      final listenerResult = await listener(Unit()).value;
      if (listenerResult.isErr()) {
        UNSAFE:
        throw listenerResult.err().unwrap();
      }
      return Unit();
    });
  }

  /// Final stage of `_updateState`: capture the chain's resolved Result,
  /// run `recordError` for any uncaptured Err, and transition `_state` to
  /// `successState` or `errorState` based on whether `firstError` was set.
  /// Splits Sync/Async paths to avoid extra microtask delays on the
  /// sync fast-path.
  Resolvable<Option> _finalizeChain({
    required Resolvable<Unit> chain,
    required void Function(Object) recordError,
    required Option<Object> Function() firstError,
    required ServiceState attemptState,
    required ServiceState successState,
    required ServiceState errorState,
    required Option<void Function()> onSuccessMustNotThrow,
  }) {
    Result<Option> applyResult(Result<Unit> finalResult) {
      if (finalResult.isErr()) {
        UNSAFE:
        recordError(finalResult.err().unwrap());
      }
      if (firstError() case Some(value: final err)) {
        _state = errorState;
        return Err<Option>(err);
      }
      if (_state == attemptState) {
        _state = successState;
        if (onSuccessMustNotThrow case Some(value: final cb)) {
          cb();
        }
      }
      return const Ok<Option>(None());
    }

    if (chain is Sync<Unit>) {
      return chain.resultMap<Option>(applyResult);
    }
    return Async<Option>(() async {
      final finalResult = await chain.value;
      final mapped = applyResult(finalResult);
      if (mapped.isErr()) {
        UNSAFE:
        throw mapped.err().unwrap();
      }
      UNSAFE:
      return mapped.unwrap();
    });
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// List of listeners returned by the `provideX` hooks. Each listener receives
/// data of type [TParams] (typically `Unit`) and returns a [Resolvable<Unit>].
typedef TServiceResolvables<TParams>
    = List<Resolvable<Unit> Function(TParams data)>;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Full lifecycle state for a [ServiceMixin]. Each lifecycle phase has three
/// substates: `_ATTEMPT` (listeners running), `_SUCCESS` (all listeners ran
/// cleanly), and `_ERROR` (at least one listener errored).
enum ServiceState {
  //
  //
  //

  NOT_INITIALIZED,
  RUN_ATTEMPT,
  RUN_SUCCESS,
  RUN_ERROR,
  PAUSE_ATTEMPT,
  PAUSE_SUCCESS,
  PAUSE_ERROR,
  RESUME_ATTEMPT,
  RESUME_SUCCESS,
  RESUME_ERROR,
  DISPOSE_ATTEMPT,
  DISPOSE_SUCCESS,
  DISPOSE_ERROR;

  //
  //
  //

  /// `true` only when the service has not yet been initialized.
  bool get isNotInitialized => this == ServiceState.NOT_INITIALIZED;

  //
  //
  //

  /// `true` if the service is in any of the RUN substates
  /// (attempt / success / error).
  bool didRun() => [
        ServiceState.RUN_ATTEMPT,
        ServiceState.RUN_SUCCESS,
        ServiceState.RUN_ERROR,
      ].contains(this);

  /// `true` if the service is in any of the PAUSE substates.
  bool didPause() => [
        ServiceState.PAUSE_ATTEMPT,
        ServiceState.PAUSE_SUCCESS,
        ServiceState.PAUSE_ERROR,
      ].contains(this);

  /// `true` if the service is in any of the RESUME substates.
  bool didResume() => [
        ServiceState.RESUME_ATTEMPT,
        ServiceState.RESUME_SUCCESS,
        ServiceState.RESUME_ERROR,
      ].contains(this);

  /// `true` if the service is in any of the DISPOSE substates. Once `true`,
  /// the service is terminal — no further lifecycle transitions are allowed.
  bool didDispose() => [
        ServiceState.DISPOSE_ATTEMPT,
        ServiceState.DISPOSE_SUCCESS,
        ServiceState.DISPOSE_ERROR,
      ].contains(this);
}
