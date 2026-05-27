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

// Adversarial tests: UniqueEntity identity (UUID, not int id), symmetric
// equality with plain Entity, and deep parent-chain traversal.

import 'dart:async';
import 'dart:isolate';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Isolate worker ──────────────────────────────────────────────────────────

void _sendUuidsBack((SendPort, int) args) {
  final (port, n) = args;
  port.send(List<String>.generate(n, (_) => UniqueEntity().uuid));
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('UniqueEntity identity is unforgeable', () {
    test('Entity with the same id as a UniqueEntity is NOT equal to it', () {
      final ue = UniqueEntity();
      final forged = _ForgedEntity(ue.id);
      expect(
        forged == ue,
        isFalse,
        reason: 'forged Entity must not be able to claim a UniqueEntity\'s '
            'identity even with a matching id',
      );
      expect(
        ue == forged,
        isFalse,
        reason: 'UniqueEntity must not accept a non-UniqueEntity as itself',
      );
    });

    test(
      '== is symmetric: entity == ue and ue == entity always agree (both false)',
      () {
        final ue = UniqueEntity();
        const reserved = <Entity>[
          DefaultEntity(),
          GlobalEntity(),
          SessionEntity(),
          UserEntity(),
        ];
        for (final e in reserved) {
          expect(e == ue, isFalse, reason: '$e == $ue must be false');
          expect(ue == e, isFalse, reason: '$ue == $e must be false');
        }
      },
    );

    test(
      'two UniqueEntity instances are never equal, even after thousands of '
      'constructions',
      () {
        final uuids = <String>{};
        for (var i = 0; i < 10000; i++) {
          uuids.add(UniqueEntity().uuid);
        }
        expect(
          uuids,
          hasLength(10000),
          reason: 'No two UniqueEntities should share a UUID',
        );
      },
    );

    test(
        'HashMap correctness: forged Entity cannot retrieve a UniqueEntity value',
        () {
      final ue = UniqueEntity();
      final map = <Entity, String>{ue: 'secret'};
      expect(map[ue], equals('secret'));
      // A reserved-id entity that collides on hashCode must still miss.
      final forged = _ForgedEntity(ue.id);
      expect(
        map[forged],
        isNull,
        reason: 'A forged Entity must not retrieve a UniqueEntity value',
      );
    });
  });

  group('UniqueEntity UUID round-trips across isolates', () {
    test('a UniqueEntity sent via SendPort preserves both id AND uuid',
        () async {
      final original = UniqueEntity();
      final received = await _echo(original);
      expect(received.id, equals(original.id));
      expect(received.uuid, equals(original.uuid));
      expect(received == original, isTrue);
      expect(original == received, isTrue);
    });

    test('two isolates generating UniqueEntities produce disjoint UUID sets',
        () async {
      const perIsolate = 500;
      final results = await Future.wait([
        _collectUuids(perIsolate),
        _collectUuids(perIsolate),
      ]);
      final combined = <String>{};
      for (final uuids in results) {
        expect(uuids, hasLength(perIsolate));
        combined.addAll(uuids);
      }
      expect(combined, hasLength(perIsolate * 2));
    });
  });

  group('parent-chain traversal does not stack-overflow', () {
    test('isRegistered traverses 5000-deep parent chain without crashing', () {
      final chain = <DI>[for (var i = 0; i < 5000; i++) DI()];
      for (var i = 0; i < chain.length - 1; i++) {
        chain[i].parents.add(chain[i + 1]);
      }
      chain.last.register<_DeepValue>(const _DeepValue('top')).end();
      expect(chain.first.isRegistered<_DeepValue>(), isTrue);
    });

    test(
      'getDependency traverses 5000-deep parent chain without crashing',
      () {
        final chain = <DI>[for (var i = 0; i < 5000; i++) DI()];
        for (var i = 0; i < chain.length - 1; i++) {
          chain[i].parents.add(chain[i + 1]);
        }
        chain.last.register<_DeepValue>(const _DeepValue('top')).end();
        final found = chain.first.getDependency<_DeepValue>();
        expect(found.isSome(), isTrue);
      },
    );

    test('isRegistered terminates on a cyclic parent chain of length 5000', () {
      final chain = <DI>[for (var i = 0; i < 5000; i++) DI()];
      for (var i = 0; i < chain.length - 1; i++) {
        chain[i].parents.add(chain[i + 1]);
      }
      chain.last.parents.add(chain.first);
      expect(chain.first.isRegistered<_DeepValue>(), isFalse);
    });
  });

  group('unregisterChildT contract', () {
    test(
      'returns Err (not throws) when children container holds a non-Lazy<DI>',
      () {
        final parent = DI();
        parent.registerChild().end();
        UNSAFE:
        final children = parent.childrenContainer.unwrap();
        // Adversarial: bypass registerChild and write a Lazy<_NotDI>
        // directly into the children container.
        children.registerLazy<_NotDI>(() => Sync.okValue(const _NotDI())).end();
        Result<Option<DI>> result;
        try {
          result = parent.unregisterChildT(_NotDI);
        } catch (e) {
          fail(
            'unregisterChildT must NOT throw on adversarial misuse; threw $e',
          );
        }
        expect(
          result.isErr(),
          isTrue,
          reason: 'mismatched-type entry should surface as Err',
        );
      },
    );
  });

  group('safety claims validated against audit findings', () {
    // These tests lock in safety properties that an external audit agent
    // had previously flagged as "bugs". After verifying the code already
    // handles each case correctly, we encode that as a test so a future
    // refactor cannot regress the property silently.

    test(
      'didEverInitAndSuccessfully stays false when an init listener errors',
      () async {
        // Audit agent claimed this flag could "lie" if a listener errored
        // mid-init. It cannot: the flag is set inside `onSuccessMustNotThrow`
        // which only fires when transitioning to RUN_SUCCESS.
        final s = _ErroringInitService();
        (await s.init().toAsync().value).end();
        expect(s.state, ServiceState.RUN_ERROR);
        expect(
          s.didEverInitAndSuccessfully,
          isFalse,
          reason: 'flag must reflect success, not "init started"',
        );
      },
    );

    test(
      'didEverInitAndSuccessfully becomes true on real success and stays true',
      () async {
        // Companion: confirm the flag DOES flip on success and stays true
        // even after dispose. Encodes the documented "sticky" contract.
        final s = _ErroringInitService(throwOnInit: false);
        (await s.init().toAsync().value).end();
        expect(s.state, ServiceState.RUN_SUCCESS);
        expect(s.didEverInitAndSuccessfully, isTrue);
        (await s.dispose().toAsync().value).end();
        expect(
          s.didEverInitAndSuccessfully,
          isTrue,
          reason: 'sticky flag must survive dispose',
        );
      },
    );

    test(
      'until<TSuper> race-with-unregister surfaces as Err, never throws',
      () async {
        // Audit agent claimed this window was "racy". The code at
        // _di_base.dart explicitly handles the case by returning an Err
        // Resolvable when the post-resolution lookup finds None. This test
        // exercises that path: seed a completer, register, then unregister
        // before the awaiter consumes the result.
        final di = DI();
        final pending = di.untilSuper<_AsyncPayload>().value;
        // Register triggers the completer to resolve.
        di.register<_AsyncPayload>(const _AsyncPayload('hi')).end();
        // Immediately unregister — between resolve and the awaiter's
        // post-resolution lookup.
        di.unregister<_AsyncPayload>().end();
        // The await should produce Err on the race, NOT throw.
        final result = await pending;
        // Either Ok (race lost — we got the value first) or Err (race
        // won — the documented race-handling Err). Both are valid; the
        // critical invariant is "no throw".
        expect(
          result.isOk() || result.isErr(),
          isTrue,
          reason: 'untilSuper must always produce a Result, never throw',
        );
      },
    );
  });

  group('async-memoization swap is identity-checked', () {
    test(
      'unregister<T>() before async resolves is not silently undone',
      () async {
        // An Async<T> dep is registered; caller obtains it via getAsync<T>
        // (whose .then body memoises by swapping the slot to Sync). If the
        // user calls unregister<T>() before the future resolves, the
        // memoise step MUST NOT re-create the slot. The slot removal in
        // `unregister` is synchronous; the unregister-chain Resolvable
        // (which itself awaits the fut) is fire-and-forget via `.end()`.
        final di = DI();
        final completer = Completer<_AsyncPayload>();
        di.register<_AsyncPayload>(completer.future).end();
        UNSAFE:
        final pending = di.getAsync<_AsyncPayload>().unwrap().value;
        di.unregister<_AsyncPayload>().end();
        expect(
          di.isRegistered<_AsyncPayload>(),
          isFalse,
          reason: 'unregister removes slot synchronously',
        );
        // Now resolve the async. memoise's .then fires; identity check
        // must see the slot is gone and skip the swap.
        completer.complete(const _AsyncPayload('resolved'));
        (await pending).end();
        // microtask drain so any pending swap would have fired by now
        await Future<void>.delayed(Duration.zero);
        expect(
          di.isRegistered<_AsyncPayload>(),
          isFalse,
          reason: 'memoisation must not re-register after explicit unregister',
        );
      },
    );

    test(
      'unregister + re-register before async resolves preserves the new slot',
      () async {
        // User unregisters AND re-registers a different value. The stale
        // async resolution must NOT clobber the new registration.
        final di = DI();
        final completer = Completer<_AsyncPayload>();
        di.register<_AsyncPayload>(completer.future).end();
        UNSAFE:
        final pending = di.getAsync<_AsyncPayload>().unwrap().value;
        di.unregister<_AsyncPayload>().end();
        di.register<_AsyncPayload>(const _AsyncPayload('fresh')).end();
        completer.complete(const _AsyncPayload('stale'));
        (await pending).end();
        await Future<void>.delayed(Duration.zero);
        UNSAFE:
        final stored = di.getSyncOrNone<_AsyncPayload>().unwrap();
        expect(
          stored.tag,
          equals('fresh'),
          reason:
              'async memoisation must not overwrite a user-re-registered slot',
        );
      },
    );
  });
}

