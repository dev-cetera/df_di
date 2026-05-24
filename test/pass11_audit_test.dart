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
// Audit pass 11: multi-dep unregister chains, every-cb-fires invariant.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

final class _A {
  const _A();
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // 1. Two-level hierarchy, removeAll=true: each container's onUnregister
  //    fires regardless of whether earlier ones succeeded.
  // ─────────────────────────────────────────────────────────────────────────
  group('unregister: every cb fires on hierarchy removeAll', () {
    test(
      'parent and child both registered with onUnregister — child.unregister '
      '(removeAll: true) fires BOTH callbacks',
      () async {
        final parent = DI();
        final child = DI();
        child.parents.add(parent);
        final fired = <String>[];
        parent.register<_A>(
          const _A(),
          onUnregister: Some((_) {
            fired.add('parent');
          }),
        ).end();
        child.register<_A>(
          const _A(),
          onUnregister: Some((_) {
            fired.add('child');
          }),
        ).end();
        (await child.unregister<_A>().toAsync().value).end();
        expect(fired, unorderedEquals(['parent', 'child']));
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. onUnregister callback fires with the dep's resolved Result (Ok)
  //    when the registration was successful.
  // ─────────────────────────────────────────────────────────────────────────
  group('unregister: callback receives the resolved Result', () {
    test(
      'onUnregister is called with Ok(value) when the dep was Sync-Ok',
      () async {
        final di = DI();
        Object? received;
        di.register<_A>(
          const _A(),
          onUnregister: Some((r) {
            received = r;
          }),
        ).end();
        (await di.unregister<_A>().toAsync().value).end();
        expect(received, isA<Ok<Object>>());
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Concurrent untilExactlyK waiters on the same TypeEntity — both
  //    resolve when the matching register fires.
  // ─────────────────────────────────────────────────────────────────────────
  group('untilExactlyK: concurrent waiters', () {
    test('20 concurrent waiters all resolve', () async {
      final di = DI();
      final futures = [
        for (var n = 0; n < 20; n++)
          di.untilExactlyK<_A>(TypeEntity(_A)).toAsync().value,
      ];
      di
          .register<_A>(
            const _A(),
            enableUntilExactlyK: true,
          )
          .end();
      final results = await Future.wait(futures);
      for (final r in results) {
        expect(r.isOk(), isTrue);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 4. After unregister, the completersK map is empty.
  // ─────────────────────────────────────────────────────────────────────────
  group('untilExactlyK: cleanup after resolution', () {
    test(
      'completersK is empty after the waiter resolves',
      () async {
        final di = DI();
        final fut = di.untilExactlyK<_A>(TypeEntity(_A)).toAsync().value;
        di
            .register<_A>(
              const _A(),
              enableUntilExactlyK: true,
            )
            .end();
        (await fut).end();
        // Allow microtasks to drain.
        await Future<void>.delayed(Duration.zero);
        expect(
          di.completersK[const DefaultEntity()] ?? <Object>[],
          isEmpty,
        );
      },
    );
  });
}
