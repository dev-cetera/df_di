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

// Tests for `Dependency` and `DependencyMetadata`. Exercises the public API
// surface: construction, getters, transformation helpers (`passNewValue`,
// `transf`, `copyWith`), equality semantics, and the `DependencyMetadata`
// `copyWith` "preserve unless explicitly set" behaviour. Also smoke-tests the
// public typedefs by assigning lambdas to them.

import 'dart:async';

import 'package:df_di/df_di.dart';
// ignore: invalid_use_of_internal_member
import 'package:df_di/src/di/_dependency.dart';
import 'package:test/test.dart';

// ─── Test fixtures ───────────────────────────────────────────────────────────

final class _A {
  const _A([this.tag = '']);
  final String tag;
}

final class _B {
  const _B();
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('Dependency construction', () {
    test('Dependency(value) stores value and defaults metadata to None', () {
      final v = Sync<_A>.okValue(const _A('x'));
      final dep = Dependency<_A>(v);
      expect(identical(dep.value, v), isTrue);
      expect(dep.metadata.isNone(), isTrue);
    });

    test('Dependency(value, metadata: Some) stores metadata', () {
      final v = Sync<_A>.okValue(const _A('x'));
      final meta = DependencyMetadata(groupEntity: TypeEntity('g'));
      final dep = Dependency<_A>(v, metadata: Some(meta));
      expect(dep.metadata.isSome(), isTrue);
      switch (dep.metadata) {
        case Some(value: final m):
          expect(identical(m, meta), isTrue);
        case None():
          fail('Expected Some metadata.');
      }
    });

    test(
      'Dependency(value, metadata: Some) populates initialType when it was '
      'None',
      () {
        final v = Sync<_A>.okValue(const _A('x'));
        final meta = DependencyMetadata();
        expect(meta.initialType.isNone(), isTrue);

        Dependency<_A>(v, metadata: Some(meta));

        // After construction the metadata's initialType is populated with the
        // runtime type of the wrapped Resolvable.
        expect(meta.initialType.isSome(), isTrue);
        switch (meta.initialType) {
          case Some(value: final t):
            expect(t, equals(v.runtimeType));
          case None():
            fail('initialType should have been populated.');
        }
      },
    );

    test(
      'Dependency does NOT overwrite a pre-populated initialType',
      () {
        // First registration captures initialType.
        final v1 = Sync<_A>.okValue(const _A('x'));
        final meta = DependencyMetadata();
        Dependency<_A>(v1, metadata: Some(meta));
        final firstType = meta.initialType;
        expect(firstType.isSome(), isTrue);

        // Re-using the same metadata with a different Resolvable runtimeType
        // (Async<_A>) must NOT overwrite the original initialType.
        final v2 = Async<_A>(() async => const _A('y'));
        Dependency<_A>(v2, metadata: Some(meta));

        switch ((firstType, meta.initialType)) {
          case (Some(value: final a), Some(value: final b)):
            expect(a, equals(b));
          default:
            fail('Both types should be Some.');
        }
      },
    );
  });

  group('Dependency.typeEntity', () {
    test(
      'returns TypeEntity(value.runtimeType) when metadata is None',
      () {
        final v = Sync<_A>.okValue(const _A('x'));
        final dep = Dependency<_A>(v);
        expect(dep.typeEntity, equals(TypeEntity(v.runtimeType)));
      },
    );

    test(
      'returns TypeEntity(value.runtimeType) when metadata has default '
      'preemptivetypeEntity',
      () {
        final v = Sync<_A>.okValue(const _A('x'));
        final dep = Dependency<_A>(
          v,
          metadata: Some(DependencyMetadata()),
        );
        expect(dep.typeEntity, equals(TypeEntity(v.runtimeType)));
      },
    );

    test(
      'returns preemptivetypeEntity when set to a non-default value',
      () {
        final custom = TypeEntity('custom-key');
        final v = Sync<_A>.okValue(const _A('x'));
        final dep = Dependency<_A>(
          v,
          metadata: Some(DependencyMetadata(preemptivetypeEntity: custom)),
        );
        expect(dep.typeEntity, equals(custom));
      },
    );
  });

  group('Dependency.passNewValue', () {
    test('returns a new Dependency<R> retaining metadata identity', () {
      final v = Sync<_A>.okValue(const _A('x'));
      final meta = DependencyMetadata(groupEntity: TypeEntity('g'));
      final dep = Dependency<_A>(v, metadata: Some(meta));

      final newVal = Sync<_B>.okValue(const _B());
      final dep2 = dep.passNewValue<_B>(newVal);

      expect(identical(dep2.value, newVal), isTrue);
      switch (dep2.metadata) {
        case Some(value: final m):
          expect(identical(m, meta), isTrue);
        case None():
          fail('metadata should be preserved.');
      }
    });

    test('passNewValue from a no-metadata Dependency yields None metadata', () {
      final v = Sync<_A>.okValue(const _A('x'));
      final dep = Dependency<_A>(v);
      final newVal = Sync<_B>.okValue(const _B());
      final dep2 = dep.passNewValue<_B>(newVal);
      expect(dep2.metadata.isNone(), isTrue);
    });
  });

