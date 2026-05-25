// ignore_for_file: sendable

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

// Regression tests derived from `AUDIT.md`. Each test corresponds to a
// finding (C4, C5, C6, C7, C8, C9, H1, H2, H5, …) and is written to fail
// against the broken behaviour and pass against the fixed behaviour.

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

class _A {
  const _A();
}

class _B {
  const _B();
}

void main() {
  // ── C4: unregister(removeAll: true) must fire onUnregister for every
  //        removed dep — not just the first one.
  test(
    'C4: unregister(removeAll: true) fires onUnregister for parent AND child',
    () async {
      final parent = DI();
      final child = DI();
      child.parents.add(parent);

      final fired = <String>[];
      parent
          .register<_A>(
            const _A(),
            onUnregister: Some((_) => fired.add('parent')),
          )
          .end();
      child
          .register<_A>(
            const _A(),
            onUnregister: Some((_) => fired.add('child')),
          )
          .end();

      (await child.unregister<_A>().value).end();
      // Both must have fired exactly once.
      expect(fired, unorderedEquals(['child', 'parent']));
    },
  );

  // ── C5: unregister(traverse: false) must NOT walk parents.
  test(
    'C5: unregister(traverse: false) does not remove from parent',
    () async {
      final parent = DI();
      final child = DI();
      child.parents.add(parent);

      parent.register<_A>(const _A()).end();
      // Child has no _A registered.
      (await child.unregister<_A>(traverse: false).value).end();
      // Parent's _A must still be registered.
      expect(parent.isRegistered<_A>(), isTrue);
    },
  );

  // ── C6: until*() must NOT complete until the registered value's
  //        `onRegister` callback has finished.
  test(
    'C6: untilSuper does not resolve before onRegister has run',
    () async {
      final di = DI();
      var onRegisterDone = false;

      // Kick off the waiter BEFORE registering.
      final waiter = di.untilSuper<_A>().value;

      di.register<_A>(
        const _A(),
        onRegister: Some((_) async {
          // Simulate a slow handshake.
          await Future<void>.delayed(const Duration(milliseconds: 20));
          onRegisterDone = true;
        }),
      ).end();

      final result = await waiter;
      expect(
        onRegisterDone,
        isTrue,
        reason: 'untilSuper completed before onRegister finished — '
            'callers would observe a "ready" service whose init never ran.',
      );
      expect(result.isOk(), isTrue);
    },
  );

  // ── C6 (cont.): if onRegister throws, until*() must surface that
  //        as Err, not as Ok.
  test('C6: untilSuper surfaces onRegister error as Err', () async {
    final di = DI();
    final waiter = di.untilSuper<_A>().value;

    di.register<_A>(
      const _A(),
      onRegister: Some((_) async {
        throw StateError('handshake failed');
      }),
    ).end();

    final result = await waiter;
    expect(
      result.isErr(),
      isTrue,
      reason: 'untilSuper resolved with Ok even though onRegister threw — '
          'silently swallowed init failure.',
    );
  });

  // ── C9: resolveAll() must not loop indefinitely if onRegister
  //        registers another async dep.
  test('C9: resolveAll terminates when async deps register more async deps',
      () async {
    final di = DI();

    // Register an Async<_A> whose resolution registers another async dep.
    di.register<_A>(
      Future<_A>.delayed(const Duration(milliseconds: 5), () => const _A()),
      onRegister: Some((_) {
        di
            .register<_B>(
              Future<_B>.delayed(
                const Duration(milliseconds: 5),
                () => const _B(),
              ),
            )
            .end();
      }),
    ).end();

    final done = di.resolveAll().toAsync().value.then<void>((_) {}).timeout(
          const Duration(seconds: 1),
          onTimeout: () => throw StateError('resolveAll did not terminate'),
        );
    await done;
    // After resolveAll, both deps should be readable as Sync.
    expect(di.isRegistered<_A>(), isTrue);
    expect(di.isRegistered<_B>(), isTrue);
  });

  // ── C8: concurrent async get<T>() must not race on the registry.
  test('C8: concurrent getAsync of the same dep produces consistent value',
      () async {
    final di = DI();
    di
        .register<_A>(
          Future<_A>.delayed(
            const Duration(milliseconds: 10),
            () => const _A(),
          ),
        )
        .end();

    // Five concurrent reads.
    final futures = List.generate(5, (_) => di.getAsyncUnsafe<_A>());
    final results = await Future.wait(futures);
    expect(results.length, 5);
    // All five must return a value (no thrown unwrap-on-None from a
    // racing remove/re-register).
    for (final r in results) {
      expect(r, isA<_A>());
    }
    // After resolution the dep is still queryable.
    expect(di.isRegistered<_A>(), isTrue);
  });

  // ── C7: registering at a parent must NOT materialise unrelated child
  //        DI lazies. (children() is called from _maybeFinish on every
  //        register.)
  test(
    'C7: registering at parent does not materialise lazy children',
    () async {
      final parent = DI();
      // Create a child container that holds a Lazy<DI> whose constructor
      // bumps a counter — we'll use this counter to detect spurious
      // materialisation.
      final materialised = <String>[];
      parent.childrenContainer = Some(DI());
      UNSAFE:
      parent.childrenContainer.unwrap().registerLazy<DI>(
        () {
          materialised.add('child');
          return Sync.okValue(DI()..parents.add(parent));
        },
        groupEntity: UniqueEntity(),
      ).end();

      // Register something at the parent; the lazy child must stay unborn.
      parent.register<_A>(const _A()).end();
      expect(
        materialised,
        isEmpty,
        reason: 'Registering at the parent should not force-construct lazy '
            'child DI containers — defeats laziness, runs side-effecting '
            'constructors at the wrong time.',
      );
    },
  );

  // ── H8: until*() with `traverse: false` must not see parent registrations.
  test('H8: until(traverse: false) does not see parent registrations',
      () async {
    final parent = DI();
    final child = DI();
    child.parents.add(parent);

    // Pre-register at parent — a `traverse: true` wait would see this.
    parent.register<_A>(const _A()).end();

    // From the child, ask for _A WITHOUT traversal. Wrap in a Future-of-bool
    // so the timeout has a usable sentinel.
    final resolved = await () async {
      final fut = child
          .until<_A, _A>(traverse: false)
          .toAsync()
          .value
          .then<void>((_) {});
      try {
        await fut.timeout(const Duration(milliseconds: 100));
        return true;
      } on TimeoutException {
        return false;
      }
    }();
    expect(
      resolved,
      isFalse,
      reason:
          'until(traverse: false) resolved against the parent registration — '
          'traverse=false should ignore parents entirely.',
    );
  });

  // ── H5: until*() with a timeout must not hang forever.
  //        (This is currently impossible because the API has no timeout.
  //        The test is included as documentation of the missing capability
  //        and is skipped until the API exists.)
  test(
    'H5: untilSuper supports a timeout',
    () async {
      // Placeholder — fails until untilSuper accepts a `Duration? timeout`.
    },
    skip: 'untilSuper does not yet support a timeout parameter (H5).',
  );
}
