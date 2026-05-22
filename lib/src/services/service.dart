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
    // Run listeners inside a single sequencer task. Listeners are chained via
    // Resolvable composition (NOT re-entrant sequencer tasks) so:
    //   • listener execution order matches declaration order, and
    //   • the state transition runs after every listener has actually run.
    // Using Resolvable.then preserves the Sync-fast-path so existing
    // consec-based onUnregister hooks keep working when listeners are sync.
    return _sequencer.then((_) {
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
        chain = chain
            .resultMap<Unit>((prev) {
              if (prev.isErr()) {
                UNSAFE:
                recordError(prev.err().unwrap());
                // eagerError: propagate Err → next `.then` is short-circuited.
                // non-eager: swallow into Ok so the next listener still runs.
                return eagerError ? prev : Ok(Unit());
              }
              return prev;
            })
            .then((_) => l(Unit()))
            .flatten();
      }

      // Final transition: depends on the chain's resolved state.
      return chain.resultMap<Option>((finalResult) {
        if (finalResult.isErr()) {
          UNSAFE:
          recordError(finalResult.err().unwrap());
        }
        if (firstError case Some(value: final err)) {
          _state = errorState;
          // Propagate the first error so callers (and `.toUnit()` chains) can
          // still detect failure even if they ignore `_state`.
          return Err(err);
        }
        if (_state == attemptState) {
          _state = successState;
          if (onSuccessMustNotThrow case Some(value: final cb)) {
            cb();
          }
        }
        return const Ok(None());
      });
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