  group('Dependency.transf', () {
    test(
      'returns a new Dependency<R> typed at R but holding the same underlying '
      'Resolvable',
      () {
        final v = Sync<_A>.okValue(const _A('x'));
        final dep = Dependency<_A>(v);
        final dep2 = dep.transf<Object>();
        expect(dep2, isA<Dependency<Object>>());
      },
    );
  });

  group('Dependency.copyWith', () {
    test('preserves value when value arg is None', () {
      final v = Sync<_A>.okValue(const _A('x'));
      final meta = DependencyMetadata(groupEntity: TypeEntity('g'));
      final dep = Dependency<_A>(v, metadata: Some(meta));
      final dep2 = dep.copyWith();
      expect(identical(dep2.value, v), isTrue);
    });

    test('swaps value when value arg is Some', () {
      final v1 = Sync<_A>.okValue(const _A('x'));
      final v2 = Sync<_A>.okValue(const _A('y'));
      final dep = Dependency<_A>(v1);
      final dep2 = dep.copyWith(value: Some(v2));
      expect(identical(dep2.value, v2), isTrue);
    });

    test('uses the metadata arg directly', () {
      final v = Sync<_A>.okValue(const _A('x'));
      final meta1 = DependencyMetadata(groupEntity: TypeEntity('g1'));
      final dep = Dependency<_A>(v, metadata: Some(meta1));
      final meta2 = DependencyMetadata(groupEntity: TypeEntity('g2'));
      final dep2 = dep.copyWith(metadata: Some(meta2));
      switch (dep2.metadata) {
        case Some(value: final m):
          expect(identical(m, meta2), isTrue);
        case None():
          fail('metadata should be the provided meta2.');
      }
    });
  });

  group('Dependency equality', () {
    test('identical instance equals itself', () {
      final dep = Dependency<_A>(Sync.okValue(const _A('x')));
      // ignore: unrelated_type_equality_checks
      expect(dep == dep, isTrue);
    });

    test('equal by hashAll(value, metadata) — same value & metadata', () {
      final v = Sync<_A>.okValue(const _A('x'));
      final meta = DependencyMetadata(groupEntity: TypeEntity('g'));
      final dep1 = Dependency<_A>(v, metadata: Some(meta));
      final dep2 = Dependency<_A>(v, metadata: Some(meta));
      expect(dep1, equals(dep2));
      expect(dep1.hashCode, equals(dep2.hashCode));
    });

    test('different metadata → not equal', () {
      final v = Sync<_A>.okValue(const _A('x'));
      final meta1 = DependencyMetadata(groupEntity: TypeEntity('g1'));
      final meta2 = DependencyMetadata(groupEntity: TypeEntity('g2'));
      final dep1 = Dependency<_A>(v, metadata: Some(meta1));
      final dep2 = Dependency<_A>(v, metadata: Some(meta2));
      expect(dep1, isNot(equals(dep2)));
    });

    test('different underlying values → not equal', () {
      final dep1 = Dependency<_A>(Sync<_A>.okValue(const _A('one')));
      final dep2 = Dependency<_A>(Sync<_A>.okValue(const _A('two')));
      // Different underlying values change the Resolvable's hash → distinct.
      expect(dep1, isNot(equals(dep2)));
    });
  });

  group('DependencyMetadata defaults', () {
    test('default constructor sets sane defaults', () {
      final m = DependencyMetadata();
      expect(m.groupEntity, equals(const DefaultEntity()));
      expect(m.preemptivetypeEntity, equals(const DefaultEntity()));
      expect(m.index.isNone(), isTrue);
      expect(m.onUnregister.isNone(), isTrue);
      expect(m.initialType.isNone(), isTrue);
    });

    test('explicit args override defaults', () {
      final g = TypeEntity('grp');
      final pt = TypeEntity('preempt');
      final m = DependencyMetadata(
        groupEntity: g,
        preemptivetypeEntity: pt,
        index: const Some(7),
      );
      expect(m.groupEntity, equals(g));
      expect(m.preemptivetypeEntity, equals(pt));
      switch (m.index) {
        case Some(value: final i):
          expect(i, 7);
        case None():
          fail('index should be Some(7).');
      }
    });
  });

