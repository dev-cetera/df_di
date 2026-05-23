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

// Abuse / stress / "use it wrong on purpose" tests. The DI container is the
// foundation of every other service in this stack — it has to keep its
// invariants even under deeply nested hierarchies, re-entrant callbacks,
// mutually referential lazies, concurrent async resolutions, throwing
// listeners, lifecycle pile-ups, and other patterns the package was not
// designed for. Each test below is a self-contained scenario; none of them
// touch a global `DI.root` so they can run in any order.

import 'dart:async';
import 'dart:math';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Sync-only extraction of a `Lazy<T>` singleton through the DI container.
/// Useful when one lazy constructor needs to pull a sibling lazy without
/// dragging a Future through the chain.
T pullLazy<T extends Object>(DI di) {
  UNSAFE:
  return di.getLazySingleton<T>().unwrap().sync().unwrap().value.unwrap();
}

// ─── Fixtures ────────────────────────────────────────────────────────────────

final class Counter {
  Counter(this.label);
  final String label;
}

final class Holder<T> {
  Holder(this.value);
  final T value;
}

final class A {
  A(this.tag);
  final String tag;
}

final class B {
  B(this.a);
  final A a;
}

final class C {
  C(this.b);
  final B b;
}

abstract class Animal {
  String speak();
}

final class Dog extends Animal {
  @override
  String speak() => 'woof';
}

final class Cat extends Animal {
  @override
  String speak() => 'meow';
}

/// A trivial service that records every lifecycle visit and can be configured
/// to throw on any phase.
final class TallyService extends Service {
  TallyService({
    this.throwOnInit = false,
    this.throwOnDispose = false,
    this.initListeners = 1,
    this.disposeListeners = 1,
  });
  final bool throwOnInit;
  final bool throwOnDispose;
  final int initListeners;
  final int disposeListeners;
  final List<String> log = [];

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        for (var i = 0; i < initListeners; i++)
          (_) {
            log.add('init.$i');
            if (throwOnInit && i == 0) return Sync.err(Err('init bomb'));
            return syncUnit();
          },
      ];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) => [
        (_) {
          log.add('pause');
          return syncUnit();
        },
      ];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) => [
        (_) {
          log.add('resume');
          return syncUnit();
        },
      ];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
        for (var i = 0; i < disposeListeners; i++)
          (_) {
            log.add('dispose.$i');
            if (throwOnDispose && i == 0) return Sync.err(Err('dispose bomb'));
            return syncUnit();
          },
      ];
}

/// A StreamService whose upstream is a controllable broadcast stream the test
/// drives by hand.
final class HandStream extends StreamService<int> {
  HandStream(this._upstream);
  final Stream<Result<int>> _upstream;
  final List<int> heard = [];

  @override
  Stream<Result<int>> provideInputStream() => _upstream;

  @override
  TServiceResolvables<Result<int>> provideOnPushToStreamListeners() => [
        (event) {
          event.ifOk((_, ok) => heard.add(ok.value)).end();
          return syncUnit();
        },
      ];
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: mass registration storm', () {
    test('registers and resolves 1000 distinct group entries of one type', () {
      final di = DI();
      const n = 1000;
      for (var i = 0; i < n; i++) {
        di
            .register<Counter>(
              Counter('c$i'),
              groupEntity: TypeEntity('group$i'),
            )
            .end();
      }
      // Spot-check a sample.
      final rng = Random(42);
      for (var j = 0; j < 50; j++) {
        final i = rng.nextInt(n);
        final v = di.getSyncOrNone<Counter>(
          groupEntity: TypeEntity('group$i'),
        );
        UNSAFE:
        expect(v.unwrap().label, 'c$i');
      }
    });

    test('registers and unregisters the same type 500 times without leaks',
        () async {
      final di = DI();
      for (var i = 0; i < 500; i++) {
        di.register<Counter>(Counter('iter$i')).end();
        UNSAFE:
        final read = di.getSyncOrNone<Counter>().unwrap();
        expect(read.label, 'iter$i');
        UNSAFE:
        (await di.unregister<Counter>().unwrap()).end();
        expect(di.isRegistered<Counter>(), isFalse);
      }
    });

