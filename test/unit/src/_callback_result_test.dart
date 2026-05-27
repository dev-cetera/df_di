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

// Tests for `awaitCallbackResult` — the helper that normalizes the assorted
// return shapes a user-supplied lifecycle callback may produce
// (`Future`, `Sync(Ok)`, `Sync(Err)`, `Async(Ok)`, `Async(Err)`, plain
// `null`, arbitrary objects) into a single `FutureOr<void>` the caller can
// uniformly await — while preserving failure information that a naive
// `is Future` check would silently drop.

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:df_di/src/_callback_result.dart';
import 'package:test/test.dart';

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('awaitCallbackResult', () {
    test('raw Future is returned as-is (passthrough)', () async {
      final fut = Future<void>.value();
      final result = awaitCallbackResult(
        fut,
        logAndSwallowSyncErr: false,
      );
      expect(result, isA<Future<void>>());
      // The returned object is the same Future instance (passthrough).
      expect(identical(result, fut), isTrue);
      await result;
    });

    test('Async carrying Ok completes normally when awaited', () async {
      final raw = Async<Unit>(() async => Unit());
      final result = awaitCallbackResult(
        raw,
        logAndSwallowSyncErr: false,
      );
      expect(result, isA<Future<void>>());
      await result; // must not throw
    });

    test('Async carrying Err throws when awaited', () async {
      UNSAFE:
      final raw = Async<Unit>.err(Err('async bomb'));
      final result = awaitCallbackResult(
        raw,
        logAndSwallowSyncErr: false,
      );
      expect(result, isA<Future<void>>());
      await expectLater(result, throwsA(isA<Err>()));
    });

    test('Sync carrying Ok returns null synchronously', () {
      final raw = Sync.okValue(Unit());
      final result = awaitCallbackResult(
        raw,
        logAndSwallowSyncErr: false,
      );
      // Not a Future — returns synchronously as null.
      expect(result, isNull);
    });

    test(
      'Sync carrying Err with logAndSwallowSyncErr=false throws synchronously',
      () {
        final raw = Sync<Unit>.err(Err('sync bomb'));
        expect(
          () => awaitCallbackResult(raw, logAndSwallowSyncErr: false),
          throwsA(isA<Err>()),
        );
      },
    );

    test(
      'Sync carrying Err with logAndSwallowSyncErr=true returns null '
      '(logs, does not throw)',
      () {
        final raw = Sync<Unit>.err(Err('swallowed bomb'));
        final result = awaitCallbackResult(
          raw,
          logAndSwallowSyncErr: true,
          logContext: 'test-context',
        );
        expect(result, isNull);
      },
    );

    test('null raw returns null synchronously', () {
      final result = awaitCallbackResult(
        null,
        logAndSwallowSyncErr: false,
      );
      expect(result, isNull);
    });

    test(
        'arbitrary object that is none of the recognized shapes '
        'returns null', () {
      final result = awaitCallbackResult(
        Object(),
        logAndSwallowSyncErr: false,
      );
      expect(result, isNull);
    });

    test(
        'arbitrary object also returns null when '
        'logAndSwallowSyncErr=true', () {
      final result = awaitCallbackResult(
        'a plain string',
        logAndSwallowSyncErr: true,
      );
      expect(result, isNull);
    });
  });
}