  group('DependencyMetadata.copyWith', () {
    test('groupEntity: only changes when non-default arg supplied', () {
      final g1 = TypeEntity('g1');
      final g2 = TypeEntity('g2');
      final m = DependencyMetadata(groupEntity: g1);

      // Default arg → no change.
      final m1 = m.copyWith();
      expect(m1.groupEntity, equals(g1));

      // Non-default arg → swap.
      final m2 = m.copyWith(groupEntity: g2);
      expect(m2.groupEntity, equals(g2));
    });

    test('preemptivetypeEntity: only changes when non-default arg supplied',
        () {
      final p1 = TypeEntity('p1');
      final p2 = TypeEntity('p2');
      final m = DependencyMetadata(preemptivetypeEntity: p1);

      final m1 = m.copyWith();
      expect(m1.preemptivetypeEntity, equals(p1));

      final m2 = m.copyWith(preemptivetypeEntity: p2);
      expect(m2.preemptivetypeEntity, equals(p2));
    });

    test('index: only changes when Some arg supplied', () {
      final m = DependencyMetadata(index: const Some(5));

      final m1 = m.copyWith();
      switch (m1.index) {
        case Some(value: final i):
          expect(i, 5);
        case None():
          fail('index should be preserved.');
      }

      final m2 = m.copyWith(index: const Some(11));
      switch (m2.index) {
        case Some(value: final i):
          expect(i, 11);
        case None():
          fail('index should be 11.');
      }
    });

    test('onUnregister: only changes when Some arg supplied', () {
      var calledFirst = 0;
      var calledSecond = 0;
      final cb1 = (Result<Object> _) {
        calledFirst++;
      };
      final cb2 = (Result<Object> _) {
        calledSecond++;
      };

      final m = DependencyMetadata(onUnregister: Some(cb1));

      // Default None — preserves cb1.
      final m1 = m.copyWith();
      switch (m1.onUnregister) {
        case Some(value: final cb):
          cb(const Ok(Object()));
        case None():
          fail('onUnregister should be preserved.');
      }
      expect(calledFirst, 1);

      // Some(cb2) — swaps.
      final m2 = m.copyWith(onUnregister: Some(cb2));
      switch (m2.onUnregister) {
        case Some(value: final cb):
          cb(const Ok(Object()));
        case None():
          fail('onUnregister should be cb2.');
      }
      expect(calledSecond, 1);
    });

    test('initialType: only writes when Some arg supplied', () {
      // Seed initialType via Dependency construction.
      final v = Sync<_A>.okValue(const _A('x'));
      final meta = DependencyMetadata();
      Dependency<_A>(v, metadata: Some(meta));
      expect(meta.initialType.isSome(), isTrue);

      // copyWith with default initialType arg → preserved.
      final m1 = meta.copyWith();
      expect(m1.initialType.isSome(), isTrue);
      switch ((meta.initialType, m1.initialType)) {
        case (Some(value: final a), Some(value: final b)):
          expect(a, equals(b));
        default:
          fail('initialType should be preserved on copyWith.');
      }

      // copyWith with Some(int) arg → overwrites.
      final m2 = meta.copyWith(initialType: const Some(int));
      switch (m2.initialType) {
        case Some(value: final t):
          expect(t, equals(int));
        case None():
          fail('initialType should be overwritten to int.');
      }
    });
  });

  group('DependencyMetadata equality', () {
    test('two metadata objects with the same fields are equal', () {
      final g = TypeEntity('g');
      final m1 = DependencyMetadata(groupEntity: g, index: const Some(1));
      final m2 = DependencyMetadata(groupEntity: g, index: const Some(1));
      expect(m1, equals(m2));
      expect(m1.hashCode, equals(m2.hashCode));
    });

    test('different index → not equal', () {
      final m1 = DependencyMetadata(index: const Some(1));
      final m2 = DependencyMetadata(index: const Some(2));
      expect(m1, isNot(equals(m2)));
    });

    test('identical instance equals itself', () {
      final m = DependencyMetadata();
      // ignore: unrelated_type_equality_checks
      expect(m == m, isTrue);
    });
  });

  group('Typedefs (smoke)', () {
    test('TOnRegisterCallback assignment compiles and is callable', () {
      var called = 0;
      final TOnRegisterCallback<_A> cb = (value) {
        expect(value, isA<_A>());
        called++;
        return Future<void>.value();
      };
      final r = cb(const _A('x'));
      expect(r, isA<FutureOr<void>>());
      expect(called, 1);
    });

    test('TOnUnregisterCallback assignment compiles and is callable', () {
      var called = 0;
      final TOnUnregisterCallback<_A> cb = (result) {
        expect(result, isA<Result<_A>>());
        called++;
      };
      cb(const Ok(_A('x')));
      expect(called, 1);
    });

    test('TDependencyValidator assignment compiles and is callable', () {
      bool predicate(_A value) => value.tag.isNotEmpty;
      // Lock the predicate against the typedef's declared signature.
      // ignore: omit_local_variable_types
      final TDependencyValidator<_A> v = predicate;
      expect(v(const _A('x')), isTrue);
      expect(v(const _A()), isFalse);
    });
  });
}
