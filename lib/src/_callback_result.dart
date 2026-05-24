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

/// Unwraps the return value of a user-supplied `FutureOr<void>` callback so
/// the caller can await it without losing failure information.
///
/// Callback signatures across df_di are declared as `FutureOr<void>` for
/// ergonomic reasons (so users can write `async {...}` or just `return;`),
/// but in practice it's idiomatic to also return a `Resolvable<Unit>` from
/// the same slot (e.g. `(s) => s.init()`). `Resolvable` is neither a `Future`
/// nor `void`, so a naïve `if (result is Future)` check passes Resolvables
/// through as sync — the underlying work never gets awaited, and any Err
/// result is silently dropped.
///
/// This helper closes that gap by also detecting `Resolvable` returns and
/// unwrapping them:
///
///   * a `Future` is returned as-is (caller awaits).
///   * an `Async<T>` is awaited via its underlying `.value` future; a final
///     `Err` becomes a thrown `Err` so the caller's `consec`/`Resolvable`
///     chain captures it.
///   * a `Sync<T>` carrying `Err` is treated according to [logAndSwallowSyncErr]:
///       * `false` (typical for `onRegister`): throw the `Err` so the
///         caller's outer `try/catch` converts to `Future.error`.
///       * `true` (typical for `onUnregister`): log via [Log.err] and continue
///         — mirrors how a synchronous *throw* is already treated by
///         `_fireOnUnregister`.
///   * a `Sync<T>` carrying `Ok` is a no-op (`null` returned).
///   * anything else (`null`, plain values, etc.) is a no-op.
FutureOr<void> awaitCallbackResult(
  Object? raw, {
  required bool logAndSwallowSyncErr,
  String? logContext,
}) {
  if (raw is Future) {
    return raw;
  }
  // Pattern matching on the sealed `Resolvable` family lets the compiler verify
  // we've handled both Sync and Async, and the destructuring lets us reach the
  // inner `Result` without any `.unwrap()` calls that could trip on a future
  // change to the underlying types.
  switch (raw) {
    case Async(value: final fut):
      // Async Resolvable: await and propagate Err on the resolved Result.
      return Future<void>.sync(() async {
        switch (await fut) {
          case Err<Object> err:
            throw err;
          case Ok():
            return;
        }
      });
    case Sync(value: final result):
      switch (result) {
        case Err<Object> err:
          if (logAndSwallowSyncErr) {
            Log.err(
              '${logContext ?? 'callback'} returned Sync.err: ${err.error}',
            );
            return null;
          }
          // Sync Err: throw so the caller's outer try/catch wraps as Future.error.
          throw err;
        case Ok():
          return null;
      }
    default:
      return null;
  }
}
