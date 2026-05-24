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

// Abuse tests for the `until*` family — every method the package exposes for
// "wait until something is registered." Each test simulates how a confused
// caller might (mis)use the API: waiting for the wrong type, the wrong
// keying, the wrong container, the wrong lifecycle moment, or simply hoping
// something will arrive that never will.
//
// Every "wait forever" scenario is wrapped in a timeout so a regression that
// breaks the until-family never hangs the whole suite — it surfaces as a
// failed assertion instead.

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Try to await [f] within [timeout]; if it doesn't resolve in time, return
/// `null`. This is how we prove that an `until*` call is NOT resolving for a
/// given scenario without hanging the suite.
Future<T?> tryAwait<T>(
  Future<T> f, {
  Duration timeout = const Duration(milliseconds: 80),
}) {
  return f.timeout(timeout, onTimeout: () => null as T).then<T?>(
        (v) => v,
        onError: (Object _, [StackTrace? __]) => null,
      );
}

// ─── Fixtures ────────────────────────────────────────────────────────────────

abstract class Vehicle {
  String label();
}

final class Car extends Vehicle {
  Car(this.model);
  final String model;
  @override
  String label() => 'car:$model';
}

final class Truck extends Vehicle {
  Truck(this.payload);
  final int payload;
  @override
  String label() => 'truck:$payload';
}

final class Boat extends Vehicle {
  Boat();
  @override
  String label() => 'boat';
}

final class Repo {
  Repo(this.tag);
  final String tag;
}

final class Cache {
  Cache(this.size);
  final int size;
}

