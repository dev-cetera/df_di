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

base mixin SupportsServiceMixin on DIBase {
  FutureOr<void>
  initService<TParams extends Option, TService extends Service<TParams>>(
    TService service, {
    required TParams params,
    FutureOr<void> Function(TService stream)? onRegister,
    TOnUnregisterCallback<TService>? onUnregister,
    Entity groupEntity = const DefaultEntity(),
    bool enableUntilExactlyK = false,
  }) {
    return register<TService>(
      service,
      onRegister: (e) {
        e.params = Some(params);
        return e.init(params: params).unwrap();
      },
      onUnregister: (e) {
        final seq = SafeSequencer();
        seq.addSafe((_) => e.unwrap().dispose()).end();
        if (onUnregister != null) {
          seq.addSafe((_) {
            final result = onUnregister(e)?.value;
            if (result == null) {
              return SYNC_NONE;
            }
            return Resolvable(
              () => consec(onUnregister(e)?.value, (e) => const None()),
            );
          }).end();
        }

        return seq.last.map((e) => const None());
      },
      groupEntity: groupEntity,
      enableUntilExactlyK: enableUntilExactlyK,
    );
  }
}