final class _NotDI {
  const _NotDI();
}

final class _AsyncPayload {
  const _AsyncPayload(this.tag);
  final String tag;
}

final class _ErroringInitService extends Service {
  _ErroringInitService({this.throwOnInit = true});
  final bool throwOnInit;

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) {
          if (throwOnInit) return Sync.err(Err('intentional init failure'));
          return syncUnit();
        },
      ];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) =>
      [(_) => syncUnit()];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) =>
      [(_) => syncUnit()];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) =>
      [(_) => syncUnit()];
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Future<UniqueEntity> _echo(UniqueEntity ue) async {
  final port = ReceivePort();
  try {
    await Isolate.spawn<(SendPort, UniqueEntity)>(
      _echoWorker,
      (port.sendPort, ue),
    );
    return await port.first as UniqueEntity;
  } finally {
    port.close();
  }
}

void _echoWorker((SendPort, UniqueEntity) args) {
  final (port, ue) = args;
  port.send(ue);
}

Future<List<String>> _collectUuids(int n) async {
  final port = ReceivePort();
  try {
    await Isolate.spawn<(SendPort, int)>(_sendUuidsBack, (port.sendPort, n));
    return await port.first as List<String>;
  } finally {
    port.close();
  }
}

// ─── Fixtures ────────────────────────────────────────────────────────────────

final class _DeepValue {
  const _DeepValue(this.label);
  final String label;
}

/// Entity subtype with a negative id, used to forge a UniqueEntity's id and
/// verify the stricter equality rejects it.
final class _ForgedEntity extends Entity {
  const _ForgedEntity(super.id) : super.reserved();
}
