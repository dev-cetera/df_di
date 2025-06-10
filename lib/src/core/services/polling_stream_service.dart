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

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A specialized [StreamService] that generates data by periodically polling a
/// data source.
///
/// This service is ideal for scenarios like checking a database for updates,
/// polling a REST API endpoint, or any other task that needs to be performed
/// on a regular interval. The polling is automatically managed by the service's
/// lifecycle (`init`, `pause`, `resume`, `dispose`).
abstract class PollingStreamService<TData extends Result> extends StreamService<TData, None> {
  PollingStreamService();

  // --- PRIVATE POLLING MEMBERS -----------------------------------------------

  Option<Timer> _timer = const None();
  bool _isPolling = false;

  // --- LIFECYCLE INTEGRATION -------------------------------------------------

  @override
  @mustCallSuper
  TServiceResolvables<None> provideInitListeners() {
    return [...super.provideInitListeners(), _startPolling];
  }

  @override
  @mustCallSuper
  TServiceResolvables<None> providePauseListeners() {
    return [...super.providePauseListeners(), _stopPolling];
  }

  @override
  @mustCallSuper
  TServiceResolvables<None> provideResumeListeners() {
    return [...super.provideResumeListeners(), _startPolling];
  }

  @override
  @mustCallSuper
  TServiceResolvables<None> provideDisposeListeners() {
    // The parent StreamService's dispose listeners are called automatically,
    // which includes our custom _stopPolling via the teardown hook.
    // We just add our specific logic here.
    return [_stopPolling, ...super.provideDisposeListeners()];
  }

  // --- CORE POLLING LOGIC ----------------------------------------------------

  /// Starts the periodic polling timer.
  Resolvable<None> _startPolling(None _) {
    // Ensure any existing timer is stopped before starting a new one.
    _stopPolling(const None());

    _timer = Some(
      Timer.periodic(providePollingInterval(), (_) async {
        // Prevent overlapping polls if a poll takes longer than the interval.
        if (_isPolling) return;
        _isPolling = true;

        try {
          final data = await onPoll();
          // The service could have been disposed while awaiting the poll.
          if (!isDisposed) {
            pushToStream(data);
          }
        } catch (e, s) {
          // Log the error and potentially push it to an error stream if needed.
          print('Error during polling for $runtimeType: $e\n$s');
        } finally {
          _isPolling = false;
        }
      }),
    );
    return const Sync.value(Ok(None()));
  }

  /// Stops the polling timer.
  Resolvable<None> _stopPolling(None _) {
    _timer.ifSome((t) => t.unwrap().cancel());
    _timer = const None();
    _isPolling = false; // Reset the polling flag.
    return const Sync.value(Ok(None()));
  }

  // --- STREAM SERVICE IMPLEMENTATION -----------------------------------------

  /// This service manages its own data source via a timer, so we provide an
  /// empty stream to satisfy the parent class's requirement.
  @override
  provideInputStream(None params) => const Stream.empty();

  // --- USER OVERRIDES --------------------------------------------------------

  ///  The asynchronous action to perform on each poll.
  ///
  /// This function will be awaited. Its successful result will be pushed
  /// to the stream.
  Future<Result<TData>> onPoll();

  /// The `Duration` to wait between each poll.
  Duration providePollingInterval();
}
