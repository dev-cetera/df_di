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

// Low-level DIRegistry invariants exercised through the public DI API.
// Mission-critical contracts:
//
//   • _typeIndex never references a group that no longer holds the type.
//   • Re-registering the same slot 1000 times doesn't bloat _typeIndex.
//   • Group-level removal (unregister, clear, unregisterAll) leaves the
//     registry in the same shape as a fresh instance.
//   • groupsWithTypeK is consistent with _state after any sequence of
//     register / unregister / re-register.
//   • removeGroup wipes every type-index entry for that group.
//   • Cross-group operations don't cross-contaminate type-index buckets.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

final class _A {
  const _A([this.tag = '']);
  final String tag;
}

final class _B {
  const _B();
}

final class _C {
  const _C();
}

void main() {
  // ── _typeIndex invariants ─────────────────────────────────────────────────
  group('DIRegistry._typeIndex invariants', () {
    test(
      'register/unregister 10k cycle on alternating groups leaves '
      '_typeIndex empty',
      () {
        final di = DI();
        final groups = [UniqueEntity(), UniqueEntity(), UniqueEntity()];
        for (var n = 0; n < 10000; n++) {
          final g = groups[n % groups.length];
          di.register<_A>(_A('$n'), groupEntity: g).end();
          di.unregister<_A>(groupEntity: g).end();
        }
        for (final g in groups) {
          expect(di.isRegistered<_A>(groupEntity: g), isFalse);
        }
        expect(
          di.registry.groupsWithTypeK(TypeEntity(Sync, [TypeEntity(_A)])),
          isEmpty,
        );
        // _state should have no leftover empty group slots.
        expect(di.registry.groupEntities, isEmpty);
      },
    );

    test(
      'registering 1000 distinct groups makes _typeIndex bucket for the type '
      'exactly 1000 long',
      () {
        final di = DI();
        for (var n = 0; n < 1000; n++) {
          di.register<_A>(_A('n=$n'), groupEntity: UniqueEntity()).end();
        }
        expect(
          di.registry
              .groupsWithTypeK(TypeEntity(Sync, [TypeEntity(_A)]))
              .length,
          1000,
        );
      },
    );

    test('unregistering one of N groups removes its entry from _typeIndex', () {
      final di = DI();
      final groups = List.generate(20, (_) => UniqueEntity());
      for (final g in groups) {
        di.register<_A>(_A(g.toString()), groupEntity: g).end();
      }
      // Unregister the 10th group's entry.
      di.unregister<_A>(groupEntity: groups[10], traverse: false).end();
      final remaining = di.registry
          .groupsWithTypeK(TypeEntity(Sync, [TypeEntity(_A)]))
          .toSet();
      expect(remaining.length, 19);
      expect(remaining.contains(groups[10]), isFalse);
      // All other groups still present.
      for (var i = 0; i < 20; i++) {
        if (i == 10) continue;
        expect(remaining.contains(groups[i]), isTrue);
      }
    });

    test(
      'removeGroup wipes _typeIndex entries for every type in the group',
      () {
        final di = DI();
        final g = UniqueEntity();
        di.register<_A>(const _A(), groupEntity: g).end();
        di.register<_B>(const _B(), groupEntity: g).end();
        di.register<_C>(const _C(), groupEntity: g).end();
        di.registry.removeGroup(groupEntity: g);
        for (final t in [_A, _B, _C]) {
          expect(
            di.registry.groupsWithTypeK(TypeEntity(Sync, [TypeEntity(t)])),
            isEmpty,
            reason: '_typeIndex must not leak references to a removed group',
          );
        }
        expect(di.registry.groupEntities, isNot(contains(g)));
      },
    );

    test('clear() empties both _state and _typeIndex', () {
      final di = DI();
      for (var n = 0; n < 100; n++) {
        di.register<_A>(_A('n=$n'), groupEntity: UniqueEntity()).end();
      }
      di.registry.clear();
      expect(di.registry.groupEntities, isEmpty);
      expect(
        di.registry.groupsWithTypeK(TypeEntity(Sync, [TypeEntity(_A)])),
        isEmpty,
      );
    });

    test('overwriting the same slot 1000 times keeps _typeIndex size at 1',
        () {
      final di = DI();
      final g = const DefaultEntity();
      di.register<_A>(const _A(), groupEntity: g).end();
      // re-register requires unregister first under the public API; use the
      // overwrite-by-setDependency path indirectly via repeated unregister +
      // register cycles.
      for (var n = 0; n < 1000; n++) {
        di.unregister<_A>(groupEntity: g).end();
        di.register<_A>(_A('n=$n'), groupEntity: g).end();
      }
      final groups = di.registry
          .groupsWithTypeK(TypeEntity(Sync, [TypeEntity(_A)]))
          .toList();
      expect(groups.length, 1);
      expect(groups.single, g);
    });

    test('cross-group operations do not cross-contaminate type-index buckets',
        () {
      final di = DI();
      final gA = UniqueEntity();
      final gB = UniqueEntity();
      // Same type in two groups.
      di.register<_A>(const _A('gA'), groupEntity: gA).end();
      di.register<_A>(const _A('gB'), groupEntity: gB).end();
      // Remove from gA only.
      di.unregister<_A>(groupEntity: gA, traverse: false).end();
      // gB still indexed.
      final indexed = di.registry
          .groupsWithTypeK(TypeEntity(Sync, [TypeEntity(_A)]))
          .toSet();
      expect(indexed, equals({gB}));
    });

    test(
      'unregisterAll fully empties _typeIndex for every registered type',
      () async {
        final di = DI();
        for (var n = 0; n < 50; n++) {
          final g = UniqueEntity();
          di.register<_A>(_A('a=$n'), groupEntity: g).end();
          di.register<_B>(const _B(), groupEntity: g).end();
        }
        (await di.unregisterAll().value).end();
        expect(
          di.registry.groupsWithTypeK(TypeEntity(Sync, [TypeEntity(_A)])),
          isEmpty,
        );
        expect(
          di.registry.groupsWithTypeK(TypeEntity(Sync, [TypeEntity(_B)])),
          isEmpty,
        );
        expect(di.registry.groupEntities, isEmpty);
      },
    );

    test(
      'reversedDependencies is sorted by registration index, newest first',
      () {
        final di = DI();
        final g1 = UniqueEntity();
        final g2 = UniqueEntity();
        final g3 = UniqueEntity();
        di.register<_A>(const _A('first'), groupEntity: g1).end();
        di.register<_A>(const _A('second'), groupEntity: g2).end();
        di.register<_A>(const _A('third'), groupEntity: g3).end();
        final rev = di.registry.reversedDependencies.toList();
        expect(rev.length, 3);
        // Verify metadata indices are descending (or non-incrementing).
        var lastIdx = (1 << 30);
        for (final dep in rev) {
          switch (dep.metadata) {
            case Some(value: final m):
              switch (m.index) {
                case Some(value: final idx):
                  expect(idx, lessThanOrEqualTo(lastIdx));
                  lastIdx = idx;
                case None():
              }
            case None():
          }
        }
      },
    );
  });

  // ── Snapshot semantics ────────────────────────────────────────────────────
  group('DIRegistry snapshots', () {
    test(
      'mutating the state snapshot does not affect the live registry',
      () {
        final di = DI();
        di.register<_A>(const _A()).end();
        final state = di.registry.state;
        // The map returned by `state` is a defensive copy: mutating it (if
        // permitted) must NOT corrupt the underlying registry.
        try {
          state.clear();
        } on UnsupportedError {
          // Either fully unmodifiable (preferred) or a mutable defensive
          // copy is acceptable; what's NOT acceptable is mutation that
          // leaks into the registry.
        }
        expect(
          di.registry.containsDependencyK(TypeEntity(_A)),
          isTrue,
          reason: 'snapshot mutation must not affect the registry',
        );
      },
    );

    test('groupEntities snapshot is unmodifiable', () {
      final di = DI();
      di.register<_A>(const _A()).end();
      final groups = di.registry.groupEntities;
      expect(
        () => groups.clear(),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  // ── Lookup semantics ──────────────────────────────────────────────────────
  group('DIRegistry lookup semantics', () {
    test(
      'containsDependencyK matches the registered Sync variant',
      () {
        final di = DI();
        di.register<_A>(const _A()).end();
        expect(di.registry.containsDependencyK(TypeEntity(_A)), isTrue);
      },
    );

    test(
      'containsDependencyK does NOT match a Lazy<T> when probing for T',
      () {
        final di = DI();
        di.registerLazy<_A>(() => Sync.okValue(const _A())).end();
        // Probing for raw _A should miss; probing for Lazy<_A> hits.
        expect(di.registry.containsDependencyK(TypeEntity(_A)), isFalse);
        expect(
          di.registry.containsDependencyK(TypeEntity(Lazy, [TypeEntity(_A)])),
          isTrue,
        );
      },
    );

    test(
      'unregister<_A>() does NOT remove a Lazy<_A> registration',
      () async {
        final di = DI();
        di.registerLazy<_A>(() => Sync.okValue(const _A())).end();
        // unregister<_A>() looks for an exact Sync<_A>/Async<_A> slot.
        final outcome = await di.unregister<_A>().value;
        UNSAFE:
        expect(
          outcome.unwrap().isNone(),
          isTrue,
          reason: 'nothing of type _A is registered (it is Lazy<_A>)',
        );
        // Lazy<_A> survives.
        expect(di.isRegistered<Lazy<_A>>(), isTrue);
      },
    );
  });

  // ── Async self-rewrite race ───────────────────────────────────────────────
  group('async dependency self-rewrite race', () {
    test(
      '100 concurrent getAsync of the same async dep all see the value',
      () async {
        final di = DI();
        di.register<_A>(
          Future<_A>.delayed(
            const Duration(milliseconds: 5),
            () => const _A('resolved'),
          ),
        ).end();
        final futures = List.generate(100, (_) => di.getAsyncUnsafe<_A>());
        final results = await Future.wait(futures);
        expect(results.length, 100);
        for (final r in results) {
          expect(r.tag, 'resolved');
        }
        // After all concurrent reads, the dep is now Sync.
        expect(di.isRegistered<_A>(), isTrue);
        final sync = di.getSyncOrNone<_A>();
        expect(sync.isSome(), isTrue);
      },
    );

    test(
      'concurrent getAsync against an async dep that is unregistered '
      'mid-flight does not crash the other awaiters',
      () async {
        final di = DI();
        di.register<_A>(
          Future<_A>.delayed(
            const Duration(milliseconds: 20),
            () => const _A('resolved'),
          ),
        ).end();
        // Start 5 awaiters via getAsyncUnsafe (returns a Future<_A>).
        final futures =
            List.generate(5, (_) => di.getAsyncUnsafe<_A>());
        // Unregister mid-flight — only the in-flight Async closures should
        // be affected. Other callers should still get values via the
        // captured future handle (they had already awaited their copy).
        await Future<void>.delayed(const Duration(milliseconds: 5));
        di.unregister<_A>().end();
        // None of the 5 futures should hang. Some may complete successfully
        // (because the underlying Future already resolved), some may surface
        // an error; the contract is "no hang, no zombie state".
        var settled = 0;
        for (final f in futures) {
          await f.then((_) => settled++, onError: (_, [__]) => settled++);
        }
        expect(settled, 5);
      },
    );
  });
}
