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
//
// Audit pass 12: polling stream's onPoll Async-Err visibility, and
// other remaining edge cases.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // 1. Polling onPoll that returns Async-Err — the listener should see the
  //    Err (since `Result<TData>` is the emission type, Err IS a valid
  //    emission). Currently `Async.resultMap` re-throws on Err input and
  //    skips the controller.add, so listeners never observe poll failures.
  // ─────────────────────────────────────────────────────────────────────────
  group('polling: Async-Err onPoll', () {
    test(
      'an Async onPoll that resolves to Err must reach the listener via '
      'controller.add(Err) or controller.addError',
      () async {
        final s = _AsyncErrPoller();
        (await s.init().toAsync().value).end();
        // Let the poller tick a couple of times.
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(
          s.observedErrors,
          isNotEmpty,
          reason: 'onPoll Async-Err must be observable downstream — otherwise '
              'polling failures are silently dropped.',
        );
        (await s.dispose().toAsync().value).end();
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Polling onPoll Sync.err propagates as expected (control test).
  // ─────────────────────────────────────────────────────────────────────────
  group('polling: Sync.err onPoll', () {
    test('Sync.err is forwarded to listeners as Err data', () async {
      final s = _SyncErrPoller();
      (await s.init().toAsync().value).end();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(s.observedErrors, isNotEmpty);
      (await s.dispose().toAsync().value).end();
    });
  });
}

class _AsyncErrPoller extends PollingStreamService<int> {
  final observedErrors = <Object>[];

  @override
  Resolvable<int> onPoll() {
    return Async<int>(() async {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      throw StateError('poll failed');
    });
  }

  @override
  Duration providePollingInterval() => const Duration(milliseconds: 5);

  @override
  TServiceResolvables<Result<int>> provideOnPushToStreamListeners() => [
        (data) {
          switch (data) {
            case Ok():
              break;
            case Err(:final error):
              observedErrors.add(error);
          }
          return Sync<Unit>.okValue(Unit());
        },
      ];
}

class _SyncErrPoller extends PollingStreamService<int> {
  final observedErrors = <Object>[];

  @override
  Resolvable<int> onPoll() {
    return Sync<int>.err(Err('sync poll failure'));
  }

  @override
  Duration providePollingInterval() => const Duration(milliseconds: 5);

  @override
  TServiceResolvables<Result<int>> provideOnPushToStreamListeners() => [
        (data) {
          switch (data) {
            case Ok():
              break;
            case Err(:final error):
              observedErrors.add(error);
          }
          return Sync<Unit>.okValue(Unit());
        },
      ];
}
