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

// Cross-isolate safety tests for Entity-family value objects.
//
// The DI container itself is per-isolate by design (it holds mutable maps,
// completers, timers — none of which can cross an isolate boundary). But the
// value-typed keys used to address it — `Entity`, `TypeEntity`,
// `GenericEntity`, `UniqueEntity`, and the reserved entity singletons — must
// survive a `SendPort` round trip so caller code can ship entity identifiers
// between worker isolates and the main one.
//
// What we verify:
//
//  1. Entity / TypeEntity / GenericEntity / DefaultEntity etc. round-trip
//     with their `id` (and therefore equality) intact.
//  2. UniqueEntity ids generated in different isolates do NOT collide. The
//     monotonic counter is seeded with a random per-isolate block offset
//     (see `lib/src/entity/unique_entity.dart`), so two isolates each
//     producing N UniqueEntities will produce 2N distinct ids with
//     overwhelmingly high probability.

import 'dart:async';
import 'dart:isolate';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Isolate workers ─────────────────────────────────────────────────────────

/// Returns N freshly-generated `UniqueEntity` ids from this isolate.
List<int> _generateUniqueIds(int n) {
  return List<int>.generate(n, (_) => UniqueEntity().id);
}

/// Top-level isolate entrypoint: produces N UniqueEntity ids and sends them
/// back over [sendPort]. Top-level so `Isolate.spawn` can find it.
void _uniqueEntityWorker((SendPort, int) args) {
  final (sendPort, n) = args;
  sendPort.send(_generateUniqueIds(n));
}

/// Top-level isolate entrypoint: round-trips a list of pre-constructed
/// entities and sends each one's id back, so the parent can verify identity
/// survives the transfer.
void _entityRoundTripWorker((SendPort, List<Entity>) args) {
  final (sendPort, entities) = args;
  // Echo the ids — but read them from the received instances, NOT from the
  // captured-in-parent values. This is what proves the entity actually made
  // it across the boundary intact.
  sendPort.send(entities.map((e) => e.id).toList());
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Future<List<int>> _spawnAndCollectUniqueIds(int count) async {
  final receivePort = ReceivePort();
  await Isolate.spawn<(SendPort, int)>(
    _uniqueEntityWorker,
    (receivePort.sendPort, count),
  );
  final result = await receivePort.first as List<int>;
  receivePort.close();
  return result;
}

Future<List<int>> _spawnAndEcho(List<Entity> entities) async {
  final receivePort = ReceivePort();
  await Isolate.spawn<(SendPort, List<Entity>)>(
    _entityRoundTripWorker,
    (receivePort.sendPort, entities),
  );
  final result = await receivePort.first as List<int>;
  receivePort.close();
  return result;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('Entity sendability across isolates', () {
    test('plain Entity round-trips with id intact', () async {
      final original = const Entity(42);
      final echoedIds = await _spawnAndEcho([original]);
      expect(echoedIds, equals([42]));
    });

    test('TypeEntity round-trips with id intact', () async {
      final original = TypeEntity(String);
      final echoedIds = await _spawnAndEcho([original]);
      expect(echoedIds, equals([original.id]));
    });

    test('GenericEntity round-trips with id intact', () async {
      final original = GenericEntity<List<String>>();
      final echoedIds = await _spawnAndEcho([original]);
      expect(echoedIds, equals([original.id]));
    });

    test('Reserved entities round-trip with id intact', () async {
      const reserved = <Entity>[
        DefaultEntity(),
        GlobalEntity(),
        SessionEntity(),
        UserEntity(),
        ThemeEntity(),
        ProdEntity(),
        DevEntity(),
        TestEntity(),
      ];
      final echoedIds = await _spawnAndEcho(reserved);
      expect(echoedIds, equals(reserved.map((e) => e.id).toList()));
    });

    test('UniqueEntity round-trips with id intact', () async {
      final original = UniqueEntity();
      final echoedIds = await _spawnAndEcho([original]);
      expect(echoedIds, equals([original.id]));
    });
  });

  group('UniqueEntity cross-isolate uniqueness', () {
    test('two isolates generate disjoint id sets', () async {
      // Each isolate picks a random block offset at first use. With 2^30
      // possible blocks of 2^20 ids each, two isolates colliding on the
      // same block is astronomically unlikely — the expected number of
      // collisions in this test is ~0.
      const perIsolate = 200;
      final futures = <Future<List<int>>>[
        _spawnAndCollectUniqueIds(perIsolate),
        _spawnAndCollectUniqueIds(perIsolate),
      ];
      final results = await Future.wait(futures);
      final combined = <int>{};
      for (final ids in results) {
        expect(ids, hasLength(perIsolate));
        combined.addAll(ids);
      }
      // No collisions across the two isolate runs (or within each — the
      // counter inside an isolate is strictly decreasing).
      expect(combined, hasLength(perIsolate * 2));
    });

    test(
      'parent-isolate UniqueEntities do not collide with worker-isolate ones',
      () async {
        const perSide = 200;
        // Parent does its own generation IN PARALLEL with the worker so both
        // sides have already seeded their counters by the time we compare.
        final parentIds = _generateUniqueIds(perSide);
        final workerIds = await _spawnAndCollectUniqueIds(perSide);
        final union = {...parentIds, ...workerIds};
        expect(union, hasLength(parentIds.length + workerIds.length));
      },
    );

    test(
      'four isolates in parallel all produce disjoint id ranges',
      () async {
        const isolates = 4;
        const perIsolate = 100;
        final results = await Future.wait(
          List<Future<List<int>>>.generate(
            isolates,
            (_) => _spawnAndCollectUniqueIds(perIsolate),
          ),
        );
        final union = <int>{};
        for (final ids in results) {
          union.addAll(ids);
        }
        expect(union, hasLength(isolates * perIsolate));
      },
    );

    test('UniqueEntity ids remain in the negative-int reserved range', () {
      // The Entity.reserved contract requires id < 0. Verify the random
      // seeding cannot violate that invariant even at the largest block
      // offset.
      for (var i = 0; i < 100; i++) {
        final e = UniqueEntity();
        expect(e.id, lessThan(0));
        // And below the reserved-entities range used for DI.global / session
        // / user / theme / etc. (those occupy -1001..-1008).
        expect(e.id, lessThan(-10000));
      }
    });
  });

  group('Entity equality survives isolate transfer', () {
    test('TypeEntity from worker equals locally-constructed sibling', () async {
      // Construct a TypeEntity in a worker, send back its id, then locally
      // reconstruct an equivalent TypeEntity and verify equality. This
      // exercises the typical real-world use case: serialise a DI key in
      // one isolate, address the same registry slot in another.
      final receivePort = ReceivePort();
      await Isolate.spawn<SendPort>(_typeEntityProducerWorker, receivePort.sendPort);
      final remote = await receivePort.first as TypeEntity;
      receivePort.close();
      final local = TypeEntity(String);
      expect(remote, equals(local));
      expect(remote.id, equals(local.id));
    });
  });
}

void _typeEntityProducerWorker(SendPort port) {
  port.send(TypeEntity(String));
}