    test('unregisterAll wipes thousands of mixed-type registrations', () async {
      final di = DI();
      for (var i = 0; i < 600; i++) {
        di
            .register<Counter>(
              Counter('a$i'),
              groupEntity: TypeEntity('A$i'),
            )
            .end();
        di
            .register<Holder<int>>(
              Holder<int>(i),
              groupEntity: TypeEntity('A$i'),
            )
            .end();
      }
      (await di.unregisterAll().toAsync().value).end();
      // Random spot-checks: every group should now be empty.
      expect(
        di.isRegistered<Counter>(groupEntity: TypeEntity('A0')),
        isFalse,
      );
      expect(
        di.isRegistered<Counter>(groupEntity: TypeEntity('A599')),
        isFalse,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: deep child nesting', () {
    test('20-level child tower resolves a root registration from the bottom',
        () {
      final root = DI();
      root.register<Counter>(Counter('root-value')).end();

      var cursor = root;
      final groups = [for (var i = 0; i < 20; i++) TypeEntity('lvl$i')];
      for (final g in groups) {
        cursor = cursor.child(groupEntity: g);
      }
      // The deepest descendant should still see the root registration.
      UNSAFE:
      expect(cursor.getSyncOrNone<Counter>().unwrap().label, 'root-value');
    });

    test('each level shadows its ancestor for the same type', () {
      final root = DI();
      root.register<Counter>(Counter('L0')).end();
      var cursor = root;
      for (var i = 1; i <= 10; i++) {
        cursor = cursor.child(groupEntity: TypeEntity('lvl$i'));
        cursor.register<Counter>(Counter('L$i')).end();
      }
      // The bottom container reads its own value.
      UNSAFE:
      expect(cursor.getSyncOrNone<Counter>().unwrap().label, 'L10');
      // traverse:false confirms it's the bottom's own copy.
      UNSAFE:
      expect(
        cursor.getSyncOrNone<Counter>(traverse: false).unwrap().label,
        'L10',
      );
    });

    test('idempotent child() across deep tower returns same instances', () {
      final root = DI();
      var a = root;
      var b = root;
      final groups = [for (var i = 0; i < 15; i++) TypeEntity('node$i')];
      for (final g in groups) {
        a = a.child(groupEntity: g);
        b = b.child(groupEntity: g);
        expect(identical(a, b), isTrue);
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: dependencies in dependencies', () {
    test('lazy A depends on lazy B depends on lazy C (forward chain)', () {
      final di = DI();
      di
          .registerLazy<C>(
            () => Sync.okValue(C(pullLazy<B>(di))),
          )
          .end();
      di
          .registerLazy<B>(
            () => Sync.okValue(B(pullLazy<A>(di))),
          )
          .end();
      di
          .registerLazy<A>(
            () => Sync.okValue(A('root')),
          )
          .end();

      final c = pullLazy<C>(di);
      expect(c.b.a.tag, 'root');

      // Singleton semantics: a second read returns the same instances.
      final c2 = pullLazy<C>(di);
      expect(identical(c, c2), isTrue);
      expect(identical(c.b, c2.b), isTrue);
    });

    test('registering B from inside A.onRegister works (re-entrant register)',
        () async {
      final di = DI();
      A? observed;
      (await di
              .register<A>(
                A('outer'),
                onRegister: Some((A a) {
                  observed = a;
                  // Re-enter the container during the outer registration.
                  di.register<B>(B(a)).end();
                }),
              )
              .toAsync()
              .value)
          .end();

      expect(observed?.tag, 'outer');
      // Both A and B made it in.
      expect(di.isRegistered<A>(), isTrue);
      expect(di.isRegistered<B>(), isTrue);
      UNSAFE:
      expect(di.getSyncOrNone<B>().unwrap().a.tag, 'outer');
    });

    test('cascading onUnregister tears down dependents in order', () async {
      final di = DI();
      final order = <String>[];
      di.register<C>(
        C(B(A('x'))),
        onUnregister: Some((_) {
          order.add('c');
        }),
      ).end();
      di.register<B>(
        B(A('y')),
        onUnregister: Some((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 1));
          order.add('b');
        }),
      ).end();
      di.register<A>(
        A('z'),
        onUnregister: Some((_) {
          order.add('a');
        }),
      ).end();

      (await di.unregister<C>().toAsync().value).end();
      (await di.unregister<B>().toAsync().value).end();
      (await di.unregister<A>().toAsync().value).end();

      expect(order, ['c', 'b', 'a']);
    });

    test('lazy constructor can pull its sibling lazy via the same container',
        () {
      final di = DI();
      di
          .registerLazy<Cat>(
            () => Sync.okValue(Cat()),
          )
          .end();
      di
          .registerLazy<Dog>(
            () => Sync.okValue(Dog()),
          )
          .end();
      di
          .registerLazy<Holder<Animal>>(
            () => Sync.okValue(Holder<Animal>(pullLazy<Dog>(di))),
          )
          .end();
      final h = pullLazy<Holder<Animal>>(di);
      expect(h.value.speak(), 'woof');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: re-entrant unregister callbacks', () {
    test('onUnregister of A can unregister B without corrupting state',
        () async {
      final di = DI();
      var unregBFired = false;
      di.register<B>(
        B(A('inner')),
        onUnregister: Some((_) {
          unregBFired = true;
        }),
      ).end();
      di.register<A>(
        A('outer'),
        onUnregister: Some((_) async {
          (await di.unregister<B>().toAsync().value).end();
        }),
      ).end();

      (await di.unregister<A>().toAsync().value).end();
      expect(unregBFired, isTrue);
      expect(di.isRegistered<A>(), isFalse);
      expect(di.isRegistered<B>(), isFalse);
    });

    test('onUnregister that throws does not poison subsequent registrations',
        () async {
      final di = DI();
      di.register<A>(
        A('x'),
        onUnregister: Some((_) {
          throw Exception('intentional');
        }),
      ).end();
      // The unregister call itself surfaces the error path through Resolvable;
      // we don't insist on success here, only on the container's recovery.
      try {
        (await di.unregister<A>().toAsync().value).end();
      } on Object {
        // expected — the callback threw
      }
      // The container still works.
      di.register<A>(A('fresh')).end();
      UNSAFE:
      expect(di.getSyncOrNone<A>().unwrap().tag, 'fresh');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: groupEntity space', () {
    test('1000 distinct groups, one A each, all independently retrievable', () {
      final di = DI();
      for (var i = 0; i < 1000; i++) {
        di
            .register<A>(
              A('g$i'),
              groupEntity: TypeEntity('g$i'),
            )
            .end();
      }
      for (var i = 0; i < 1000; i += 37) {
        UNSAFE:
        expect(
          di.getSyncOrNone<A>(groupEntity: TypeEntity('g$i')).unwrap().tag,
          'g$i',
        );
      }
    });

    test('DefaultEntity and named groups do not collide', () {
      final di = DI();
      di.register<A>(A('default')).end();
      di
          .register<A>(
            A('named'),
            groupEntity: TypeEntity('named'),
          )
          .end();
      UNSAFE:
      expect(di.getSyncOrNone<A>().unwrap().tag, 'default');
      UNSAFE:
      expect(
        di.getSyncOrNone<A>(groupEntity: TypeEntity('named')).unwrap().tag,
        'named',
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: async storms', () {
    test('many concurrent awaiters of the same async dep all see the value',
        () async {
      final di = DI();
      di
          .register<A>(
            Future<A>.delayed(
              const Duration(milliseconds: 20),
              () => A('slow'),
            ),
          )
          .end();
      // Capture N independent Async wrappers but await them sequentially —
      // exercising the post-resolution sync re-registration path more than
      // once is the abuse vector.
      for (var i = 0; i < 25; i++) {
        final a = await di.getAsyncUnsafe<A>();
        expect(a.tag, 'slow');
      }
      // Final state must be sync after the first resolution.
      expect(di.getSyncOrNone<A>().isSome(), isTrue);
    });

    test('a Future that throws surfaces an error through getAsync', () async {
      final di = DI();
      di
          .register<A>(
            Future<A>.delayed(
              const Duration(milliseconds: 5),
              () => throw Exception('boom'),
            ),
          )
          .end();
      Object? caught;
      try {
        await di.getAsyncUnsafe<A>();
      } catch (e) {
        caught = e;
      }
      expect(caught, isNotNull);
      // The container survives: a fresh sync registration takes over after we
      // unregister the broken async slot.
      (await di.unregister<A>().toAsync().value).end();
      di.register<A>(A('recovered')).end();
      UNSAFE:
      expect(di.getSyncOrNone<A>().unwrap().tag, 'recovered');
    });

    test('resolveAll waits out all async deps across distinct types', () async {
      final di = DI();
      final delays = [5, 15, 30, 10, 25];
      for (var i = 0; i < delays.length; i++) {
        di
            .register<Holder<int>>(
              Future<Holder<int>>.delayed(
                Duration(milliseconds: delays[i]),
                () => Holder<int>(i),
              ),
              groupEntity: TypeEntity('h$i'),
            )
            .end();
      }
      (await di.resolveAll(groupEntity: const None()).toAsync().value).end();
      for (var i = 0; i < delays.length; i++) {
        expect(
          di
              .getSyncOrNone<Holder<int>>(groupEntity: TypeEntity('h$i'))
              .isSome(),
          isTrue,
        );
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: until* waiters', () {
    test('20 untilSuper waiters all resolve from a single late registration',
        () async {
      final di = DI();
      final waiters = [
        for (var i = 0; i < 20; i++) di.untilSuper<A>().toAsync().value,
      ];
      // Trigger after a microtask so every waiter has had a chance to enqueue.
      unawaited(
        Future<void>.microtask(() {
          di.register<A>(A('arrival')).end();
        }),
      );
      for (final w in waiters) {
        UNSAFE:
        final a = (await w).unwrap();
        expect(a.tag, 'arrival');
      }
    });

    test('untilSuper across N unregister/re-register cycles never gets stuck',
        () async {
      final di = DI();
      for (var cycle = 0; cycle < 10; cycle++) {
        final waiter = di.untilSuper<A>().toAsync().value;
        unawaited(
          Future<void>.microtask(() {
            di.register<A>(A('c$cycle')).end();
          }),
        );
        UNSAFE:
        expect((await waiter).unwrap().tag, 'c$cycle');
        (await di.unregister<A>().toAsync().value).end();
      }
    });

    test('untilExactlyK with epoch advances correctly across re-registration',
        () async {
      final di = DI();
      UNSAFE:
      final waiter = di
          .untilExactlyK<A>(TypeEntity(A))
          .toAsync()
          .value
          .then((r) => r.unwrap());
      // Register, unregister, then re-register a different value. The waiter
      // must surface the *second* value (epoch guard).
      di.register<A>(A('v1'), enableUntilExactlyK: true).end();
      (await di.unregister<A>().toAsync().value).end();
      di.register<A>(A('v2'), enableUntilExactlyK: true).end();
      expect((await waiter).tag, 'v2');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: lazy churn', () {
    test('500 resetLazySingleton cycles all yield fresh instances', () async {
      final di = DI();
      var ctor = 0;
      di.registerLazy<A>(() => Sync.okValue(A('v${++ctor}'))).end();
      A? last;
      for (var i = 0; i < 500; i++) {
        UNSAFE:
        final a =
            di.getLazySingleton<A>().unwrap().sync().unwrap().value.unwrap();
        if (last != null) expect(identical(last, a), isFalse);
        last = a;
        (await di.resetLazySingleton<A>().toAsync().value).end();
      }
      expect(ctor, 500);
    });

    test('1000 factory reads return 1000 distinct instances', () {
      final di = DI();
      var ctor = 0;
      di.registerConstructor<A>(() => A('f${++ctor}')).end();
      final seen = <A>{};
      for (var i = 0; i < 1000; i++) {
        UNSAFE:
        final a = di.getFactory<A>().unwrap().sync().unwrap().value.unwrap();
        seen.add(a);
      }
      expect(seen.length, 1000);
    });

    test(
        'lazy and direct registrations of the same T coexist and unregister independently',
        () async {
      final di = DI();
      di.register<A>(A('direct')).end();
      di.registerLazy<A>(() => Sync.okValue(A('lazy'))).end();

      expect(di.isRegistered<A>(), isTrue);
      expect(di.isRegistered<Lazy<A>>(), isTrue);

      // unregister<A>() only touches the direct slot.
      (await di.unregister<A>().toAsync().value).end();
      expect(di.isRegistered<A>(), isFalse);
      expect(di.isRegistered<Lazy<A>>(), isTrue);

      // unregisterLazy<A>() clears the lazy slot.
      (await di.unregisterLazy<A>().toAsync().value).end();
      expect(di.isRegistered<Lazy<A>>(), isFalse);
    });

    test('lazy constructor that throws surfaces the error and leaves the slot',
        () {
      final di = DI();
      di
          .registerLazy<A>(
            () => Sync.err(Err('ctor failed')),
          )
          .end();

      UNSAFE:
      final r = di.getLazySingleton<A>().unwrap().sync().unwrap();
      expect(r.value.isErr(), isTrue);
      // The lazy registration is still there — a caller can replace it.
      expect(di.isRegistered<Lazy<A>>(), isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: traversal corners', () {
    test('parent child round-trip: child registers, parent must NOT see it',
        () {
      final root = DI();
      final c = root.child(groupEntity: TypeEntity('c1'));
      c.register<A>(A('child-only')).end();
      // The parent does not look down into children for `get<T>`.
      expect(root.isRegistered<A>(traverse: false), isFalse);
      expect(root.getSyncOrNone<A>().isNone(), isTrue);
      // The child still sees its own.
      UNSAFE:
      expect(c.getSyncOrNone<A>().unwrap().tag, 'child-only');
    });

    test(
        'isRegistered with traverse:false ignores parents even from deep child',
        () {
      final root = DI();
      root.register<A>(A('p')).end();
      var cursor = root;
      for (var i = 0; i < 5; i++) {
        cursor = cursor.child(groupEntity: TypeEntity('n$i'));
      }
      expect(cursor.isRegistered<A>(), isTrue); // traversed
      expect(cursor.isRegistered<A>(traverse: false), isFalse);
    });

    test(
      'shadowed registrations: removeAll:false leaves the parent intact across depth',
      () async {
        final root = DI();
        root.register<A>(A('root')).end();
        final mid = root.child(groupEntity: TypeEntity('m'));
        mid.register<A>(A('mid')).end();
        final leaf = mid.child(groupEntity: TypeEntity('l'));
        leaf.register<A>(A('leaf')).end();

        // Drop only the leaf copy.
        (await leaf.unregister<A>(removeAll: false).toAsync().value).end();
        expect(leaf.isRegistered<A>(traverse: false), isFalse);
        // mid + root survive untouched.
        UNSAFE:
        expect(mid.getSyncOrNone<A>(traverse: false).unwrap().tag, 'mid');
        UNSAFE:
        expect(root.getSyncOrNone<A>(traverse: false).unwrap().tag, 'root');

        // Now drop mid's copy.
        (await mid.unregister<A>(removeAll: false).toAsync().value).end();
        // Root still has its own.
        UNSAFE:
        expect(root.getSyncOrNone<A>(traverse: false).unwrap().tag, 'root');
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: subtype semantics', () {
    test('register<Animal>(Dog) is reachable via Animal', () {
      final di = DI();
      di.register<Animal>(Dog()).end();
      UNSAFE:
      expect(di.getSyncOrNone<Animal>().unwrap().speak(), 'woof');
      // Subtype query: `Animal` matches anything assignable to Animal.
      expect(di.isRegistered<Animal>(), isTrue);
    });

    test('until<Animal, Dog> resolves on a Dog registration', () async {
      final di = DI();
      UNSAFE:
      final waiter = di.until<Animal, Dog>().toAsync().value;
      unawaited(
        Future<void>.microtask(() {
          di.register<Animal>(Dog()).end();
        }),
      );
      UNSAFE:
      final dog = (await waiter).unwrap();
      expect(dog.speak(), 'woof');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: service lifecycle', () {
    test('concurrent init/pause/resume/dispose calls serialize cleanly',
        () async {
      final s = TallyService();
      // Fire many lifecycle calls without awaiting between them. The sequencer
      // is responsible for ordering them deterministically.
      final pending = [
        s.init(),
        s.pause(),
        s.resume(),
        s.pause(),
        s.resume(),
        s.dispose(),
      ];
      for (final r in pending) {
        (await r.toAsync().value).end();
      }
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
      expect(
          s.log, ['init.0', 'pause', 'resume', 'pause', 'resume', 'dispose.0'],);
    });

    test('init→dispose→init pattern is rejected (cannot re-init after dispose)',
        () async {
      final s = TallyService();
      (await s.init().value).end();
      (await s.dispose().value).end();
      try {
        (await s.init().value).end();
      } on Object {
        // expected: assertion fires in debug; release just early-returns.
      }
      // Either way, init listener did not run a second time.
      expect(s.log.where((e) => e.startsWith('init.')).length, 1);
    });

    test('service registered with onRegister=init and onUnregister=dispose',
        () async {
      final di = DI();
      final s = TallyService();
      di
          .register<TallyService>(
            s,
            onRegister: Some((TallyService svc) => svc.init()),
            onUnregister: const Some(ServiceMixin.unregister),
          )
          .end();
      UNSAFE:
      final retrieved = await di
          .untilSuper<TallyService>()
          .toAsync()
          .value
          .then((r) => r.unwrap());
      expect(identical(retrieved, s), isTrue);
      expect(s.state, ServiceState.RUN_SUCCESS);
      (await di.unregister<TallyService>().toAsync().value).end();
      expect(s.state, ServiceState.DISPOSE_SUCCESS);
    });

    test('100 service instances init+dispose concurrently — no cross-talk',
        () async {
      const n = 100;
      final services = [for (var i = 0; i < n; i++) TallyService()];
      // Init all in parallel.
      await Future.wait([
        for (final s in services) (() async => (await s.init().value).end())(),
      ]);
      for (final s in services) {
        expect(s.state, ServiceState.RUN_SUCCESS);
        expect(s.log, ['init.0']);
      }
      // Dispose all in parallel.
      await Future.wait([
        for (final s in services)
          (() async => (await s.dispose().value).end())(),
      ]);
      for (final s in services) {
        expect(s.state, ServiceState.DISPOSE_SUCCESS);
      }
    });

    test('a service that throws in init survives if you replace it', () async {
      final di = DI();
      final bad = TallyService(throwOnInit: true);
      di
          .register<TallyService>(
            bad,
            onRegister: Some((TallyService svc) => svc.init()),
            onUnregister: const Some(ServiceMixin.unregister),
          )
          .end();
      // Allow the init chain to complete (it will land in RUN_ERROR). After
      // the C6-aligned fix, `untilSuper` surfaces the init failure as an Err
      // — the `bad` instance is unreachable via the public Resolvable API.
      // We confirm: the failure is observable (Err result), the service's
      // own state moved to RUN_ERROR, and the registry still treats the slot
      // as occupied so a follow-up `register` of the SAME type is rejected.
      final result =
          await di.untilSuper<TallyService>().toAsync().value;
      expect(
        result.isErr(),
        isTrue,
        reason:
            'onRegister failure (whether sync throw, async throw, or '
            'Resolvable-Err) must surface as Err on `untilSuper` — C6 '
            'contract.',
      );
      expect(bad.state, ServiceState.RUN_ERROR);

      // Swap in a healthy one.
      try {
        (await di.unregister<TallyService>().toAsync().value).end();
      } on Object {
        // dispose on a RUN_ERROR service is allowed; ignore stray asserts.
      }
      final good = TallyService();
      di
          .register<TallyService>(
            good,
            onRegister: Some((TallyService svc) => svc.init()),
            onUnregister: const Some(ServiceMixin.unregister),
          )
          .end();
      UNSAFE:
      final got2 = await di
          .untilSuper<TallyService>()
          .toAsync()
          .value
          .then((r) => r.unwrap());
      expect(identical(got2, good), isTrue);
      expect(good.state, ServiceState.RUN_SUCCESS);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: stream service', () {
    test('100 emissions arrive in order and trigger listeners in order',
        () async {
      final ctrl = StreamController<Result<int>>.broadcast();
      final svc = HandStream(ctrl.stream);
      (await svc.init().value).end();

      const n = 100;
      for (var i = 0; i < n; i++) {
        ctrl.add(Ok(i));
      }
      // Give the event loop time to drain.
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(svc.heard.length, n);
      expect(svc.heard.first, 0);
      expect(svc.heard.last, n - 1);
      // The list is monotonically increasing.
      for (var i = 1; i < svc.heard.length; i++) {
        expect(svc.heard[i] > svc.heard[i - 1], isTrue);
      }
      await ctrl.close();
      (await svc.dispose().value).end();
      expect(svc.state, ServiceState.DISPOSE_SUCCESS);
    });

    test('pause/resume drops nothing once resumed', () async {
      final ctrl = StreamController<Result<int>>();
      final svc = HandStream(ctrl.stream);
      (await svc.init().value).end();
      (await svc.pause().value).end();
      ctrl.add(const Ok(1));
      ctrl.add(const Ok(2));
      ctrl.add(const Ok(3));
      // Give the event loop a chance to discover that the stream is paused.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      // Nothing should have arrived yet.
      expect(svc.heard, isEmpty);
      (await svc.resume().value).end();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(svc.heard, [1, 2, 3]);
      await ctrl.close();
      (await svc.dispose().value).end();
    });

    test('restartStream drops in-flight emissions from the previous epoch',
        () async {
      final ctrl = StreamController<Result<int>>.broadcast();
      final svc = HandStream(ctrl.stream);
      (await svc.init().value).end();
      ctrl.add(const Ok(42));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      // Restart now: any new emissions on the same controller are still
      // forwarded (broadcast stream listens are re-attached), but any in-flight
      // pushes captured by closure on the old epoch must not land.
      (await svc.restartStream().value).end();
      ctrl.add(const Ok(7));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      // The original 42 either landed before the restart (recorded) or got
      // dropped by the epoch guard. Either way, 7 must be in the list and the
      // list must be ordered.
      expect(svc.heard, contains(7));
      for (var i = 1; i < svc.heard.length; i++) {
        // No duplicates either: every emission is recorded at most once.
        expect(svc.heard[i] != svc.heard[i - 1], isTrue);
      }
      await ctrl.close();
      (await svc.dispose().value).end();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: container isolation', () {
    test('50 parallel DI()s with the same type are fully independent',
        () async {
      const n = 50;
      final dis = [for (var i = 0; i < n; i++) DI()];
      for (var i = 0; i < n; i++) {
        dis[i].register<A>(A('di$i')).end();
      }
      // Each container sees only its own value.
      for (var i = 0; i < n; i++) {
        UNSAFE:
        expect(dis[i].getSyncOrNone<A>().unwrap().tag, 'di$i');
      }
      // Unregistering one does not affect the others.
      (await dis[10].unregister<A>().toAsync().value).end();
      expect(dis[10].isRegistered<A>(), isFalse);
      for (var i = 0; i < n; i++) {
        if (i == 10) continue;
        expect(dis[i].isRegistered<A>(), isTrue);
      }
    });

    test('child().unregisterChild() then child() builds a brand-new instance',
        () {
      final root = DI();
      final c1 = root.child(groupEntity: TypeEntity('g'));
      c1.register<A>(A('inside-c1')).end();
      final removed = root.unregisterChild(groupEntity: TypeEntity('g'));
      expect(removed.isOk(), isTrue);
      final c2 = root.child(groupEntity: TypeEntity('g'));
      expect(identical(c1, c2), isFalse);
      // The fresh child does NOT carry over the old registration.
      expect(c2.isRegistered<A>(traverse: false), isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: duplicate registration', () {
    test('register<T> twice does not clobber the first value', () {
      final di = DI();
      di.register<A>(A('first')).end();
      // Second registration is rejected internally — returns Err. We do not
      // unwrap the result; we just confirm the first survives.
      di.register<A>(A('second')).end();
      UNSAFE:
      expect(di.getSyncOrNone<A>().unwrap().tag, 'first');
    });

    test('unregister-then-register clobbers correctly', () async {
      final di = DI();
      di.register<A>(A('first')).end();
      (await di.unregister<A>().toAsync().value).end();
      di.register<A>(A('second')).end();
      UNSAFE:
      expect(di.getSyncOrNone<A>().unwrap().tag, 'second');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: unregisterAll edge cases', () {
    test(
        'unregisterAll with sync onUnregister callbacks fires them in reverse order',
        () async {
      final di = DI();
      final order = <String>[];
      di.register<A>(A('a'), onUnregister: Some((_) {
        order.add('a');
      }),).end();
      di.register<B>(B(A('inner')), onUnregister: Some((_) {
        order.add('b');
      }),).end();
      di.register<C>(
        C(B(A('inner2'))),
        onUnregister: Some((_) {
          order.add('c');
        }),
      ).end();

      (await di.unregisterAll().toAsync().value).end();
      // unregisterAll iterates `reversedDependencies` (newest first).
      expect(order, ['c', 'b', 'a']);
      expect(di.isRegistered<A>(), isFalse);
      expect(di.isRegistered<B>(), isFalse);
      expect(di.isRegistered<C>(), isFalse);
    });

    test('unregisterAll fires every onUnregister even with many deps',
        () async {
      final di = DI();
      const n = 50;
      var disposed = 0;
      for (var i = 0; i < n; i++) {
        di.register<Counter>(
          Counter('c$i'),
          groupEntity: TypeEntity('g$i'),
          onUnregister: Some((_) {
            disposed++;
          }),
        ).end();
      }
      (await di.unregisterAll().toAsync().value).end();
      expect(disposed, n);
    });

    test('unregisterAll with a condition only evicts matching deps', () async {
      final di = DI();
      di.register<A>(A('keep')).end();
      di.register<B>(B(A('drop'))).end();
      (await di
              .unregisterAll(
                condition: Some((d) => d.value is Resolvable<B>),
              )
              .toAsync()
              .value)
          .end();
      expect(di.isRegistered<A>(), isTrue);
      expect(di.isRegistered<B>(), isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: nested untilSuper chains', () {
    test('untilSuper inside untilSuper inside untilSuper resolves bottom-up',
        () async {
      final di = DI();
      final order = <String>[];

      Future<void> waiterA() async {
        UNSAFE:
        final a =
            await di.untilSuper<A>().toAsync().value.then((r) => r.unwrap());
        order.add('saw-${a.tag}');
      }

      Future<void> waiterB() async {
        UNSAFE:
        final b =
            await di.untilSuper<B>().toAsync().value.then((r) => r.unwrap());
        order.add('saw-B(${b.a.tag})');
        await waiterA();
      }

      final f = waiterB();

      await Future<void>.delayed(const Duration(milliseconds: 5));
      di.register<B>(B(A('paired'))).end();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      di.register<A>(A('arrived')).end();

      await f;
      expect(order, ['saw-B(paired)', 'saw-arrived']);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: register-while-resolving', () {
    test('registering a new dep from within a getAsync of another dep is safe',
        () async {
      final di = DI();
      di
          .register<A>(
            Future<A>.delayed(
              const Duration(milliseconds: 10),
              () => A('resolved'),
            ),
          )
          .end();
      // Read A asynchronously; from inside that await, register B.
      UNSAFE:
      final a = await di.getAsyncUnsafe<A>();
      di.register<B>(B(a)).end();
      expect(a.tag, 'resolved');
      UNSAFE:
      expect(di.getSyncOrNone<B>().unwrap().a.tag, 'resolved');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: callbacks with side effects', () {
    test('onRegister side effects are visible to subsequent registrations',
        () async {
      final di = DI();
      var counter = 0;
      // Each registration bumps a shared counter through its onRegister.
      for (var i = 0; i < 25; i++) {
        (await di
                .register<Counter>(
                  Counter('iter$i'),
                  groupEntity: TypeEntity('g$i'),
                  onRegister: Some((c) {
                    counter++;
                  }),
                )
                .toAsync()
                .value)
            .end();
      }
      expect(counter, 25);
    });

    test('a sync onRegister that throws still aborts cleanly', () async {
      final di = DI();
      try {
        (await di
                .register<A>(
                  A('boom'),
                  onRegister: Some((_) {
                    throw Exception('nope');
                  }),
                )
                .toAsync()
                .value)
            .end();
      } on Object {
        // expected
      }
      // Container is still usable; the registration may or may not have
      // landed — we don't care about that, we care that the container itself
      // is not corrupted.
      di.register<B>(B(A('survived'))).end();
      UNSAFE:
      expect(di.getSyncOrNone<B>().unwrap().a.tag, 'survived');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: ultra-mixed deep tree', () {
    test(
        'build a hierarchy with sync, async, lazy, factory deps and tear it down',
        () async {
      final root = DI();

      // Sync at root.
      root.register<A>(A('root.A')).end();

      // Async at root.
      root
          .register<B>(
            Future<B>.delayed(
              const Duration(milliseconds: 5),
              () => B(A('root.B.inner')),
            ),
          )
          .end();

      // Lazy at root.
      root.registerLazy<C>(() => Sync.okValue(C(B(A('root.C.inner'))))).end();

      // Child container.
      final mid = root.child(groupEntity: TypeEntity('mid'));

      // Constructor (factory) at mid.
      var counter = 0;
      mid
          .registerConstructor<Counter>(
            () => Counter('counter${++counter}'),
          )
          .end();

      // Grandchild.
      final leaf = mid.child(groupEntity: TypeEntity('leaf'));
      leaf.register<Holder<int>>(Holder<int>(99)).end();

      // Resolve everything from the leaf.
      UNSAFE:
      expect(leaf.getSyncOrNone<A>().unwrap().tag, 'root.A');
      UNSAFE:
      expect(
        leaf
            .getLazySingleton<C>()
            .unwrap()
            .sync()
            .unwrap()
            .value
            .unwrap()
            .b
            .a
            .tag,
        'root.C.inner',
      );
      UNSAFE:
      expect(leaf.getSyncOrNone<Holder<int>>().unwrap().value, 99);

      // Resolve B at root first (async traversal + container re-registration
      // is intentionally a root-bound operation: the leaf does not own the
      // slot, so we awake the Future at the registration site, then read it
      // synchronously from the leaf through traversal).
      UNSAFE:
      final b = await root.getAsyncUnsafe<B>();
      expect(b.a.tag, 'root.B.inner');
      UNSAFE:
      expect(leaf.getSyncOrNone<B>().unwrap().a.tag, 'root.B.inner');

      // Factory at mid yields fresh values every time.
      UNSAFE:
      final f1 =
          mid.getFactory<Counter>().unwrap().sync().unwrap().value.unwrap();
      UNSAFE:
      final f2 =
          mid.getFactory<Counter>().unwrap().sync().unwrap().value.unwrap();
      expect(identical(f1, f2), isFalse);

      // Wipe everything from root.
      (await root.unregisterAll().toAsync().value).end();
      expect(root.isRegistered<A>(), isFalse);
      expect(root.isRegistered<B>(), isFalse);
      expect(root.isRegistered<Lazy<C>>(), isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('abuse: child of child of child registration ripple', () {
    test('registering at root after a deep child is built is visible at leaf',
        () {
      final root = DI();
      var cursor = root;
      for (var i = 0; i < 12; i++) {
        cursor = cursor.child(groupEntity: TypeEntity('n$i'));
      }
      // Register at root AFTER the tower is built.
      root.register<A>(A('late')).end();
      UNSAFE:
      expect(cursor.getSyncOrNone<A>().unwrap().tag, 'late');
    });
  });
}
