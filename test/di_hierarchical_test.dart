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

// Tests for hierarchical container resolution: parent traversal in get / probe
// methods, removeAll semantics, and isolation across independent DI trees.
// The parent/child wiring is exercised through the public `child()` API,
// which is the supported way to compose a DI hierarchy.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Test fixtures ───────────────────────────────────────────────────────────

final class Config {
  Config(this.value);
  final String value;
}

final class Token {
  Token(this.bytes);
  final String bytes;
}

final _groupA = TypeEntity('groupA');
final _groupB = TypeEntity('groupB');

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('parent traversal via child()', () {
    test('get<T> from child finds T in parent', () {
      final parent = DI();
      final child = parent.child(groupEntity: _groupA);
      parent.register<Config>(Config('parent-config')).end();

      UNSAFE:
      expect(child.getSyncOrNone<Config>().unwrap().value, 'parent-config');
    });

    test('isRegistered traverses parents by default', () {
      final parent = DI();
      final child = parent.child(groupEntity: _groupA);
      parent.register<Config>(Config('p')).end();

      expect(child.isRegistered<Config>(), isTrue);
      expect(child.isRegistered<Config>(traverse: false), isFalse);
    });

    test('child registration shadows parent', () {
      final parent = DI();
      final child = parent.child(groupEntity: _groupA);
      parent.register<Config>(Config('parent')).end();
      child.register<Config>(Config('child')).end();

      UNSAFE:
      expect(child.getSyncOrNone<Config>().unwrap().value, 'child');
      // Parent still has its own value.
      UNSAFE:
      expect(parent.getSyncOrNone<Config>().unwrap().value, 'parent');
    });

    test('traverse:false skips parent lookup', () {
      final parent = DI();
      final child = parent.child(groupEntity: _groupA);
      parent.register<Token>(Token('tok')).end();

      expect(child.getSyncOrNone<Token>(traverse: false).isNone(), isTrue);
      // Default traverse:true does find it.
      expect(child.getSyncOrNone<Token>().isSome(), isTrue);
    });
  });

  group('removeAll semantics', () {
    test('removeAll:true wipes child and all parents', () async {
      final parent = DI();
      final child = parent.child(groupEntity: _groupA);

      parent.register<Config>(Config('p')).end();
      child.register<Config>(Config('c')).end();

      UNSAFE:
      (await child.unregister<Config>().unwrap()).end();

      // Both registrations are gone.
      expect(child.isRegistered<Config>(traverse: false), isFalse);
      expect(parent.isRegistered<Config>(), isFalse);
    });

    test('removeAll:false stops after the first hit (child wins)', () async {
      final parent = DI();
      final child = parent.child(groupEntity: _groupA);

      parent.register<Config>(Config('p')).end();
      child.register<Config>(Config('c')).end();

      UNSAFE:
      (await child.unregister<Config>(removeAll: false).unwrap()).end();

      // The child copy is gone, the parent copy survives.
      expect(child.isRegistered<Config>(traverse: false), isFalse);
      expect(parent.isRegistered<Config>(), isTrue);
    });

    test('unregister returns the first removed value (not None)', () async {
      // Regression: the original `unregister` always returned `None` on
      // success, even when a value was removed.
      final di = DI();
      di.register<Config>(Config('payload')).end();

      UNSAFE:
      final removed = await di.unregister<Config>().unwrap();
      expect(removed.isSome(), isTrue);
      UNSAFE:
      expect(removed.unwrap().value, 'payload');
    });
  });

  group('multiple containers are isolated', () {
    test('two independent DIs do not share state', () {
      final a = DI();
      final b = DI();
      a.register<Config>(Config('a')).end();

      expect(a.isRegistered<Config>(), isTrue);
      expect(b.isRegistered<Config>(), isFalse);
    });
  });

  group('child() singleton semantics', () {
    test('repeated child() with the same group returns the same instance', () {
      final root = DI();
      final c1 = root.child(groupEntity: _groupA);
      final c2 = root.child(groupEntity: _groupA);
      expect(identical(c1, c2), isTrue);
    });

    test('different groups produce different child containers', () {
      final root = DI();
      final cA = root.child(groupEntity: _groupA);
      final cB = root.child(groupEntity: _groupB);
      expect(identical(cA, cB), isFalse);
    });
  });
}
