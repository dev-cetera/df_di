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

abstract class Service {
  Service();

  /// A static hook for the DI system to properly dispose of the service upon
  /// unregistering.
  static Resolvable<Unit> unregister(Result<Service> serviceResult) {
    if (serviceResult.isErr()) {
      return syncUnit();
    }
    UNSAFE:
    return serviceResult.unwrap().dispose();
  }

  ServiceState _state = ServiceState.NOT_INITIALIZED;

  /// The current state of the service.
  ServiceState get state => _state;

  @protected
  final sequencer = SafeSequencer();

  var _didEverInitAndSuccessfully = false;
  bool get didEverInitAndSuccessfully => _didEverInitAndSuccessfully;

  //
  //
  //

  @nonVirtual
  Resolvable<Unit> init({bool eagerError = true}) {
    return sequencer.addSafe((prev) {
      assert(!state.didDispose());
      if (state.didDispose()) {
        return Sync.value(prev);
      }
      assert(state == ServiceState.NOT_INITIALIZED);
      if (state != ServiceState.NOT_INITIALIZED) {
        return Sync.value(prev);
      }
      return _updateState(
        providerFunction: provideInitListeners,
        eagerError: eagerError,
        attemptState: ServiceState.RUN_ATTEMPT,
        successState: ServiceState.RUN_SUCCESS,
        errorState: ServiceState.RUN_ERROR,
        onSuccessMustNotThrow: () {
          _didEverInitAndSuccessfully = true;
        },
      );
    }).toUnit();
  }

  @mustCallSuper
  TServiceResolvables<Unit> provideInitListeners(void _);

  //
  //
  //

  @nonVirtual
  Resolvable<Unit> pause({bool eagerError = false}) {
    return sequencer.addSafe((prev) {
      assert(!state.didDispose());
      if (state.didDispose()) {
        return Sync.value(prev);
      }
      assert(!state.didPause());
      if (state.didPause()) {
        return Sync.value(prev);
      }
      return _updateState(
        providerFunction: providePauseListeners,
        eagerError: eagerError,
        attemptState: ServiceState.PAUSE_ATTEMPT,
        successState: ServiceState.PAUSE_SUCCESS,
        errorState: ServiceState.PAUSE_ERROR,
      );
    }).toUnit();
  }

  @mustCallSuper
  TServiceResolvables<Unit> providePauseListeners(void _);

  //
  //
  //

  @nonVirtual
  Resolvable<Unit> resume({bool eagerError = false}) {
    return sequencer.addSafe((prev) {
      assert(!state.didDispose());
      if (state.didDispose()) {
        return Sync.value(prev);
      }
      assert(!state.didResume());
      if (state.didResume()) {
        return Sync.value(prev);
      }
      return _updateState(
        providerFunction: provideResumeListeners,
        eagerError: eagerError,
        attemptState: ServiceState.RESUME_ATTEMPT,
        successState: ServiceState.RESUME_SUCCESS,
        errorState: ServiceState.RESUME_ERROR,
      );
    }).toUnit();
  }

  @mustCallSuper
  TServiceResolvables<Unit> provideResumeListeners(void _);

  //
  //
  //

  @nonVirtual
  Resolvable<Unit> dispose({bool eagerError = false}) {
    return sequencer.addSafe((prev) {
      assert(!state.didDispose());
      if (state.didDispose()) {
        return Sync.value(prev);
      }
      return _updateState(
        providerFunction: provideDisposeListeners,
        eagerError: eagerError,
        attemptState: ServiceState.DISPOSE_ATTEMPT,
        successState: ServiceState.DISPOSE_SUCCESS,
        errorState: ServiceState.DISPOSE_ERROR,
      );
    }).toUnit();
  }

  @mustCallSuper
  TServiceResolvables<Unit> provideDisposeListeners(void _);

  //
  //
  //

  Resolvable<Option> _updateState({
    required TServiceResolvables<Unit> Function(void _) providerFunction,
    required bool eagerError,
    required ServiceState attemptState,
    required ServiceState successState,
    required ServiceState errorState,
    void Function()? onSuccessMustNotThrow,
  }) {
    sequencer.addSafe((prev1) {
      _state = attemptState;
      for (final listener in providerFunction(null)) {
        sequencer.addSafe((prev2) {
          switch (prev2) {
            case Err(error: final error):
              assert(false, error);
              _state = errorState;
              if (eagerError) {
                return Sync.value(prev2);
              }
            default:
          }
          return listener(Unit()).map((e) => prev2).flatten();
        }).end();
      }
      return Sync.value(prev1);
    }).end();
    return sequencer.addSafe((prev3) {
      if (_state == attemptState) {
        _state = successState;
        onSuccessMustNotThrow?.call();
      }
      return Sync.value(prev3);
    });
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TServiceResolvables<TParams> = List<Resolvable<Unit> Function(TParams data)>;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

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

  bool get isNotInitialized => this == ServiceState.NOT_INITIALIZED;

  //
  //
  //

  bool didRun() => [
        ServiceState.RUN_ATTEMPT,
        ServiceState.RUN_SUCCESS,
        ServiceState.RUN_ERROR,
      ].contains(this);
  bool didPause() => [
        ServiceState.PAUSE_ATTEMPT,
        ServiceState.PAUSE_SUCCESS,
        ServiceState.PAUSE_ERROR,
      ].contains(this);
  bool didResume() => [
        ServiceState.RESUME_ATTEMPT,
        ServiceState.RESUME_SUCCESS,
        ServiceState.RESUME_ERROR,
      ].contains(this);
  bool didDispose() => [
        ServiceState.DISPOSE_ATTEMPT,
        ServiceState.DISPOSE_SUCCESS,
        ServiceState.DISPOSE_ERROR,
      ].contains(this);
}
