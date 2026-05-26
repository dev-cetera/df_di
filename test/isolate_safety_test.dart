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

// Cross-isolate safety tests for Entity-family value objects. The DI
// container itself is per-isolate, but the keys used to address it must
// survive a SendPort round trip.

import 'dart:async';
import 'dart:isolate';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Isolate workers ─────────────────────────────────────────────────────────

List<int> _generateUniqueIds(int n) {
  return List<int>.generate(n, (_) => UniqueEntity().id);
}

void _uniqueEntityWorker((SendPort, int) args) {
  final (sendPort, n) = args;
  sendPort.send(_generateUniqueIds(n));
}

void _entityRoundTripWorker((SendPort, List<Entity>) args) {
  final (sendPort, entities) = args;
  sendPort.send(entities.map((e) => e.id).toList());
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Future<List<int>> _spawnAndCollectUniqueIds(int count) async {
  final receivePort = ReceivePort();
  try {
    await Isolate.spawn<(SendPort, int)>(
      _uniqueEntityWorker,
      (receivePort.sendPort, count),
    );
    return await receivePort.first as List<int>;
  } finally {
    receivePort.close();
  }
}

Future<List<int>> _spawnAndEcho(List<Entity> entities) async {
  final receivePort = ReceivePort();
  try {
    await Isolate.spawn<(SendPort, List<Entity>)>(
      _entityRoundTripWorker,
      (receivePort.sendPort, entities),
    );
    return await receivePort.first as List<int>;
  } finally {
    receivePort.close();
  }
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
      expect(combined, hasLength(perIsolate * 2));
    });

    test(
      'parent-isolate UniqueEntities do not collide with worker-isolate ones',
      () async {
        const perSide = 200;
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
      for (var i = 0; i < 100; i++) {
        final e = UniqueEntity();
        expect(e.id, lessThan(0));
        // Below the reserved-entities range (-1001..-1008).
        expect(e.id, lessThan(-10000));
      }
    });
  });

  group('Entity equality survives isolate transfer', () {
    test('TypeEntity from worker equals locally-constructed sibling', () async {
      final receivePort = ReceivePort();
      final TypeEntity remote;
      try {
        await Isolate.spawn<SendPort>(
          _typeEntityProducerWorker,
          receivePort.sendPort,
        );
        remote = await receivePort.first as TypeEntity;
      } finally {
        receivePort.close();
      }
      final local = TypeEntity(String);
      expect(remote, equals(local));
      expect(remote.id, equals(local.id));
    });
  });
}

void _typeEntityProducerWorker(SendPort port) {
  port.send(TypeEntity(String));
}
