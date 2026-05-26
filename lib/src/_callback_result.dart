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

/// Unwraps a user-supplied callback return so the caller can await it
/// without losing failure information. Callback signatures are
/// `FutureOr<void>` but commonly return `Resolvable<Unit>` (e.g.
/// `(s) => s.init()`) — a naive `is Future` check would pass that through
/// as sync and silently drop any Err.
///
/// On `Sync` carrying `Err`: throw when [logAndSwallowSyncErr] is false
/// (onRegister contract — surface the failure) or log and continue when
/// true (onUnregister contract — never break the cleanup chain).
FutureOr<void> awaitCallbackResult(
  Object? raw, {
  required bool logAndSwallowSyncErr,
  String? logContext,
}) {
  if (raw is Future) {
    return raw;
  }
  switch (raw) {
    case Async(value: final fut):
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
          throw err;
        case Ok():
          return null;
      }
    default:
      return null;
  }
}