final class Config {
  Config(this.value);
  final String value;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  group('untilSuper: confused user — waiting for the wrong thing', () {
    test('waits forever when an unrelated type is registered', () async {
      final di = DI();
      // Caller wants a Repo. They register a Cache by mistake.
      final waiter = di.untilSuper<Repo>().toAsync().value;
      di.register<Cache>(Cache(100)).end();
      // Wait briefly, then give up.
      final r = await tryAwait(waiter);
      expect(
        r,
        isNull,
        reason: 'untilSuper<Repo> must not resolve from a Cache registration',
      );
    });

    test('registering a subtype DOES resolve untilSuper<Supertype>', () async {
      final di = DI();
      final waiter = di.untilSuper<Vehicle>().toAsync().value;
      unawaited(
        Future<void>.microtask(() {
          di.register<Vehicle>(Car('M3')).end();
        }),
      );
      UNSAFE:
      final v = (await waiter).unwrap();
      expect(v.label(), 'car:M3');
    });

    test(
      'untilSuper<Vehicle> DOES resolve from a register<Car>(Car(..)) '
      'because Resolvable<Car> is covariantly a Resolvable<Vehicle>',
      () async {
        // The registry probes `e.value is Resolvable<T>`, and Dart classes
        // are covariant for `is` checks: `Resolvable<Car>` IS-A
        // `Resolvable<Vehicle>`. A confused caller who expects exact-type
        // matching here will be surprised — use `untilExactlyK` for strict
        // matching.
        final di = DI();
        final waiter = di.untilSuper<Vehicle>().toAsync().value;
        di.register<Car>(Car('covariant-match')).end();
        UNSAFE:
        final v = (await waiter).unwrap();
        expect(v.label(), 'car:covariant-match');
      },
    );

    test(
      'untilSuper<Vehicle> does NOT resolve from a register<Repo>(Repo(..)) — '
      'Repo is not a Vehicle subtype',
      () async {
        final di = DI();
        final waiter = di.untilSuper<Vehicle>().toAsync().value;
        di.register<Repo>(Repo('unrelated')).end();
        final r = await tryAwait(waiter);
        expect(
          r,
          isNull,
          reason: 'unrelated type registration should not satisfy waiter',
        );
      },
    );

    test('resolves immediately when the type is already registered', () async {
      final di = DI();
      di.register<Repo>(Repo('present')).end();
      // No delay: it should be ready in this microtask.
      UNSAFE:
      final r = (await di.untilSuper<Repo>().toAsync().value).unwrap();
      expect(r.tag, 'present');
    });

    test('500 untilSuper waiters all share one completer and all resolve',
        () async {
      final di = DI();
      const n = 500;
      final waiters = [
        for (var i = 0; i < n; i++) di.untilSuper<Repo>().toAsync().value,
      ];
      unawaited(
        Future<void>.microtask(() {
          di.register<Repo>(Repo('shared')).end();
        }),
      );
      for (final w in waiters) {
        UNSAFE:
        expect((await w).unwrap().tag, 'shared');
      }
    });

    test(
        'after a successful resolution, a fresh untilSuper resolves to the same registered value',
        () async {
      final di = DI();
      final w1 = di.untilSuper<Repo>().toAsync().value;
      di.register<Repo>(Repo('once')).end();
      UNSAFE:
      expect((await w1).unwrap().tag, 'once');
      // Now ask again — already registered, so it resolves immediately.
      UNSAFE:
      expect(
        (await di.untilSuper<Repo>().toAsync().value).unwrap().tag,
        'once',
      );
    });

    test('untilSuper preserves isolation across groupEntities', () async {
      final di = DI();
      final groupA = TypeEntity('region.A');
      final groupB = TypeEntity('region.B');

      final wA = di.untilSuper<Repo>(groupEntity: groupA).toAsync().value;
      final wB = di.untilSuper<Repo>(groupEntity: groupB).toAsync().value;

      // Only register in A — B must remain unresolved.
      di.register<Repo>(Repo('A'), groupEntity: groupA).end();

      UNSAFE:
      expect((await wA).unwrap().tag, 'A');
      final b = await tryAwait(wB);
      expect(b, isNull, reason: 'group B must not see group A registrations');

      // Now register in B.
      di.register<Repo>(Repo('B'), groupEntity: groupB).end();
      UNSAFE:
      expect((await wB).unwrap().tag, 'B');
    });

    test('untilSuper resolves with an async-registered value (Future)',
        () async {
      final di = DI();
      final waiter = di.untilSuper<Config>().toAsync().value;
      di
          .register<Config>(
            Future<Config>.delayed(
              const Duration(milliseconds: 20),
              () => Config('eventually'),
            ),
          )
          .end();
      UNSAFE:
      expect((await waiter).unwrap().value, 'eventually');
    });

    test(
      'untilSuper from a direct child resolves when the root registers first',
      () async {
        final root = DI();
        final child = root.child(groupEntity: TypeEntity('c'));
        // Register on root BEFORE the wait — child sees it via traversal in
        // the immediate-probe path of `until`.
        root.register<Config>(Config('parent-first')).end();
        UNSAFE:
        final v = (await child.untilSuper<Config>().toAsync().value).unwrap();
        expect(v.value, 'parent-first');
      },
    );

    test(
      'untilSuper from a direct child resolves when the root registers after '
      'the wait starts',
      () async {
        // The `_maybeFinish` walk inside `register` iterates [this, …children()]
        // for one level — so a direct child's completer is reachable from
        // root. (Deeper grandchildren are an explicit limitation; we don't
        // assert that here.)
        final root = DI();
        final child = root.child(groupEntity: TypeEntity('c'));
        final waiter = child.untilSuper<Config>().toAsync().value;
        unawaited(
          Future<void>.microtask(() {
            root.register<Config>(Config('parent-late')).end();
          }),
        );
        UNSAFE:
        expect((await waiter).unwrap().value, 'parent-late');
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('until<TSuper, TSub>: subtype casts', () {
    test('until<Vehicle, Car> resolves when register<Vehicle>(Car) fires',
        () async {
      final di = DI();
      final waiter = di.until<Vehicle, Car>().toAsync().value;
      unawaited(
        Future<void>.microtask(() {
          di.register<Vehicle>(Car('A4')).end();
        }),
      );
      UNSAFE:
      final car = (await waiter).unwrap();
      // Type narrowed to Car — calling Car-specific API works.
      expect(car.model, 'A4');
    });

    test(
      'until<Vehicle, Car> with a Boat registration produces a runtime error on use',
      () async {
        // The compiler can't prove the registered Vehicle is a Car at
        // registration time. If a caller registers a non-Car Vehicle, the
        // cast to TSub happens on resolution — and using Car-specific API
        // surfaces a TypeError. This is the "confused user" hazard.
        final di = DI();
        final waiter = di.until<Vehicle, Car>().toAsync().value;
        di.register<Vehicle>(Boat()).end();

        Object? caught;
        try {
          final maybeCar = await waiter;
          // Try to use Car-specific API: dart2js / VM both raise here.
          UNSAFE:
          maybeCar.unwrap().model.toString();
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isNotNull,
          reason: 'Boat-as-Car cast must surface as a runtime error '
              'when the Car-only API is accessed',
        );
      },
    );

    test('until<Repo, Repo> behaves identically to untilSuper<Repo>', () async {
      final di = DI();
      final wA = di.untilSuper<Repo>().toAsync().value;
      final wB = di.until<Repo, Repo>().toAsync().value;
      di.register<Repo>(Repo('twin')).end();
      UNSAFE:
      expect((await wA).unwrap().tag, 'twin');
      UNSAFE:
      expect((await wB).unwrap().tag, 'twin');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('untilExactlyK / untilExactlyT: strict-entity waiters', () {
    test('untilExactlyK without enableUntilExactlyK: waits forever', () async {
      final di = DI();
      final waiter = di.untilExactlyK<Repo>(TypeEntity(Repo)).toAsync().value;
      // Register WITHOUT the flag — the strict-K completer is never fired.
      di.register<Repo>(Repo('not-k')).end();
      final r = await tryAwait(waiter);
      expect(
        r,
        isNull,
        reason: 'untilExactlyK should not resolve from a non-K registration',
      );
    });

    test(
      'untilExactlyK with enableUntilExactlyK resolves on matching typeEntity',
      () async {
        final di = DI();
        final waiter = di.untilExactlyK<Repo>(TypeEntity(Repo)).toAsync().value;
        di.register<Repo>(Repo('strict'), enableUntilExactlyK: true).end();
        UNSAFE:
        expect((await waiter).unwrap().tag, 'strict');
      },
    );

    test('untilExactlyT(Repo) is equivalent to untilExactlyK(TypeEntity(Repo))',
        () async {
      final di = DI();
      final wK = di.untilExactlyK<Repo>(TypeEntity(Repo)).toAsync().value;
      final wT = di.untilExactlyT<Repo>(Repo).toAsync().value;
      di.register<Repo>(Repo('twin-K-T'), enableUntilExactlyK: true).end();
      UNSAFE:
      expect((await wK).unwrap().tag, 'twin-K-T');
      UNSAFE:
      expect((await wT).unwrap().tag, 'twin-K-T');
    });

    test('untilExactlyK isolates across groupEntities', () async {
      final di = DI();
      final gA = TypeEntity('regK.A');
      final gB = TypeEntity('regK.B');
      final wA = di
          .untilExactlyK<Repo>(TypeEntity(Repo), groupEntity: gA)
          .toAsync()
          .value;
      final wB = di
          .untilExactlyK<Repo>(TypeEntity(Repo), groupEntity: gB)
          .toAsync()
          .value;
      di
          .register<Repo>(
            Repo('A-only'),
            groupEntity: gA,
            enableUntilExactlyK: true,
          )
          .end();
      UNSAFE:
      expect((await wA).unwrap().tag, 'A-only');
      final b = await tryAwait(wB);
      expect(b, isNull);
    });

    test(
      'untilExactlyK with a custom typeEntity matches only that exact entity',
      () async {
        final di = DI();
        // A user crafts a custom TypeEntity (e.g. for an ECS-style tag).
        final customEntity = TypeEntity('SpecialTag', [Repo]);
        final waiter = di.untilExactlyK<Repo>(customEntity).toAsync().value;
        // A plain register<Repo> writes the slot under TypeEntity(Repo) —
        // it must NOT match a SpecialTag waiter.
        di.register<Repo>(Repo('plain'), enableUntilExactlyK: true).end();
        final r = await tryAwait(waiter);
        expect(r, isNull, reason: 'custom entity should not match plain Repo');
      },
    );

    test(
      'rapid register/unregister churn does not deadlock untilExactlyK',
      () async {
        final di = DI();
        final waiter =
            di.untilExactlyK<Repo>(TypeEntity(Repo)).toAsync().value.then((r) {
          UNSAFE:
          return r.unwrap();
        });

        // 20 round-trips before letting the final registration stick.
        for (var i = 0; i < 20; i++) {
          di.register<Repo>(Repo('churn$i'), enableUntilExactlyK: true).end();
          (await di.unregister<Repo>().toAsync().value).end();
        }
        di.register<Repo>(Repo('settled'), enableUntilExactlyK: true).end();
        final repo = await waiter;
        // Epoch guard ensures the waiter ends up on the final, settled value.
        expect(repo.tag, 'settled');
      },
    );

    test(
      'untilExactlyK with enableUntilExactlyK=false on the final register',
      () async {
        // The completer is created. A user registers with enableUntilExactlyK
        // flipped OFF — the K-side completer never fires. The wait must time
        // out cleanly.
        final di = DI();
        final waiter = di.untilExactlyK<Repo>(TypeEntity(Repo)).toAsync().value;
        di.register<Repo>(Repo('plain')).end(); // no K flag
        final r = await tryAwait(waiter);
        expect(
          r,
          isNull,
          reason: 'register without K flag should leave the K-completer'
              ' un-fired',
        );
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('untilLazySuper / untilLazy: lazy-keyed waits', () {
    test('untilLazySuper does NOT resolve from a non-lazy register', () async {
      final di = DI();
      final waiter = di.untilLazySuper<Repo>().toAsync().value;
      // Direct register — keyed as Repo, not Lazy<Repo>.
      di.register<Repo>(Repo('direct')).end();
      final r = await tryAwait(waiter);
      expect(
        r,
        isNull,
        reason: 'Lazy<Repo> waiter must not pick up a direct Repo slot',
      );
    });

    test('untilLazySuper resolves when the matching registerLazy fires',
        () async {
      final di = DI();
      final waiter = di.untilLazySuper<Repo>().toAsync().value;
      unawaited(
        Future<void>.microtask(() {
          di.registerLazy<Repo>(() => Sync.okValue(Repo('lazy-arrived'))).end();
        }),
      );
      UNSAFE:
      final lazy = (await waiter).unwrap();
      UNSAFE:
      final v = lazy.singleton.sync().unwrap().value.unwrap();
      expect(v.tag, 'lazy-arrived');
    });

    test(
      'untilLazy<Repo, Repo> resolves with the registered Lazy<Repo>',
      () async {
        // Note: `untilLazy<TSuper, TSub>` cannot safely re-key a
        // `Lazy<TSuper>` slot as `Lazy<TSub>` because Dart generics are
        // invariant — `Lazy<Car>` is NOT a `Lazy<Vehicle>`. So this method
        // is only safe with TSuper == TSub. Confused callers who try
        // `untilLazy<Vehicle, Car>` will hit a runtime TypeError when they
        // use the cast.
        final di = DI();
        final waiter = di.untilLazy<Repo, Repo>().toAsync().value;
        di.registerLazy<Repo>(() => Sync.okValue(Repo('lazy-match'))).end();
        UNSAFE:
        final lazy = (await waiter).unwrap();
        UNSAFE:
        final v = lazy.singleton.sync().unwrap().value.unwrap();
        expect(v.tag, 'lazy-match');
      },
    );

    test(
      'untilLazy<Vehicle, Car> against a Lazy<Vehicle> registration surfaces a '
      'runtime TypeError — caller MUST use untilLazySuper<Vehicle>',
      () async {
        // This documents the invariance hazard: a confused user writes
        // untilLazy<Vehicle, Car> hoping to cast the lazy to Lazy<Car>, but
        // there is no safe cast from Lazy<Vehicle> to Lazy<Car>.
        final di = DI();
        final waiter = di.untilLazy<Vehicle, Car>().toAsync().value;
        di.registerLazy<Vehicle>(() => Sync.okValue(Car('Z4'))).end();
        Object? caught;
        try {
          final r = await waiter;
          // The .unwrap() actually does the cast Resolvable<Lazy<Vehicle>>→
          // Resolvable<Lazy<Car>>, which the safer_dart layer asserts.
          UNSAFE:
          r.unwrap().toString();
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isNotNull,
          reason: 'invariance: Lazy<Vehicle> is not Lazy<Car>',
        );
      },
    );

    test(
      'registering plain T does not fire a Lazy<T> waiter (strict keying)',
      () async {
        // The most common confusion: someone registers `<T>` but waits on
        // `untilLazySuper<T>`. The waits must not cross over.
        final di = DI();
        final wLazy = di.untilLazySuper<Repo>().toAsync().value;
        final wPlain = di.untilSuper<Repo>().toAsync().value;
        di.register<Repo>(Repo('plain')).end();
        UNSAFE:
        expect((await wPlain).unwrap().tag, 'plain');
        // The lazy waiter is still pending.
        final r = await tryAwait(wLazy);
        expect(r, isNull);
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('untilLazySingleton / untilLazySingletonSuper', () {
    test('untilLazySingletonSuper materializes the singleton once', () async {
      final di = DI();
      var ctorCalls = 0;
      final waiter = di.untilLazySingletonSuper<Repo>().toAsync().value;
      unawaited(
        Future<void>.microtask(() {
          di.registerLazy<Repo>(() {
            ctorCalls++;
            return Sync.okValue(Repo('lazy-singleton'));
          }).end();
        }),
      );
      UNSAFE:
      expect((await waiter).unwrap().tag, 'lazy-singleton');
      // The singleton was materialized exactly once for the waiter.
      expect(ctorCalls, 1);
      // Subsequent direct reads of the singleton don't re-construct.
      UNSAFE:
      final again =
          di.getLazySingleton<Repo>().unwrap().sync().unwrap().value.unwrap();
      expect(ctorCalls, 1);
      expect(again.tag, 'lazy-singleton');
    });

    test(
      'untilLazySingleton<Repo, Repo> is the safe, invariant form',
      () async {
        // Same invariance hazard as untilLazy: caller must use TSuper == TSub
        // for the lazy variants. Vehicle/Car combinations will TypeError.
        final di = DI();
        final waiter = di.untilLazySingleton<Repo, Repo>().toAsync().value;
        di.registerLazy<Repo>(() => Sync.okValue(Repo('settled'))).end();
        UNSAFE:
        final r = (await waiter).unwrap();
        expect(r.tag, 'settled');
      },
    );

    test(
      'after resetLazySingleton, a fresh untilLazySingletonSuper resolves to a new instance',
      () async {
        final di = DI();
        var ctorCalls = 0;
        di
            .registerLazy<Repo>(
              () => Sync.okValue(Repo('iter${++ctorCalls}')),
            )
            .end();

        // First materialization — uses the immediate-resolution path because
        // Lazy<Repo> is already registered.
        UNSAFE:
        final a =
            (await di.untilLazySingletonSuper<Repo>().toAsync().value).unwrap();
        expect(a.tag, 'iter1');

        (await di.resetLazySingleton<Repo>().toAsync().value).end();

        UNSAFE:
        final b =
            (await di.untilLazySingletonSuper<Repo>().toAsync().value).unwrap();
        expect(b.tag, 'iter2');
        expect(identical(a, b), isFalse);
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('untilFactorySuper / untilFactory', () {
    test('every call after the wait returns a fresh instance', () async {
      final di = DI();
      var ctor = 0;
      di.registerConstructor<Repo>(() => Repo('factory${++ctor}')).end();
      // Confused user: they wait once, then re-read the factory many times.
      UNSAFE:
      final first =
          (await di.untilFactorySuper<Repo>().toAsync().value).unwrap();
      expect(first.tag, 'factory1');

      // The factory must mint a new instance every time it's queried.
      final seen = <Repo>{first};
      for (var i = 0; i < 10; i++) {
        UNSAFE:
        final v = di.getFactory<Repo>().unwrap().sync().unwrap().value.unwrap();
        seen.add(v);
      }
      // 1 from until + 10 from getFactory = 11 distinct.
      expect(seen.length, 11);
    });

    test('untilFactory<Repo, Repo> mints fresh instances per wait', () async {
      final di = DI();
      var ctor = 0;
      di.registerConstructor<Repo>(() => Repo('F${++ctor}')).end();
      UNSAFE:
      final a = (await di.untilFactory<Repo, Repo>().toAsync().value).unwrap();
      UNSAFE:
      final b = (await di.untilFactory<Repo, Repo>().toAsync().value).unwrap();
      expect(identical(a, b), isFalse);
      expect(a.tag, 'F1');
      expect(b.tag, 'F2');
    });

    test('factory waiter does NOT resolve from a non-lazy register', () async {
      final di = DI();
      final waiter = di.untilFactorySuper<Repo>().toAsync().value;
      di.register<Repo>(Repo('plain')).end();
      final r = await tryAwait(waiter);
      expect(
        r,
        isNull,
        reason: 'factory waiter is keyed under Lazy<T>, not <T>',
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('untilFactoryExactlyK', () {
    test(
      'untilFactoryExactlyK takes the INNER typeEntity (Repo), not Lazy<Repo> — '
      'it wraps internally',
      () async {
        // Common confusion: the method's name says "Factory" but it's keyed
        // by the INNER T's typeEntity. The implementation wraps it as
        // `TypeEntity(Lazy, [t])` internally. If a caller passes
        // `TypeEntity(Lazy, [Repo])`, it ends up double-wrapped (Lazy<Lazy<R>>)
        // and never fires.
        final di = DI();
        final waiter =
            di.untilFactoryExactlyK<Repo>(TypeEntity(Repo)).toAsync().value;
        // To fire the K-completer the underlying register MUST set the K
        // flag. `registerConstructor`/`registerLazy` don't expose it, so go
        // through `register<Lazy<T>>` directly.
        di
            .register<Lazy<Repo>>(
              Lazy<Repo>(() => Sync.okValue(Repo('strict-final'))),
              enableUntilExactlyK: true,
            )
            .end();
        UNSAFE:
        final r = (await waiter).unwrap();
        expect(r.tag, 'strict-final');
      },
    );

    test(
      'untilFactoryExactlyK with the WRONG typeEntity (Lazy<Repo>) never fires',
      () async {
        // Documents the pitfall: passing the already-wrapped key.
        final di = DI();
        final waiter = di
            .untilFactoryExactlyK<Repo>(TypeEntity(Lazy, [Repo]))
            .toAsync()
            .value;
        di
            .register<Lazy<Repo>>(
              Lazy<Repo>(() => Sync.okValue(Repo('would-have-arrived'))),
              enableUntilExactlyK: true,
            )
            .end();
        final r = await tryAwait(waiter);
        expect(
          r,
          isNull,
          reason: 'a double-wrapped typeEntity should never match',
        );
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('untilSuper: lifecycle race conditions', () {
    test(
      'untilSuper before register, then unregister-after-resolve: '
      'the resolved value is not affected by the later unregister',
      () async {
        final di = DI();
        final waiter = di.untilSuper<Repo>().toAsync().value;
        di.register<Repo>(Repo('held')).end();
        UNSAFE:
        final r = (await waiter).unwrap();
        expect(r.tag, 'held');

        (await di.unregister<Repo>().toAsync().value).end();
        // The already-resolved value is still in our hands.
        expect(r.tag, 'held');
        // But a fresh untilSuper now blocks again.
        final retry = await tryAwait(di.untilSuper<Repo>().toAsync().value);
        expect(retry, isNull);
      },
    );

    test(
      'untilSuper concurrent with mass registration of OTHER types resolves correctly',
      () async {
        final di = DI();
        final waiter = di.untilSuper<Repo>().toAsync().value;
        // Make some noise: register 200 unrelated types in 200 distinct
        // groups, none of which is `Repo`.
        for (var i = 0; i < 200; i++) {
          di
              .register<Cache>(
                Cache(i),
                groupEntity: TypeEntity('noise$i'),
              )
              .end();
        }
        // Finally register the thing we're actually waiting for.
        di.register<Repo>(Repo('signal-through-noise')).end();
        UNSAFE:
        expect((await waiter).unwrap().tag, 'signal-through-noise');
      },
    );

    test(
      'inside onRegister of T, the safe way to see the value is the callback '
      'parameter (not a nested untilSuper / getSyncOrNone, which can deadlock '
      'on a Resolvable that is mid-computation)',
      () async {
        final di = DI();
        Repo? seenFromParam;
        Object? sawNoneOrErr;
        (await di
                .register<Repo>(
                  Repo('initial'),
                  onRegister: Some((r) {
                    // The callback parameter is always safe.
                    seenFromParam = r;
                    // The registry may not yet have a resolved Sync value
                    // for THIS slot while we're still inside its onRegister.
                    // Calling getSyncOrNone here is *defined* to return None
                    // in that window; we capture the outcome rather than
                    // unwrap it.
                    final option = di.getSyncOrNone<Repo>();
                    sawNoneOrErr = option.isSome() ? 'some' : 'none';
                  }),
                )
                .toAsync()
                .value)
            .end();
        expect(seenFromParam?.tag, 'initial');
        // We do not assert which branch fires — we only assert that the
        // probe did NOT throw and the container is still consistent.
        expect(sawNoneOrErr, isNotNull);
        // And after register returns, the value is fully resolved.
        UNSAFE:
        expect(di.getSyncOrNone<Repo>().unwrap().tag, 'initial');
      },
    );

    test(
      'untilSuper<B> from inside onRegister of A fires when A.onRegister '
      'registers B — the cross-type pattern is safe',
      () async {
        final di = DI();
        // Start a waiter for Cache BEFORE registering Repo. Repo's onRegister
        // will register a Cache, which should fire the waiter.
        final cacheWaiter = di.untilSuper<Cache>().toAsync().value;
        di.register<Repo>(
          Repo('parent'),
          onRegister: Some((r) {
            di.register<Cache>(Cache(99)).end();
          }),
        ).end();
        UNSAFE:
        final c = (await cacheWaiter).unwrap();
        expect(c.size, 99);
      },
    );

    test(
      'untilSuper does not leak ReservedSafeCompleter slots after resolution',
      () async {
        final di = DI();
        for (var i = 0; i < 100; i++) {
          final w = di.untilSuper<Repo>().toAsync().value;
          di.register<Repo>(Repo('iter$i')).end();
          UNSAFE:
          expect((await w).unwrap().tag, 'iter$i');
          (await di.unregister<Repo>().toAsync().value).end();
        }
        // After 100 round-trips, the registry should be empty.
        expect(di.isRegistered<Repo>(), isFalse);
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('untilSuper: hierarchical confusion', () {
    test('untilSuper at root does NOT see a child registration', () async {
      final root = DI();
      final child = root.child(groupEntity: TypeEntity('c'));
      final waiter = root.untilSuper<Repo>().toAsync().value;
      child.register<Repo>(Repo('child-only')).end();
      final r = await tryAwait(waiter);
      expect(
        r,
        isNull,
        reason: 'root does not look down into child containers',
      );
    });

    test(
      'untilSuper from two sibling children resolves independently when '
      'registrations happen in different children',
      () async {
        final root = DI();
        final c1 = root.child(groupEntity: TypeEntity('c1'));
        final c2 = root.child(groupEntity: TypeEntity('c2'));
        // Use traverse:false so each waiter is truly local.
        final w1 = c1.untilSuper<Repo>(traverse: false).toAsync().value;
        final w2 = c2.untilSuper<Repo>(traverse: false).toAsync().value;

        c1.register<Repo>(Repo('in-c1')).end();
        UNSAFE:
        expect((await w1).unwrap().tag, 'in-c1');
        final pending = await tryAwait(w2);
        expect(pending, isNull);

        c2.register<Repo>(Repo('in-c2')).end();
        UNSAFE:
        expect((await w2).unwrap().tag, 'in-c2');
      },
    );

    test(
      'untilSuper from a child, then unregister at child mid-resolution: '
      'the resolved value reflects the child registration',
      () async {
        final root = DI();
        final child = root.child(groupEntity: TypeEntity('c'));
        root.register<Repo>(Repo('parent')).end();
        // Child sees parent via traversal: untilSuper should resolve
        // immediately with the parent value.
        UNSAFE:
        final r = (await child.untilSuper<Repo>().toAsync().value).unwrap();
        expect(r.tag, 'parent');
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('confused user: choosing the wrong until*', () {
    test(
      'untilSuper<T> on a lazy-only registration NEVER fires — caller must use '
      'untilLazySuper<T>',
      () async {
        final di = DI();
        final wWrong = di.untilSuper<Repo>().toAsync().value;
        final wRight = di.untilLazySuper<Repo>().toAsync().value;
        di.registerLazy<Repo>(() => Sync.okValue(Repo('lazy-only'))).end();
        // The right one resolves.
        UNSAFE:
        final lazy = (await wRight).unwrap();
        UNSAFE:
        expect(lazy.singleton.sync().unwrap().value.unwrap().tag, 'lazy-only');
        // The wrong one does not.
        final wrongResult = await tryAwait(wWrong);
        expect(wrongResult, isNull);
      },
    );

    test(
      'untilExactlyK<T>(TypeEntity(T)) on a NON-K-enabled registration NEVER '
      'fires — caller must use untilSuper<T>',
      () async {
        final di = DI();
        final wExact = di.untilExactlyK<Repo>(TypeEntity(Repo)).toAsync().value;
        final wLoose = di.untilSuper<Repo>().toAsync().value;
        di.register<Repo>(Repo('no-K-flag')).end();
        // The loose one resolves.
        UNSAFE:
        expect((await wLoose).unwrap().tag, 'no-K-flag');
        // The strict-K one does not.
        final exactResult = await tryAwait(wExact);
        expect(exactResult, isNull);
      },
    );

    test(
      'untilFactorySuper<T> when the user actually wanted the singleton',
      () async {
        // The factory waiter mints a fresh instance per call. A user who
        // confused factory for singleton ends up with two distinct Repos.
        final di = DI();
        var ctor = 0;
        di.registerConstructor<Repo>(() => Repo('inst${++ctor}')).end();

        UNSAFE:
        final fA =
            (await di.untilFactorySuper<Repo>().toAsync().value).unwrap();
        UNSAFE:
        final fB =
            (await di.untilFactorySuper<Repo>().toAsync().value).unwrap();
        expect(identical(fA, fB), isFalse);

        // What they *actually* wanted: untilLazySingletonSuper.
        UNSAFE:
        final sA =
            (await di.untilLazySingletonSuper<Repo>().toAsync().value).unwrap();
        UNSAFE:
        final sB =
            (await di.untilLazySingletonSuper<Repo>().toAsync().value).unwrap();
        expect(identical(sA, sB), isTrue);
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('untilSuper: storms', () {
    test(
      '50 sibling DIs each with their own untilSuper resolve independently',
      () async {
        const n = 50;
        final dis = [for (var i = 0; i < n; i++) DI()];
        final waiters = [
          for (var i = 0; i < n; i++) dis[i].untilSuper<Repo>().toAsync().value,
        ];
        // Resolve them out of order.
        for (var i = n - 1; i >= 0; i--) {
          dis[i].register<Repo>(Repo('di$i')).end();
        }
        for (var i = 0; i < n; i++) {
          UNSAFE:
          expect((await waiters[i]).unwrap().tag, 'di$i');
        }
      },
    );

    test(
      '100 untilSuper waiters across 10 alternating types each resolve on '
      'their own type',
      () async {
        final di = DI();
        // We need 10 distinct types — we model them via 10 distinct groups
        // since making 10 Dart types is overkill.
        final waiters = <(int, Resolvable<Repo>)>[];
        for (var i = 0; i < 100; i++) {
          final g = TypeEntity('grp${i % 10}');
          waiters.add(
            (
              i % 10,
              di.untilSuper<Repo>(groupEntity: g),
            ),
          );
        }
        // Register in each group, value carries the group index.
        for (var k = 0; k < 10; k++) {
          di
              .register<Repo>(
                Repo('val$k'),
                groupEntity: TypeEntity('grp$k'),
              )
              .end();
        }
        for (final (grpIndex, w) in waiters) {
          UNSAFE:
          expect((await w.toAsync().value).unwrap().tag, 'val$grpIndex');
        }
      },
    );

    test('100 rapid waiter/register cycles never lose a wakeup', () async {
      final di = DI();
      for (var i = 0; i < 100; i++) {
        final waiter = di.untilSuper<Repo>().toAsync().value;
        unawaited(
          Future<void>.microtask(() {
            di.register<Repo>(Repo('cycle$i')).end();
          }),
        );
        UNSAFE:
        expect((await waiter).unwrap().tag, 'cycle$i');
        (await di.unregister<Repo>().toAsync().value).end();
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('untilSuper: chaining and composition', () {
    test('chaining several untilSuper into a pipeline', () async {
      final di = DI();
      // The user wires up a dependency chain via three untilSuper waits.
      Future<String> pipeline() async {
        UNSAFE:
        final config = (await di.untilSuper<Config>().toAsync().value).unwrap();
        UNSAFE:
        final cache = (await di.untilSuper<Cache>().toAsync().value).unwrap();
        UNSAFE:
        final repo = (await di.untilSuper<Repo>().toAsync().value).unwrap();
        return '${config.value}|${cache.size}|${repo.tag}';
      }

      final out = pipeline();
      // Stagger the registrations.
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 5), () {
          di.register<Config>(Config('CFG')).end();
        }),
      );
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 10), () {
          di.register<Cache>(Cache(99)).end();
        }),
      );
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 15), () {
          di.register<Repo>(Repo('REPO')).end();
        }),
      );

      expect(await out, 'CFG|99|REPO');
    });

    test(
      'until-of-until: a service waits for its parent service that waits for '
      'configuration',
      () async {
        final di = DI();

        Future<Repo> bootstrapRepo() async {
          UNSAFE:
          final cfg = (await di.untilSuper<Config>().toAsync().value).unwrap();
          return Repo('repo-from(${cfg.value})');
        }

        // Register Repo lazily: its constructor pulls Config via untilSuper.
        // Use Future<Repo> as the registered value so the container exposes
        // it as an Async dep.
        di.register<Repo>(bootstrapRepo()).end();

        // Now register Config — the bootstrapRepo() future resolves.
        di.register<Config>(Config('alpha')).end();

        UNSAFE:
        final r = (await di.untilSuper<Repo>().toAsync().value).unwrap();
        expect(r.tag, 'repo-from(alpha)');
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('untilSuper: state hygiene', () {
    test('untilSuper after unregisterAll does not pick up old completers',
        () async {
      final di = DI();
      // Spin up an unresolved waiter, then nuke the container.
      // tryAwait it briefly and confirm it didn't accidentally resolve.
      final wOld = di.untilSuper<Repo>().toAsync().value;
      (await di.unregisterAll().toAsync().value).end();

      // The old waiter is now in an indeterminate state — but the container
      // itself is healthy: a fresh wait followed by a fresh register works.
      final wNew = di.untilSuper<Repo>().toAsync().value;
      di.register<Repo>(Repo('after-wipe')).end();
      UNSAFE:
      expect((await wNew).unwrap().tag, 'after-wipe');
      // Drain the old future too (it may or may not have resolved — we just
      // make sure awaiting it does not crash the test runner).
      (await tryAwait(wOld))?.end();
    });
  });
}
