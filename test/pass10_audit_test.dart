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
// Audit pass 10: untilExactlyK asymmetry & onUnregister for Err deps.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

final class _A {
  const _A([this.tag = '']);
  final String tag;
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // 1. untilExactlyK directional asymmetry (same shape as untilSuper).
  // ─────────────────────────────────────────────────────────────────────────
  group('hierarchy: untilExactlyK sees parent register', () {
    test(
      'child.untilExactlyK<_A>(...) must resolve when parent.register<_A>(...,'
      ' enableUntilExactlyK: true) fires',
      () async {
        final parent = DI();
        final child = DI();
        child.parents.add(parent);
        // Start a waiter from child BEFORE parent registers.
        final waiter = child.untilExactlyK<_A>(TypeEntity(_A)).toAsync().value;
        parent
            .register<_A>(
              const _A('from-parent'),
              enableUntilExactlyK: true,
            )
            .end();
        final result = await waiter.timeout(
          const Duration(milliseconds: 200),
          onTimeout: () => Err<_A>('child.untilExactlyK timed out'),
        );
        expect(
          result.isOk(),
          isTrue,
          reason: 'child.untilExactlyK must resolve when an ancestor registers '
              'with enableUntilExactlyK — otherwise the `completersK` map '
              'has the same directional asymmetry as the until-completer '
              'walk.',
        );
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. onUnregister for an Async-Err dep: the chain currently skips
  //    `.then((first) => ...)` because Async.then re-throws on Err input.
  //    onUnregister never fires for those callers — even though they
  //    explicitly registered an onUnregister hook to clean up.
  // ─────────────────────────────────────────────────────────────────────────
  group('unregister: onUnregister fires even for Err deps', () {
    test(
      'register a Future that rejects → onUnregister callback still fires '
      'on unregister, with an Err Result',
      () async {
        final di = DI();
        Object? receivedResult;
        di.register<_A>(
          Future<_A>.delayed(
            const Duration(milliseconds: 5),
            () => throw StateError('registration value failed'),
          ),
          onUnregister: Some((r) {
            receivedResult = r;
          }),
        ).end();
        // Wait for the Future to settle as Err.
        await Future<void>.delayed(const Duration(milliseconds: 30));
        (await di.unregister<_A>().toAsync().value).end();
        expect(
          receivedResult,
          isNotNull,
          reason: 'onUnregister must fire even for a dep whose Resolvable '
              'resolved to Err — callers register the hook precisely to '
              'clean up failed registrations.',
        );
      },
    );
  });
}
