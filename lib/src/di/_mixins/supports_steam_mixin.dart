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

base mixin SupportsStreamServiceMixin on DIBase {
  Resolvable<TStream> initSteamService<TData extends Result,
      TParams extends Option, TStream extends StreamService<TData, TParams>>(
    TStream stream, {
    required TParams params,
    FutureOr<void> Function(TStream stream)? onRegister,
    TOnUnregisterCallback<TStream>? onUnregister,
    Entity groupEntity = const DefaultEntity(),
    bool enableUntilExactlyK = false,
  }) {
    return register<TStream>(
      stream,
      onRegister: (e) => e.init(params).unwrap(),
      onUnregister: (e) =>
          Resolvable(() => e.map((e) => e.dispose().unwrap()).unwrap()),
      groupEntity: groupEntity,
      enableUntilExactlyK: enableUntilExactlyK,
    );
  }
}
