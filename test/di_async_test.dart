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

// Tests for async (Future-valued) registrations: get returns Async, the
// dependency is replaced by its resolved sync value after first await,
// getAsync / getSyncOrNone behave correctly across the async→sync transition.

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Test fixtures ───────────────────────────────────────────────────────────

final class FetchedConfig {
  FetchedConfig(this.payload);
  final String payload;
}

final class Profile {
  Profile(this.name);
  final String name;
}

final _groupA = TypeEntity('groupA');
final _groupB = TypeEntity('groupB');

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('async registrations', () {
    test('Future registration is exposed as an Async dependency', () async {
      final di = DI();
      di
          .register<FetchedConfig>(
            Future<FetchedConfig>.delayed(
              const Duration(milliseconds: 10),
              () => FetchedConfig('loaded'),
            ),
          )
          .end();

      // Before resolution, getSyncOrNone returns None because it's async.
      expect(di.getSyncOrNone<FetchedConfig>().isNone(), isTrue);

      // getAsync returns the Async wrapper.
      UNSAFE:
      final result = await di.getAsync<FetchedConfig>().unwrap().value;
      UNSAFE:
      expect(result.unwrap().payload, 'loaded');
    });

    test('after first resolution, the dep is re-registered as Sync', () async {
      final di = DI();
      di
          .register<FetchedConfig>(
            Future<FetchedConfig>.value(FetchedConfig('cached')),
          )
          .end();

      // First read awaits the future.
      await di.getAsyncUnsafe<FetchedConfig>();

      // Second read is now synchronous.
      final sync = di.getSyncOrNone<FetchedConfig>();
      expect(sync.isSome(), isTrue);
      UNSAFE:
      expect(sync.unwrap().payload, 'cached');
    });

    test('getAsyncUnsafe returns the resolved value directly', () async {
      final di = DI();
      di.register<FetchedConfig>(Future.value(FetchedConfig('v'))).end();

      final c = await di.getAsyncUnsafe<FetchedConfig>();
      expect(c.payload, 'v');
    });
  });

  group('async + onRegister / onUnregister', () {
    test('onRegister fires once the Future resolves, with the resolved value',
        () async {
      final di = DI();
      Profile? observed;
      di
          .register<Profile>(
            Future<Profile>.delayed(
              const Duration(milliseconds: 10),
              () => Profile('alice'),
            ),
            onRegister: Some((p) => observed = p),
          )
          .end();

      // Drive resolution.
      UNSAFE:
      final p = await di.getAsyncUnsafe<Profile>();
      expect(p.name, 'alice');
      expect(observed?.name, 'alice');
    });

    test('onUnregister sees the resolved value (after async resolution)',
        () async {
      final di = DI();
      Profile? disposed;
      di.register<Profile>(
        Future<Profile>.value(Profile('bob')),
        onUnregister: Some((result) {
          UNSAFE:
          if (result.isOk()) disposed = result.unwrap();
        }),
      ).end();

      // Force resolution before unregistering so onUnregister receives the
      // resolved value rather than the still-pending Future.
      UNSAFE:
      (await di.getAsyncUnsafe<Profile>()).toString();
      UNSAFE:
      (await di.unregister<Profile>().toAsync().value).end();
      expect(disposed?.name, 'bob');
    });
  });

  group('async + groupEntity isolation', () {
    test('same type in different groups resolves independently', () async {
      final di = DI();
      di
          .register<FetchedConfig>(
            Future<FetchedConfig>.value(FetchedConfig('a')),
            groupEntity: _groupA,
          )
          .end();
      di
          .register<FetchedConfig>(
            Future<FetchedConfig>.value(FetchedConfig('b')),
            groupEntity: _groupB,
          )
          .end();

      UNSAFE:
      final pa = await di.getAsyncUnsafe<FetchedConfig>(groupEntity: _groupA);
      UNSAFE:
      final pb = await di.getAsyncUnsafe<FetchedConfig>(groupEntity: _groupB);
      expect(pa.payload, 'a');
      expect(pb.payload, 'b');
    });
  });

  group('async + untilSuper', () {
    test('untilSuper resolves with the awaited future value', () async {
      final di = DI();
      final waiter = di.untilSuper<Profile>();

      unawaited(
        Future<void>.microtask(() {
          di
              .register<Profile>(
                Future<Profile>.value(Profile('eve')),
              )
              .end();
        }),
      );

      UNSAFE:
      final p = await waiter.toAsync().value.then((r) => r.unwrap());
      expect(p.name, 'eve');
    });
  });

  group('resolveAll', () {
    test('completes once all async deps in a group have resolved', () async {
      final di = DI();
      di
          .register<FetchedConfig>(
            Future.delayed(
              const Duration(milliseconds: 10),
              () => FetchedConfig('one'),
            ),
          )
          .end();

      (await di.resolveAll().toAsync().value).end();

      // After resolveAll, the async deps have completed and are now sync.
      expect(di.getSyncOrNone<FetchedConfig>().isSome(), isTrue);
    });

    test('resolves multiple async deps of distinct types in parallel',
        () async {
      final di = DI();
      di
          .register<FetchedConfig>(
            Future.delayed(
              const Duration(milliseconds: 20),
              () => FetchedConfig('cfg'),
            ),
          )
          .end();
      di
          .register<Profile>(
            Future.delayed(
              const Duration(milliseconds: 20),
              () => Profile('p'),
            ),
          )
          .end();

      (await di.resolveAll().toAsync().value).end();

      expect(di.getSyncOrNone<FetchedConfig>().isSome(), isTrue);
      expect(di.getSyncOrNone<Profile>().isSome(), isTrue);
    });
  });
}
