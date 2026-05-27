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

// ignore_for_file: sendable

// Tests for `DIRegistry` — the underlying storage map. Construction,
// setDependency/getDependency/removeDependency, group operations
// (setGroup/getGroup/removeGroup/clear), the reverse type-index
// (groupsWithTypeK/groupsWithTypeT), the onChange callback, the snapshot
// safety contract on `state` and `groupEntities`, and the strict keying
// semantics (Lazy<T> is not matched by T-keyed lookups).
//
// `DIRegistry` is not exported through the package barrel, so we import it
// via the internal path. Same convention as `_dependency_test.dart`.

import 'package:df_di/df_di.dart';
// ignore: invalid_use_of_internal_member
import 'package:df_di/src/di/_dependency.dart';
// ignore: invalid_use_of_internal_member
import 'package:df_di/src/di/_di_registry.dart';
import 'package:test/test.dart';

// ─── Test fixtures ───────────────────────────────────────────────────────────

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

// ─── Helpers ─────────────────────────────────────────────────────────────────

Dependency<T> _dep<T extends Object>(
  T value, {
  Entity groupEntity = const DefaultEntity(),
  Entity preemptivetypeEntity = const DefaultEntity(),
}) {
  return Dependency<T>(
    Sync<T>.okValue(value),
    metadata: Some(
      DependencyMetadata(
        groupEntity: groupEntity,
        preemptivetypeEntity: preemptivetypeEntity,
      ),
    ),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('DIRegistry construction', () {
    test('fresh registry has empty state', () {
      final r = DIRegistry();
      expect(r.groupEntities, isEmpty);
      expect(r.unsortedDependencies, isEmpty);
      expect(r.reversedDependencies, isEmpty);
    });

    test('onChange defaults to None', () {
      final r = DIRegistry();
      // Sanity: setDependency must not throw on a registry with no listener.
      expect(() => r.setDependency(_dep<_A>(const _A())), returnsNormally);
    });
  });

  group('setDependency / getDependency / removeDependency', () {
    test('setDependency stores a dependency under DefaultEntity', () {
      final r = DIRegistry();
      r.setDependency(_dep<_A>(const _A('x')));
      expect(r.containsDependency<_A>(), isTrue);
      switch (r.getDependency<_A>()) {
        case Some(value: final dep):
          expect(dep, isA<Dependency<_A>>());
        case None():
          fail('Expected Some<Dependency<_A>>.');
      }
    });

    test('setDependency stores under explicit groupEntity', () {
      final r = DIRegistry();
      final g = TypeEntity('grp');
      r.setDependency(_dep<_A>(const _A('x'), groupEntity: g));
      expect(r.containsDependency<_A>(groupEntity: g), isTrue);
      // Default group does NOT see the entry.
      expect(r.containsDependency<_A>(), isFalse);
    });

    test('containsDependency matches subtypes', () {
      // _A < Object — Resolvable<_A> is also Resolvable<Object>.
      final r = DIRegistry();
      r.setDependency(_dep<_A>(const _A('x')));
      expect(r.containsDependency<_A>(), isTrue);
      expect(r.containsDependency<Object>(), isTrue);
    });

    test('removeDependency removes the entry and prunes the empty group', () {
      final r = DIRegistry();
      final g = TypeEntity('grp');
      r.setDependency(_dep<_A>(const _A('x'), groupEntity: g));
      expect(r.containsDependency<_A>(groupEntity: g), isTrue);
      final removed = r.removeDependency<_A>(groupEntity: g);
      expect(removed.isSome(), isTrue);
      expect(r.containsDependency<_A>(groupEntity: g), isFalse);
      // Empty group should be pruned from _state.
      expect(r.groupEntities.contains(g), isFalse);
    });

    test('removeDependency on missing returns None', () {
      final r = DIRegistry();
      expect(r.removeDependency<_A>().isNone(), isTrue);
    });
  });

  group('Exact-type lookup family (T / K variants)', () {
    test('containsDependencyT matches the registered Sync variant', () {
      final r = DIRegistry();
      r.setDependency(_dep<_A>(const _A('x')));
      expect(r.containsDependencyT(_A), isTrue);
    });

    test('containsDependencyK matches by Entity', () {
      final r = DIRegistry();
      r.setDependency(_dep<_A>(const _A('x')));
      expect(r.containsDependencyK(TypeEntity(_A)), isTrue);
    });

    test('getDependencyT returns Some on hit, None on miss', () {
      final r = DIRegistry();
      r.setDependency(_dep<_A>(const _A('x')));
      expect(r.getDependencyT(_A).isSome(), isTrue);
      expect(r.getDependencyT(_B).isNone(), isTrue);
    });

    test('removeDependencyT removes the entry', () {
      final r = DIRegistry();
      r.setDependency(_dep<_A>(const _A('x')));
      final removed = r.removeDependencyT(_A);
      expect(removed.isSome(), isTrue);
      expect(r.containsDependencyT(_A), isFalse);
    });
  });

  group('Group operations', () {
    test('setGroup overwrites all entries under a groupEntity', () {
      final r = DIRegistry();
      final g = TypeEntity('grp');
      r.setDependency(_dep<_A>(const _A('a'), groupEntity: g));
      r.setDependency(_dep<_B>(const _B(), groupEntity: g));
      expect(r.getGroup(groupEntity: g).length, 2);

      // Replace with a different shape.
      r.setGroup(
        {
          TypeEntity(Sync, [TypeEntity(_C)]):
              _dep<_C>(const _C(), groupEntity: g),
        },
        groupEntity: g,
      );
      expect(r.containsDependency<_A>(groupEntity: g), isFalse);
      expect(r.containsDependency<_B>(groupEntity: g), isFalse);
      expect(r.containsDependency<_C>(groupEntity: g), isTrue);
    });

    test('getGroup returns an unmodifiable map', () {
      final r = DIRegistry();
      final g = TypeEntity('grp');
      r.setDependency(_dep<_A>(const _A('x'), groupEntity: g));
      final group = r.getGroup(groupEntity: g);
      expect(() => group.clear(), throwsA(isA<UnsupportedError>()));
    });

    test('getGroup on a missing groupEntity returns an empty unmodifiable map',
        () {
      final r = DIRegistry();
      final group = r.getGroup(groupEntity: TypeEntity('missing'));
      expect(group, isEmpty);
      expect(() => group.clear(), throwsA(isA<UnsupportedError>()));
    });

    test('removeGroup wipes the group and all type-index entries', () {
      final r = DIRegistry();
      final g = TypeEntity('grp');
      r.setDependency(_dep<_A>(const _A('x'), groupEntity: g));
      r.setDependency(_dep<_B>(const _B(), groupEntity: g));
      r.removeGroup(groupEntity: g);
      expect(r.groupEntities.contains(g), isFalse);
      expect(
        r.groupsWithTypeK(TypeEntity(Sync, [TypeEntity(_A)])),
        isEmpty,
      );
      expect(
        r.groupsWithTypeK(TypeEntity(Sync, [TypeEntity(_B)])),
        isEmpty,
      );
    });

    test('clear() empties everything', () {
      final r = DIRegistry();
      for (var n = 0; n < 5; n++) {
        r.setDependency(
          _dep<_A>(_A('n=$n'), groupEntity: TypeEntity('g$n')),
        );
      }
      r.clear();
      expect(r.groupEntities, isEmpty);
      expect(r.unsortedDependencies, isEmpty);
      expect(
        r.groupsWithTypeK(TypeEntity(Sync, [TypeEntity(_A)])),
        isEmpty,
      );
    });
  });

  group('removeDependencyExact / removeDependencyWhere', () {
    test('removeDependencyExact removes by the raw registry key', () {
      final r = DIRegistry();
      final dep = _dep<_A>(const _A('x'));
      r.setDependency(dep);
      final removed = r.removeDependencyExact(dep.typeEntity);
      expect(removed.isSome(), isTrue);
      expect(r.containsDependency<_A>(), isFalse);
    });

    test('removeDependencyExact returns None on missing group', () {
      final r = DIRegistry();
      final out = r.removeDependencyExact(
        TypeEntity(_A),
        groupEntity: TypeEntity('missing'),
      );
      expect(out.isNone(), isTrue);
    });

    test('removeDependencyWhere drops only matching entries', () {
      final r = DIRegistry();
      r.setDependency(_dep<_A>(const _A('keep')));
      r.setDependency(_dep<_B>(const _B()));
      // Drop only _B.
      r.removeDependencyWhere((typeEntity, _) {
        return typeEntity == TypeEntity(Sync, [TypeEntity(_B)]);
      });
      expect(r.containsDependency<_A>(), isTrue);
      expect(r.containsDependency<_B>(), isFalse);
    });

    test('removeDependencyWhere prunes empty groups', () {
      final r = DIRegistry();
      final g = TypeEntity('grp');
      r.setDependency(_dep<_A>(const _A('a'), groupEntity: g));
      r.removeDependencyWhere((_, __) => true, groupEntity: g);
      expect(r.groupEntities.contains(g), isFalse);
    });

    test('removeDependencyWhere on a missing group is a no-op', () {
      final r = DIRegistry();
      expect(
        () => r.removeDependencyWhere(
          (_, __) => true,
          groupEntity: TypeEntity('missing'),
        ),
        returnsNormally,
      );
    });
  });

  group('Reverse type-index (groupsWithTypeK / groupsWithTypeT)', () {
    test('records the group when a type is registered', () {
      final r = DIRegistry();
      final g = TypeEntity('grp');
      r.setDependency(_dep<_A>(const _A('x'), groupEntity: g));
      final groups =
          r.groupsWithTypeK(TypeEntity(Sync, [TypeEntity(_A)])).toSet();
      expect(groups.contains(g), isTrue);
    });

    test('groupsWithTypeT mirrors groupsWithTypeK', () {
      final r = DIRegistry();
      final g = TypeEntity('grp');
      r.setDependency(_dep<_A>(const _A('x'), groupEntity: g));
      // groupsWithTypeT wraps in Sync/Async — but our reverse index stores the
      // wrapped key. The high-level helper groupsWithTypeK with TypeEntity(_A)
      // returns empty, while groupsWithTypeT wraps in Sync<_A>.
      final t1 = r.groupsWithTypeT(_A);
      final t2 = r.groupsWithTypeK(TypeEntity(_A));
      // Sanity: both return the same iterable shape — but only T includes Sync.
      // Comparing the .toSet() of both confirms they agree.
      expect(t1.toSet(), equals(t2.toSet()));
    });

    test('returns empty Iterable for an unknown type', () {
      final r = DIRegistry();
      expect(
        r.groupsWithTypeK(TypeEntity(Sync, [TypeEntity(_C)])),
        isEmpty,
      );
    });

    test('drops the group entry on removeDependency', () {
      final r = DIRegistry();
      final g = TypeEntity('grp');
      r.setDependency(_dep<_A>(const _A('x'), groupEntity: g));
      r.removeDependency<_A>(groupEntity: g).end();
      expect(
        r.groupsWithTypeK(TypeEntity(Sync, [TypeEntity(_A)])),
        isEmpty,
      );
    });
  });

  group('reversedDependencies / unsortedDependencies', () {
    test('unsortedDependencies returns all registered values', () {
      final r = DIRegistry();
      r.setDependency(_dep<_A>(const _A('a')));
      r.setDependency(_dep<_B>(const _B()));
      expect(r.unsortedDependencies.length, 2);
    });

    test('reversedDependencies sorts newest-first by metadata index', () {
      final r = DIRegistry();
      r.setDependency(
        Dependency<_A>(
          Sync.okValue(const _A('first')),
          metadata: Some(DependencyMetadata(index: const Some(0))),
        ),
      );
      r.setDependency(
        Dependency<_B>(
          Sync.okValue(const _B()),
          metadata: Some(DependencyMetadata(index: const Some(1))),
        ),
      );
      r.setDependency(
        Dependency<_C>(
          Sync.okValue(const _C()),
          metadata: Some(DependencyMetadata(index: const Some(2))),
        ),
      );
      final rev = r.reversedDependencies;
      // Verify metadata indices are descending (newest first).
      var lastIdx = (1 << 30);
      for (final dep in rev) {
        switch (dep.metadata) {
          case Some(value: DependencyMetadata(index: Some(value: final i))):
            expect(i, lessThanOrEqualTo(lastIdx));
            lastIdx = i;
          default:
        }
      }
    });

    test('reversedDependencies is unmodifiable', () {
      final r = DIRegistry();
      r.setDependency(_dep<_A>(const _A('x')));
      final rev = r.reversedDependencies;
      expect(() => rev.clear(), throwsA(isA<UnsupportedError>()));
    });
  });

  group('dependenciesWhereType / WhereTypeK / WhereTypeT', () {
    test('dependenciesWhereType<T> filters by subtype', () {
      final r = DIRegistry();
      r.setDependency(_dep<_A>(const _A('x')));
      r.setDependency(_dep<_B>(const _B()));
      final asAny = r.dependenciesWhereType<Object>().toList();
      expect(asAny.length, 2);
    });

    test(
      'dependenciesWhereTypeK matches exact key only — no subtype propagation',
      () {
        final r = DIRegistry();
        r.setDependency(_dep<_A>(const _A('x')));
        final keyForA = TypeEntity(Sync, [TypeEntity(_A)]);
        expect(r.dependenciesWhereTypeK(keyForA).length, 1);
        // No match for unrelated key.
        final keyForB = TypeEntity(Sync, [TypeEntity(_B)]);
        expect(r.dependenciesWhereTypeK(keyForB), isEmpty);
      },
    );

    test('dependenciesWhereTypeT delegates to WhereTypeK with TypeEntity(t)',
        () {
      // WhereTypeT matches by `typeEntity == TypeEntity(t)` exactly — so a
      // Sync<_A> registration (key = TypeEntity(Sync, [TypeEntity(_A)]))
      // is NOT matched. Use a preemptivetypeEntity to register under the
      // bare TypeEntity(_A) for this exact-key test.
      final r = DIRegistry();
      r.setDependency(
        _dep<_A>(const _A('x'), preemptivetypeEntity: TypeEntity(_A)),
      );
      expect(r.dependenciesWhereTypeT(_A).length, 1);
    });

    test('getDependencies returns all matching deps in the group', () {
      final r = DIRegistry();
      r.setDependency(_dep<_A>(const _A('a')));
      r.setDependency(_dep<_B>(const _B()));
      final outA = r.getDependencies<_A>().toList();
      expect(outA.length, 1);
    });
  });

  group('onChange callback', () {
    test('fires on setDependency', () {
      var fired = 0;
      final r = DIRegistry(onChange: Some(() => fired++));
      r.setDependency(_dep<_A>(const _A('x')));
      expect(fired, 1);
    });

    test('does NOT fire when setDependency is a no-op (equal dep)', () {
      // Identical Dependency object → equals() short-circuits the change.
      final dep = _dep<_A>(const _A('x'));
      var fired = 0;
      final r = DIRegistry(onChange: Some(() => fired++));
      r.setDependency(dep);
      expect(fired, 1);
      r.setDependency(dep);
      // Same instance → no second fire.
      expect(fired, 1);
    });

    test('fires on removeDependency', () {
      var fired = 0;
      final r = DIRegistry(onChange: Some(() => fired++));
      r.setDependency(_dep<_A>(const _A('x')));
      fired = 0;
      r.removeDependency<_A>().end();
      expect(fired, 1);
    });

    test('fires on removeGroup', () {
      var fired = 0;
      final r = DIRegistry(onChange: Some(() => fired++));
      final g = TypeEntity('grp');
      r.setDependency(_dep<_A>(const _A('x'), groupEntity: g));
      fired = 0;
      r.removeGroup(groupEntity: g);
      expect(fired, 1);
    });

    test('fires on clear()', () {
      var fired = 0;
      final r = DIRegistry(onChange: Some(() => fired++));
      r.setDependency(_dep<_A>(const _A('x')));
      fired = 0;
      r.clear();
      expect(fired, 1);
    });

    test('fires on removeDependencyExact', () {
      var fired = 0;
      final r = DIRegistry(onChange: Some(() => fired++));
      final dep = _dep<_A>(const _A('x'));
      r.setDependency(dep);
      fired = 0;
      r.removeDependencyExact(dep.typeEntity).end();
      expect(fired, 1);
    });
  });

  group('Snapshot semantics', () {
    test('state map mutation does not affect the registry', () {
      final r = DIRegistry();
      r.setDependency(_dep<_A>(const _A('x')));
      final s = r.state;
      // Try to mutate. Either it throws (unmodifiable) or silently fails —
      // either way the registry must stay intact.
      try {
        s.clear();
      } on UnsupportedError {
        // Expected.
      }
      expect(r.containsDependencyK(TypeEntity(_A)), isTrue);
    });

    test('groupEntities snapshot is unmodifiable', () {
      final r = DIRegistry();
      r.setDependency(_dep<_A>(const _A('x')));
      final entities = r.groupEntities;
      expect(() => entities.clear(), throwsA(isA<UnsupportedError>()));
    });

    test('groupSlots returns an unmodifiable view', () {
      final r = DIRegistry();
      r.setDependency(_dep<_A>(const _A('x')));
      final slots = r.groupSlots(const DefaultEntity());
      expect(slots, isNotNull);
      expect(() => slots!.clear(), throwsA(isA<UnsupportedError>()));
    });

    test('groupSlots returns null for an absent group', () {
      final r = DIRegistry();
      expect(r.groupSlots(TypeEntity('missing')), isNull);
    });

    test(
      'groupsWithTypeK returns an unmodifiable view',
      () {
        final r = DIRegistry();
        final g = TypeEntity('grp');
        r.setDependency(_dep<_A>(const _A('x'), groupEntity: g));
        final view = r.groupsWithTypeK(TypeEntity(Sync, [TypeEntity(_A)]));
        expect(
          () => (view as Set).add(TypeEntity('other')),
          throwsA(isA<UnsupportedError>()),
        );
      },
    );
  });

  group('Strict keying (Lazy<T> ≠ T)', () {
    test('removeDependency<_A>() does NOT match a Lazy<_A> registration', () {
      final r = DIRegistry();
      r.setDependency(_dep<Lazy<_A>>(Lazy<_A>(() => Sync.okValue(const _A()))));
      expect(r.removeDependency<_A>().isNone(), isTrue);
      expect(r.containsDependency<Lazy<_A>>(), isTrue);
    });

    test(
      'containsDependencyK(TypeEntity(_A)) does NOT match a Lazy<_A> '
      'registration',
      () {
        final r = DIRegistry();
        r.setDependency(
          _dep<Lazy<_A>>(Lazy<_A>(() => Sync.okValue(const _A()))),
        );
        expect(r.containsDependencyK(TypeEntity(_A)), isFalse);
        expect(
          r.containsDependencyK(TypeEntity(Lazy, [TypeEntity(_A)])),
          isTrue,
        );
      },
    );
  });
}
