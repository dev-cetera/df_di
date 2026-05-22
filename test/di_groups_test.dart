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

// Tests for `groupEntity` isolation: dependencies of the same type registered
// under different groups coexist; get / isRegistered / unregister all honour
// the group selector.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Test fixtures ───────────────────────────────────────────────────────────

final class Client {
  Client(this.name);
  final String name;
}

// Use TypeEntity as a lightweight named-group helper.
final _groupA = TypeEntity('groupA');
final _groupB = TypeEntity('groupB');

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('groupEntity isolation', () {
    test('same type can register under different groups', () {
      final di = DI();
      di.register<Client>(Client('a'), groupEntity: _groupA).end();
      di.register<Client>(Client('b'), groupEntity: _groupB).end();

      UNSAFE:
      expect(
        di.getSyncOrNone<Client>(groupEntity: _groupA).unwrap().name,
        'a',
      );
      UNSAFE:
      expect(
        di.getSyncOrNone<Client>(groupEntity: _groupB).unwrap().name,
        'b',
      );
    });

    test('isRegistered scoped to group', () {
      final di = DI();
      di.register<Client>(Client('a'), groupEntity: _groupA).end();

      expect(di.isRegistered<Client>(groupEntity: _groupA), isTrue);
      expect(di.isRegistered<Client>(groupEntity: _groupB), isFalse);
    });

    test('unregister scoped to group', () async {
      final di = DI();
      di.register<Client>(Client('a'), groupEntity: _groupA).end();
      di.register<Client>(Client('b'), groupEntity: _groupB).end();

      UNSAFE:
      (await di.unregister<Client>(groupEntity: _groupA).unwrap()).end();

      expect(di.isRegistered<Client>(groupEntity: _groupA), isFalse);
      expect(di.isRegistered<Client>(groupEntity: _groupB), isTrue);
    });

    test('lookup without group falls back to default, not other groups', () {
      final di = DI();
      di.register<Client>(Client('a'), groupEntity: _groupA).end();

      // No registration under default — even though one exists in _groupA.
      expect(di.getSyncOrNone<Client>().isNone(), isTrue);
    });
  });

  group('focusGroup', () {
    test('focusGroup is the implicit default when no group is passed', () {
      final di = DI()..focusGroup = _groupA;
      di.register<Client>(Client('focused')).end();

      // Without an explicit groupEntity, the focused group is consulted.
      UNSAFE:
      expect(di.getSyncOrNone<Client>().unwrap().name, 'focused');
      // Other groups don't see it.
      expect(di.isRegistered<Client>(groupEntity: _groupB), isFalse);
    });
  });
}
