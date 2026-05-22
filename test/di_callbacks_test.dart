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

// Tests for onRegister / onUnregister lifecycle callbacks and for the
// `triggerOnUnregisterCallbacks` switch.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Test fixtures ───────────────────────────────────────────────────────────

final class Disposable {
  Disposable(this.tag);
  final String tag;
  bool disposed = false;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('onRegister callback', () {
    test('fires synchronously during register', () async {
      final di = DI();
      String? observed;
      (await di
              .register<Disposable>(
                Disposable('hello'),
                onRegister: Some((d) => observed = d.tag),
              )
              .toAsync()
              .value)
          .end();
      expect(observed, 'hello');
    });

    test('async onRegister is awaited', () async {
      final di = DI();
      var ran = false;
      (await di
              .register<Disposable>(
                Disposable('x'),
                onRegister: Some((_) async {
                  await Future<void>.delayed(const Duration(milliseconds: 10));
                  ran = true;
                }),
              )
              .toAsync()
              .value)
          .end();
      expect(ran, isTrue);
    });
  });

  group('onUnregister callback', () {
    test('fires when unregistered, with Ok(value)', () async {
      final di = DI();
      Disposable? seen;
      di
          .register<Disposable>(
            Disposable('bye'),
            onUnregister: Some((result) {
              UNSAFE:
              if (result.isOk()) seen = result.unwrap();
            }),
          )
          .end();

      UNSAFE:
      (await di.unregister<Disposable>().unwrap()).end();
      expect(seen, isNotNull);
      expect(seen!.tag, 'bye');
    });

    test('triggerOnUnregisterCallbacks:false suppresses the callback', () async {
      final di = DI();
      var fired = false;
      di
          .register<Disposable>(
            Disposable('silent'),
            onUnregister: Some((_) => fired = true),
          )
          .end();

      UNSAFE:
      (await di
              .unregister<Disposable>(triggerOnUnregisterCallbacks: false)
              .unwrap())
          .end();
      expect(fired, isFalse);
      // The dependency is still removed.
      expect(di.isRegistered<Disposable>(), isFalse);
    });

    test('async onUnregister is awaited before returning', () async {
      final di = DI();
      var completed = false;
      di
          .register<Disposable>(
            Disposable('a'),
            onUnregister: Some((_) async {
              await Future<void>.delayed(const Duration(milliseconds: 10));
              completed = true;
            }),
          )
          .end();

      (await di.unregister<Disposable>().toAsync().value).end();
      expect(completed, isTrue);
    });
  });
}
