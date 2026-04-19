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

// Regression tests for the `until` / `untilSuper` completer-routing bug that
// silently hung on dart2js release mode. The bug: `_maybeFinish` iterated
// completers matched by `.whereType<ReservedSafeCompleter<T>>()` and relied
// on a `value as FutureOr<T>` cast to reject the wrong types (caught by
// try/catch). Both of those generic-reification checks are weakened in
// dart2js release — a completer of the *wrong* type could be matched and
// "completed" with a garbage value, with `break` exiting the loop before the
// correct completer was reached.
//
// These tests cover the VM (debug + release) — they pass on current logic
// already because VM keeps generic type info. The real value is as a
// contract test that pins the behaviour: whatever implementation of
// `_maybeFinish` runs, registering service X must only complete the
// `untilSuper<X>` waiter, never a waiter for an unrelated type.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Test fixtures ───────────────────────────────────────────────────────────

final class UserService {
  UserService(this.id);
  final int id;
}

final class AuthService {
  AuthService(this.token);
  final String token;
}

// Subtype chain for the "super/sub" coverage.
abstract class Animal {
  String name();
}

final class Cat extends Animal {
  @override
  String name() => 'Cat';
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('untilSuper', () {
    test(
      'registering ServiceA does not complete an untilSuper<ServiceB> waiter',
      () async {
        final di = DI();
        // Two waiters in the same group, registered in an order that used to
        // let the wrong one win. On the buggy code, registering AuthService
        // resolves the UserService waiter with an AuthService value, and the
        // AuthService waiter hangs.
        final userWait = di.untilSuper<UserService>();
        final authWait = di.untilSuper<AuthService>();

        final auth = AuthService('token-123');
        di.register<AuthService>(auth);

        // Auth waiter should resolve to the registered auth instance.
        final resolvedAuth = await authWait.unwrap();
        expect(resolvedAuth, same(auth));

        // User waiter should still be pending, not resolved with the auth
        // instance. Use a short timeout to assert it does NOT resolve yet.
        final userFuture = Future<Object>.value(userWait.unwrap());
        final raced = await Future.any<Object>([
          userFuture,
          Future.delayed(const Duration(milliseconds: 200), () => #pending),
        ]);
        expect(raced, equals(#pending));

        // And registering the user service now resolves the user waiter
        // with the correct value.
        final user = UserService(42);
        di.register<UserService>(user);
        final resolvedUser = await userWait.unwrap();
        expect(resolvedUser, same(user));
      },
    );

    test(
      'registering an already-waited service resolves its completer only once',
      () async {
        final di = DI();
        final wait1 = di.untilSuper<UserService>();
        final wait2 = di.untilSuper<UserService>();

        final user = UserService(7);
        di.register<UserService>(user);

        expect(await wait1.unwrap(), same(user));
        expect(await wait2.unwrap(), same(user));
      },
    );

    test(
      'registering a subtype satisfies an untilSuper<Supertype> waiter',
      () async {
        final di = DI();
        final animalWait = di.untilSuper<Animal>();

        final cat = Cat();
        // Dependencies must be registered under their declared T — here the
        // caller registers under Cat (subtype). untilSuper<Animal> should
        // complete if the registered value is assignable to Animal.
        di.register<Cat>(cat);

        final resolved = await animalWait.unwrap();
        expect(resolved, same(cat));
        expect(resolved.name(), equals('Cat'));
      },
    );

    test(
      'multiple waiters in different type families all resolve correctly',
      () async {
        final di = DI();

        final userWait = di.untilSuper<UserService>();
        final authWait = di.untilSuper<AuthService>();
        final animalWait = di.untilSuper<Animal>();

        // Register out-of-order to stress the matching logic.
        di.register<AuthService>(AuthService('t'));
        di.register<Cat>(Cat());
        di.register<UserService>(UserService(1));

        final a = await authWait.unwrap();
        final an = await animalWait.unwrap();
        final u = await userWait.unwrap();

        expect(a, isA<AuthService>());
        expect(an, isA<Animal>());
        expect(an, isA<Cat>());
        expect(u, isA<UserService>());
        expect(u.id, equals(1));
      },
    );
  });
}
