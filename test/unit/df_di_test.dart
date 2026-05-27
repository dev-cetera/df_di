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

// Smoke tests for the public barrel `package:df_di/df_di.dart`. The barrel
// re-exports `df_safer_dart`, `df_type`, and `src/_src.g.dart`. The intent
// of this test file is to lock the **shape** of the public API surface: if
// a key symbol stops being reachable through the single canonical import,
// downstream consumers will break.

import 'package:df_di/df_di.dart';
import 'package:df_di/src/di/_dependency.dart';
import 'package:test/test.dart';

// ─── Test fixtures ───────────────────────────────────────────────────────────

final class _Thing {
  _Thing(this.label);
  final String label;
}

void main() {
  group('df_di.dart barrel: core DI symbols', () {
    test('DI is constructible', () {
      final di = DI();
      expect(di, isA<DI>());
    });

    test('register/get round-trips through the public surface', () {
      final di = DI();
      di.register<_Thing>(_Thing('a')).end();
      expect(di.isRegistered<_Thing>(), isTrue);
    });
  });

  group('Dependency / DependencyMetadata (via internal import path)', () {
    test('DependencyMetadata is constructible with a preemptive type entity',
        () {
      final meta = DependencyMetadata(preemptivetypeEntity: TypeEntity(int));
      expect(meta, isA<DependencyMetadata>());
      expect(meta.preemptivetypeEntity, equals(TypeEntity(int)));
    });

    test('Dependency is constructible with a Resolvable value', () {
      final dep = Dependency<int>(Sync.okValue(1));
      expect(dep, isA<Dependency<int>>());
      expect(dep.value, isA<Resolvable<int>>());
    });
  });

  group('df_di.dart barrel: Service / ServiceMixin / variants', () {
    test('Service / StreamService / PollingStreamService are exported types',
        () {
      expect(Service, isA<Type>());
      expect(StreamService, isA<Type>());
      expect(PollingStreamService, isA<Type>());
    });

    test('ServiceMixin / StreamServiceMixin are exported types', () {
      expect(ServiceMixin, isA<Type>());
      expect(StreamServiceMixin, isA<Type>());
    });
  });

  group('df_di.dart barrel: Entity and reserved entities', () {
    test('TypeEntity constructible from a Dart Type', () {
      expect(TypeEntity(int), isA<Entity>());
    });

    test('UniqueEntity constructs and is an Entity', () {
      expect(UniqueEntity(), isA<Entity>());
    });

    test('reserved entities are all constructible Entities', () {
      expect(const DefaultEntity(), isA<Entity>());
      expect(const GlobalEntity(), isA<Entity>());
      expect(const SessionEntity(), isA<Entity>());
      expect(const UserEntity(), isA<Entity>());
      expect(const ThemeEntity(), isA<Entity>());
      expect(const DevEntity(), isA<Entity>());
      expect(const ProdEntity(), isA<Entity>());
      expect(const TestEntity(), isA<Entity>());
    });
  });

  group('df_di.dart barrel: ECS / Plugin surface', () {
    test('World is constructible', () {
      final world = World();
      expect(world, isA<World>());
    });

    test(
      'Plugin / EcsPlugin / Component / Resource / Event / System / Bundle '
      'are exported types',
      () {
        expect(Plugin, isA<Type>());
        expect(EcsPlugin, isA<Type>());
        expect(Component, isA<Type>());
        expect(Resource, isA<Type>());
        expect(Event, isA<Type>());
        expect(System, isA<Type>());
        expect(Bundle, isA<Type>());
      },
    );
  });

  group('df_di.dart barrel: df_safer_dart re-exports', () {
    test('Option / Some / None reachable', () {
      const opt = None<int>();
      expect(opt, isA<Option<int>>());
      expect(const Some(1), isA<Option<int>>());
    });

    test('Result / Ok / Err reachable', () {
      expect(const Ok(1), isA<Result<int>>());
      expect(Err<int>('boom'), isA<Result<int>>());
    });

    test('Resolvable / Sync / Async reachable', () {
      expect(Sync.okValue(1), isA<Resolvable<int>>());
      expect(Sync.okValue(1), isA<Sync<int>>());
      final a = Async<int>(() async => 1);
      expect(a, isA<Resolvable<int>>());
      expect(a, isA<Async<int>>());
      a.end();
    });

    test('Unit reachable as a value-type', () {
      expect(Unit(), isA<Unit>());
      expect(Unit(), same(Unit.instance));
    });
  });
}
