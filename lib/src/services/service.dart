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
    return switch (serviceResult) {
      Ok(value: final service) => service.dispose(),
      Err() => syncUnit(),
    };
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
  /// Contract:
  ///
  /// * Calling [init] after [dispose] (any DISPOSE_* state) resolves to **Err**
  ///   without re-running listeners. The service is terminal and cannot be
  ///   re-initialized — callers must construct a fresh instance.
  /// * Calling [init] a second time while the service is still RUN_*/PAUSE_*/
  ///   RESUME_* resolves to **Err** without re-running listeners (idempotent —
  ///   listeners run exactly once per service lifetime).
  /// * On the first valid call: listeners run; the service transitions to
  ///   [ServiceState.RUN_ATTEMPT] during execution and then [RUN_SUCCESS] /
  ///   [RUN_ERROR] depending on outcome. If [eagerError] is `true` (default),
  ///   the chain short-circuits on the first listener error.
  ///
  /// Returning **Err** on invalid transitions (instead of silent Ok in release
  /// or AssertionError in debug) is a mission-critical reliability choice:
  /// callers checking the awaited Result can detect "init was skipped because
  /// the service is in the wrong state" without relying on asserts being on.
  @nonVirtual
  Resolvable<Unit> init({bool eagerError = true}) {
    return _sequencer.then((prev) {
      if (state.didDispose()) {
        return Sync<Option>.err(
          Err('init: cannot be called after dispose; '
              'state is $state.'),
        );
      }
      if (state != ServiceState.NOT_INITIALIZED) {
        return Sync<Option>.err(
          Err('init: already initialized; state is $state. '
              'init() runs listeners exactly once per service lifetime.'),
        );
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
  /// listeners from [providePauseListeners].
  ///
  /// Contract:
  ///
  /// * Calling [pause] before [init] (state is [NOT_INITIALIZED]) resolves to
  ///   **Err**. Pausing an uninitialized service is a lifecycle bug; without
  ///   this guard a caller could reach [PAUSE_SUCCESS] without ever running
  ///   init listeners.
  /// * Calling [pause] after [dispose] resolves to **Err** — disposed is
  ///   terminal.
  /// * Calling [pause] while already paused is a **no-op Ok** (idempotent).
  /// * Otherwise: listeners run; state transitions to [PAUSE_ATTEMPT] then
  ///   [PAUSE_SUCCESS] / [PAUSE_ERROR]. With [eagerError] `false` (default),
  ///   all listeners run even if earlier ones error.
  @nonVirtual
  Resolvable<Unit> pause({bool eagerError = false}) {
    return _sequencer.then((prev) {
      if (state.didDispose()) {
        return Sync<Option>.err(
          Err('pause: cannot be called after dispose; state is $state.'),
        );
      }
      if (state == ServiceState.NOT_INITIALIZED) {
        return Sync<Option>.err(
          Err('pause: service has not been initialized. '
              'Call init() first.'),
        );
      }
      if (state.didPause()) {
        return Sync<Option>.okValue(const None());
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
  /// listeners from [provideResumeListeners].
  ///
  /// Contract mirrors [pause]:
  ///
  /// * [NOT_INITIALIZED] → **Err** (call [init] first).
  /// * [didDispose] → **Err** (terminal state).
  /// * Already in a resumed state → **no-op Ok** (idempotent).
  /// * Otherwise: listeners run; transitions to [RESUME_ATTEMPT] then
  ///   [RESUME_SUCCESS] / [RESUME_ERROR].
  @nonVirtual
  Resolvable<Unit> resume({bool eagerError = false}) {
    return _sequencer.then((prev) {
      if (state.didDispose()) {
        return Sync<Option>.err(
          Err('resume: cannot be called after dispose; state is $state.'),
        );
      }
      if (state == ServiceState.NOT_INITIALIZED) {
        return Sync<Option>.err(
          Err('resume: service has not been initialized. '
              'Call init() first.'),
        );
      }
      if (state.didResume()) {
        return Sync<Option>.okValue(const None());
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
  /// listeners from [provideDisposeListeners].
  ///
  /// Contract:
  ///
  /// * Calling [dispose] a second time is a **no-op Ok** (idempotent).
  /// * Otherwise: listeners run; state transitions to [DISPOSE_ATTEMPT] then
  ///   [DISPOSE_SUCCESS] / [DISPOSE_ERROR].
  /// * Once disposed, [init]/[pause]/[resume] all resolve to Err (terminal).
  @nonVirtual
  Resolvable<Unit> dispose({bool eagerError = false}) {
    return _sequencer.then((prev) {
      if (state.didDispose()) {
        return Sync<Option>.okValue(const None());
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
    if (prev case Sync<Unit>()) {
      // Sync.resultMap fires the callback for Ok AND Err. Use it to keep
      // the fast path identical to the pre-fix behaviour. Call `.then`
      // through `asResolvable()` so the compile-time dispatch goes to
      // `Resolvable.then` (public) rather than `Sync.then` (protected).
      return prev
          .resultMap<Unit>(
            (prevResult) => switch (prevResult) {
              Err<Unit>(:final error) => () {
                  recordError(error);
                  return eagerError ? prevResult : Ok(Unit());
                }(),
              Ok() => prevResult,
            },
          )
          .asResolvable()
          .then((_) => listener(Unit()))
          .flatten();
    }
    // Async prev. Async.resultMap / Async.then re-throw on Err WITHOUT
    // firing their callback, so we must unwrap the Future manually to
    // record the Err and (in non-eager mode) continue the chain.
    return Async<Unit>(() async {
      switch (await prev.value) {
        case Err<Unit>(:final error):
          recordError(error);
          if (eagerError) throw error;
        case Ok():
          break;
      }
      switch (await listener(Unit()).value) {
        case Err<Unit>(:final error):
          throw error;
        case Ok():
          return Unit();
      }
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
      if (finalResult case Err<Unit>(:final error)) {
        recordError(error);
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

    if (chain case Sync<Unit>()) {
      return chain.resultMap<Option>(applyResult);
    }
    return Async<Option>(() async {
      final finalResult = await chain.value;
      return switch (applyResult(finalResult)) {
        Err<Option>(:final error) => throw error,
        Ok<Option>(value: final v) => v,
      };
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
