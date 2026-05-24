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
// Audit pass 5: hierarchy cycles, completer-map leaks, and other
// out-of-the-norm shapes the package should survive.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

final class _A {
  const _A();
}

final class _B {
  const _B();
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // 1. Cycle in `.parents`: a → b → a. Operations must not infinite-loop.
  // ─────────────────────────────────────────────────────────────────────────
  group('hierarchy: cycle detection', () {
    test(
      'cyclic parent relationship — isRegistered does not infinite-loop',
      () {
        final a = DI();
        final b = DI();
        a.parents.add(b);
        b.parents.add(a);
        // No-one has registered _A. The lookup must terminate (not stack
        // overflow).
        var didReturn = false;
        try {
          a.isRegistered<_A>();
          didReturn = true;
        } on StackOverflowError {
          didReturn = false;
        }
        expect(
          didReturn,
          isTrue,
          reason: 'isRegistered on a cyclic parent graph must terminate — '
              'currently it stack-overflows because there is no visited-set '
              'guard.',
        );
      },
    );

    test(
      'cyclic parent relationship — getDependency does not infinite-loop',
      () {
        final a = DI();
        final b = DI();
        a.parents.add(b);
        b.parents.add(a);
        var didReturn = false;
        try {
          a.getDependency<_A>().end();
          didReturn = true;
        } on StackOverflowError {
          didReturn = false;
        }
        expect(didReturn, isTrue);
      },
    );

    test(
      'cyclic parent relationship — untilSuper does not infinite-loop',
      () async {
        final a = DI();
        final b = DI();
        a.parents.add(b);
        b.parents.add(a);
        // untilSuper goes through getSyncOrNone<ReservedSafeCompleter<...>>
        // which traverses parents. Cycle would stack-overflow.
        var didReturn = false;
        try {
          a.untilSuper<_A>().end();
          didReturn = true;
        } on StackOverflowError {
          didReturn = false;
        }
        expect(didReturn, isTrue);
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. untilExactlyK completer hygiene: a never-completed waiter leaves
  //    the completer in `completersK`. Either the API exposes cleanup, or
  //    `registry.clear()` should drop these too.
  // ─────────────────────────────────────────────────────────────────────────
  group('untilExactlyK completer-map hygiene', () {
    test(
      'cleanupCompleters drops the entry for a given type',
      () {
        final di = DI();
        // Start a waiter — adds a completer to completersK.
        di.untilExactlyK<_A>(TypeEntity(_A)).end();
        expect(di.completersK[const DefaultEntity()] ?? [], isNotEmpty);
        // Unregistering an unrelated type doesn't affect this.
        di.cleanupCompleters(
          TypeEntity(_B),
          groupEntity: const DefaultEntity(),
        );
        expect(di.completersK[const DefaultEntity()] ?? [], isNotEmpty);
        // Unregistering the matching type drops the entry.
        di.cleanupCompleters(
          TypeEntity(_A),
          groupEntity: const DefaultEntity(),
        );
        final remaining = di.completersK[const DefaultEntity()] ?? [];
        expect(remaining, isEmpty);
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 3. unregisterChild for a non-existent child — Err, not throw.
  // ─────────────────────────────────────────────────────────────────────────
  group('children: unregister non-existent child', () {
    test('unregisterChild before any child container is set up returns Err',
        () {
      final di = DI();
      final r = di.unregisterChild();
      expect(r.isErr(), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Re-registering the SAME instance under the same type is rejected
  //    (the slot is already occupied — same instance is still a duplicate).
  // ─────────────────────────────────────────────────────────────────────────
  group('register: same instance twice', () {
    test('registering the same instance twice produces Err on the second', () {
      final di = DI();
      const a = _A();
      final r1 = di.register<_A>(a);
      final r2 = di.register<_A>(a);
      // r1 is the first registration's Resolvable (Ok).
      // r2 is Err because slot is taken.
      expect(r1.isSync(), isTrue);
      UNSAFE:
      expect(r2.sync().unwrap().value.isErr(), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 5. unregister returning the unregistered value: the Resolvable should
  //    carry the value to onUnregister callbacks (already partially tested).
  // ─────────────────────────────────────────────────────────────────────────
  group('unregister return value carries the dep', () {
    test('Ok(Some(value)) on successful unregister', () async {
      final di = DI();
      di.register<_A>(const _A()).end();
      final r = await di.unregister<_A>().toAsync().value;
      expect(r.isOk(), isTrue);
      UNSAFE:
      expect(r.unwrap().isSome(), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 6. Multiple childrenContainers: setting a new childrenContainer
  //    must NOT silently drop the old one — caller's responsibility, but
  //    the package should at least allow inspection.
  // ─────────────────────────────────────────────────────────────────────────
  group('childrenContainer replacement', () {
    test('replacing childrenContainer is observable via the field', () {
      final di = DI();
      di.childrenContainer = Some(DI());
      expect(di.childrenContainer.isSome(), isTrue);
      di.childrenContainer = const None();
      expect(di.childrenContainer.isNone(), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 7. Async dep resolution converting Async to Sync — calling get<T>
  //    twice on the same Async dep does not corrupt the state.
  // ─────────────────────────────────────────────────────────────────────────
  group('async dep: serial get<T> after Sync conversion', () {
    test(
      'first get<T> converts Async→Sync; second get<T> sees the Sync',
      () async {
        final di = DI();
        di
            .register<_A>(
              Future<_A>.delayed(
                const Duration(milliseconds: 5),
                () => const _A(),
              ),
            )
            .end();
        // First get — Async, converts after await.
        UNSAFE:
        final first =
            await di.get<_A>().unwrap().toAsync().value.then((r) => r.unwrap());
        expect(first, isA<_A>());
        // After conversion, the dep is Sync.
        expect(di.getSyncOrNone<_A>().isSome(), isTrue);
        // Second get — should be Sync directly.
        UNSAFE:
        final second = di.getSyncUnsafe<_A>();
        expect(identical(first, second), isTrue);
      },
    );
  });
}
