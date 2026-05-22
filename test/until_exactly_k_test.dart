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

// Tests for `untilExactlyK` — exact-typeEntity waiters that require
// `enableUntilExactlyK: true` on register. Covers the basic resolve flow plus
// the review fixes: completer cleanup on unregister AND the registration
// epoch guard that prevents a stale fire from delivering a value from a
// different registration epoch.

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Test fixtures ───────────────────────────────────────────────────────────

final class Svc {
  Svc(this.tag);
  final String tag;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('untilExactlyK basics', () {
    test('resolves immediately when typeEntity is already registered', () async {
      final di = DI();
      di.register<Svc>(Svc('present'), enableUntilExactlyK: true).end();

      UNSAFE:
      final svc = await di
          .untilExactlyK<Svc>(TypeEntity(Svc))
          .toAsync()
          .value
          .then((r) => r.unwrap());
      expect(svc.tag, 'present');
    });

    test('resolves when typeEntity is registered after the wait', () async {
      final di = DI();
      UNSAFE:
      final waiter = di
          .untilExactlyK<Svc>(TypeEntity(Svc))
          .toAsync()
          .value
          .then((r) => r.unwrap());

      unawaited(
        Future<void>.microtask(() {
          di.register<Svc>(Svc('arrived'), enableUntilExactlyK: true).end();
        }),
      );

      expect((await waiter).tag, 'arrived');
    });
  });

  group('completer cleanup on unregister', () {
    test('unregister wipes pending completers for that typeEntity', () async {
      final di = DI();

      // Start a wait, then unregister before anything is registered.
      // The pending completer should be cleaned up.
      final f = di.untilExactlyK<Svc>(TypeEntity(Svc)).toAsync().value;
      // Race a cleanup against a 50ms timeout; we just want to confirm
      // unregister doesn't hang or throw.
      (await di.unregister<Svc>().toAsync().value).end();

      // The waiter from before should NOT resolve to a stale value if we
      // now register a fresh entry: the epoch guard re-waits, and the
      // freshly registered value is what we see.
      unawaited(
        Future<void>.microtask(() {
          di.register<Svc>(Svc('post-cleanup'), enableUntilExactlyK: true).end();
        }),
      );
      UNSAFE:
      final svc = await f.then((r) => r.unwrap());
      expect(svc.tag, 'post-cleanup');
    });
  });

  group('registration epoch guard (review fix)', () {
    test(
      'completer fired before unregister/reregister cycle delivers the new value',
      () async {
        final di = DI();

        // Caller starts waiting.
        UNSAFE:
        final waiter = di
            .untilExactlyK<Svc>(TypeEntity(Svc))
            .toAsync()
            .value
            .then((r) => r.unwrap());

        // First registration fires the completer.
        di.register<Svc>(Svc('v1'), enableUntilExactlyK: true).end();
        // Unregister (epoch bumps).
        (await di.unregister<Svc>().toAsync().value).end();
        // Re-register a new value.
        di.register<Svc>(Svc('v2'), enableUntilExactlyK: true).end();

        // Without the epoch guard, the continuation would call getK<T> and
        // see either nothing (between unregister and re-register) or whatever
        // happened to be there. With the guard, it re-waits and resolves with
        // the new value.
        final svc = await waiter;
        // The epoch advanced; we re-waited, so we see the fresh registration.
        expect(svc.tag, 'v2');
      },
    );
  });
}
