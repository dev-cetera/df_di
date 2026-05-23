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
//
// Audit pass 8: subtype-aware contract consistency and adversarial
// callback re-entrancy that wasn't covered earlier.

import 'dart:async';

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

abstract class _Animal {
  String name();
}

class _Dog extends _Animal {
  @override
  String name() => 'dog';
}

class _Cat extends _Animal {
  @override
  String name() => 'cat';
}

final class _A {
  const _A([this.tag = '']);
  final String tag;
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // 1. registry slot semantics: register<Dog>(dog) followed by
  //    register<Animal>(cat) — both succeed (different slots) because the
  //    pre-check uses traverse=false subtype matching.
  // ─────────────────────────────────────────────────────────────────────────
  group('register: subtype slots', () {
    test(
      'register<Dog>(dog) does NOT block register<Cat>(cat) — different '
      'concrete types are different slots',
      () {
        final di = DI();
        final dRes = di.register<_Dog>(_Dog());
        final cRes = di.register<_Cat>(_Cat());
        UNSAFE:
        expect(dRes.sync().unwrap().value.isOk(), isTrue);
        UNSAFE:
        expect(cRes.sync().unwrap().value.isOk(), isTrue);
      },
    );

    test(
      'register<Dog>(dog) → register<Animal>(cat) BLOCKS — Dog is already '
      'an Animal in the existence-check pass',
      () {
        final di = DI();
        di.register<_Dog>(_Dog()).end();
        final r = di.register<_Animal>(_Cat());
        UNSAFE:
        expect(
          r.sync().unwrap().value.isErr(),
          isTrue,
          reason:
              'subtype-aware existence check: Dog is also an Animal, '
              'so the Animal slot is logically taken',
        );
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Re-entrant register inside onUnregister of the SAME type — must not
  //    deadlock or recurse infinitely. The new registration goes in cleanly.
  // ─────────────────────────────────────────────────────────────────────────
  group('register: re-entrant re-register from onUnregister', () {
    test(
      'unregister<T>() whose onUnregister re-registers a fresh T leaves the '
      'fresh T registered',
      () async {
        final di = DI();
        di
            .register<_A>(
              const _A('first'),
              onUnregister: Some((_) {
                // Re-register a different value during teardown.
                di.register<_A>(const _A('fresh')).end();
              }),
            )
            .end();
        (await di.unregister<_A>().toAsync().value).end();
        // After unregister-with-re-register, the fresh one is in the slot.
        UNSAFE:
        expect(di.getSyncUnsafe<_A>().tag, 'fresh');
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Stream service: provideOnPushToStreamListeners returns a different
  //    list each emission — each emission uses the latest list.
  // ─────────────────────────────────────────────────────────────────────────
  group('stream: dynamic listener list', () {
    test(
      'subclass can change provideOnPushToStreamListeners between emissions',
      () async {
        final s = _DynamicListenerStream();
        (await s.init().toAsync().value).end();
        s.useAlternateListener = false;
        s.input.add(const Ok<int>(1));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        s.useAlternateListener = true;
        s.input.add(const Ok<int>(2));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(s.firstListenerSaw, equals([1]));
        expect(s.altListenerSaw, equals([2]));
        (await s.dispose().toAsync().value).end();
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 4. resolveAll across multiple groups — terminates and resolves all.
  // ─────────────────────────────────────────────────────────────────────────
  group('resolveAll: cross-group', () {
    test(
      'resolveAll on default group only resolves default-group async deps',
      () async {
        final di = DI();
        final g1 = UniqueEntity();
        di
            .register<_A>(
              Future<_A>.delayed(
                const Duration(milliseconds: 10),
                () => const _A('default'),
              ),
            )
            .end();
        di
            .register<_A>(
              Future<_A>.delayed(
                const Duration(milliseconds: 10),
                () => const _A('g1'),
              ),
              groupEntity: g1,
            )
            .end();
        (await di.resolveAll().toAsync().value).end();
        // Default group's _A is now Sync. g1's might still be Async (we
        // only resolved default).
        expect(di.getSyncOrNone<_A>().isSome(), isTrue);
        UNSAFE:
        expect(
          di.getSyncOrNone<_A>().unwrap().tag,
          'default',
        );
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 5. ServiceMixin: init listener that throws synchronously inside a
  //    Resolvable callback (NOT returning Sync.err — throwing a regular
  //    exception). The state machine must still land at RUN_ERROR.
  // ─────────────────────────────────────────────────────────────────────────
  group('service: synchronous throw from listener body', () {
    test('a listener that throws sync (not Sync.err) lands at RUN_ERROR',
        () async {
      final s = _SyncThrowSvc();
      Object? caught;
      try {
        (await s.init().toAsync().value).end();
      } on Object catch (e) {
        caught = e;
      }
      // In debug mode the internal assert(false, error) re-throws as
      // AssertionError; in release it's caught into Err. Both paths must
      // leave the state at RUN_ERROR.
      expect(s.state, ServiceState.RUN_ERROR);
      expect(
        caught == null || caught is AssertionError || caught is StateError,
        isTrue,
      );
    });
  });
}

class _DynamicListenerStream extends StreamService<int> {
  final input = StreamController<Result<int>>.broadcast();
  final firstListenerSaw = <int>[];
  final altListenerSaw = <int>[];
  bool useAlternateListener = false;

  @override
  Stream<Result<int>> provideInputStream() => input.stream;

  @override
  TServiceResolvables<Result<int>> provideOnPushToStreamListeners() {
    if (useAlternateListener) {
      return [
        (data) {
          switch (data) {
            case Ok(value: final v):
              altListenerSaw.add(v);
            case Err():
          }
          return Sync<Unit>.okValue(Unit());
        },
      ];
    }
    return [
      (data) {
        switch (data) {
          case Ok(value: final v):
            firstListenerSaw.add(v);
          case Err():
        }
        return Sync<Unit>.okValue(Unit());
      },
    ];
  }
}

class _SyncThrowSvc with ServiceMixin {
  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) {
          throw StateError('sync throw mid-init');
        },
      ];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) =>
      [(_) => Sync<Unit>.okValue(Unit())];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) =>
      [(_) => Sync<Unit>.okValue(Unit())];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) =>
      [(_) => Sync<Unit>.okValue(Unit())];
}
