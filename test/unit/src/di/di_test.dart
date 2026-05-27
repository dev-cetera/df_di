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

// Tests for the `DI` facade itself: the `DI()` constructor, the static
// singletons `DI.root`/`DI.global`/`DI.session`/`DI.user`, and the convenience
// scopes `DI.theme`/`DI.dev`/`DI.prod`/`DI.test`. Verifies the parent/child
// wiring and the group-entity each scope carries.
//
// Tests intentionally use `UniqueEntity()` groups when registering into the
// shared `DI.root` graph so they cannot collide with each other or with
// production-defined keys.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Test fixtures ───────────────────────────────────────────────────────────

final class _Service {
  _Service(this.label);
  final String label;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('DI()', () {
    test('constructs a fresh DI instance', () {
      final di = DI();
      expect(di, isA<DI>());
    });

    test('two DI() instances are not identical', () {
      final a = DI();
      final b = DI();
      expect(identical(a, b), isFalse);
    });

    test('a fresh DI() has no parents and an empty registry', () {
      final di = DI();
      expect(di.parents, isEmpty);
      expect(di.registry.groupEntities, isEmpty);
    });

    test('a fresh DI() has focusGroup == DefaultEntity', () {
      final di = DI();
      expect(di.focusGroup, equals(const DefaultEntity()));
    });
  });

  group('DI.root', () {
    test('repeated access returns the same instance', () {
      final a = DI.root;
      final b = DI.root;
      expect(identical(a, b), isTrue);
    });

    test('DI.root is a DI', () {
      expect(DI.root, isA<DI>());
    });
  });

  group('DI.global', () {
    test('repeated access returns the same instance', () {
      final a = DI.global;
      final b = DI.global;
      expect(identical(a, b), isTrue);
    });

    test('is a child of DI.root', () {
      final g = DI.global;
      expect(g.parents.contains(DI.root), isTrue);
    });

    test('DI.root sees DI.global as its registered child', () {
      DI.global; // force registration
      expect(
        DI.root.isChildRegistered(groupEntity: const GlobalEntity()),
        isTrue,
      );
    });

    test('register/get round-trips work', () {
      // Use a UniqueEntity so we cannot collide with other tests on DI.global.
      final g = UniqueEntity();
      DI.global.register<_Service>(_Service('global'), groupEntity: g).end();
      expect(
        DI.global.isRegistered<_Service>(groupEntity: g, traverse: false),
        isTrue,
      );
      DI.global.unregister<_Service>(groupEntity: g, traverse: false).end();
      expect(
        DI.global.isRegistered<_Service>(groupEntity: g, traverse: false),
        isFalse,
      );
    });
  });

  group('DI.session', () {
    test('repeated access returns the same instance', () {
      expect(identical(DI.session, DI.session), isTrue);
    });

    test('is a child of DI.global', () {
      expect(DI.session.parents.contains(DI.global), isTrue);
    });

    test('DI.global sees DI.session as its registered child', () {
      DI.session; // force registration
      expect(
        DI.global.isChildRegistered(groupEntity: const SessionEntity()),
        isTrue,
      );
    });

    test('reaches up through DI.global to DI.root via traversal', () {
      final g = UniqueEntity();
      DI.root.register<_Service>(_Service('on-root'), groupEntity: g).end();
      // Traversal: session → global → root.
      expect(DI.session.isRegistered<_Service>(groupEntity: g), isTrue);
      DI.root.unregister<_Service>(groupEntity: g, traverse: false).end();
    });
  });

  group('DI.user', () {
    test('repeated access returns the same instance', () {
      expect(identical(DI.user, DI.user), isTrue);
    });

    test('is a child of DI.session', () {
      expect(DI.user.parents.contains(DI.session), isTrue);
    });

    test('DI.session sees DI.user as its registered child', () {
      DI.user; // force registration
      expect(
        DI.session.isChildRegistered(groupEntity: const UserEntity()),
        isTrue,
      );
    });

    test('reaches up the full chain (user → session → global → root)', () {
      final g = UniqueEntity();
      DI.root.register<_Service>(_Service('top'), groupEntity: g).end();
      expect(DI.user.isRegistered<_Service>(groupEntity: g), isTrue);
      DI.root.unregister<_Service>(groupEntity: g, traverse: false).end();
    });
  });

  group('DI.theme / DI.dev / DI.prod / DI.test', () {
    test('DI.theme is a child of DI.root', () {
      final t = DI.theme;
      expect(t.parents.contains(DI.root), isTrue);
      expect(
        DI.root.isChildRegistered(groupEntity: const ThemeEntity()),
        isTrue,
      );
    });

    test('DI.dev is a child of DI.root', () {
      final d = DI.dev;
      expect(d.parents.contains(DI.root), isTrue);
      expect(
        DI.root.isChildRegistered(groupEntity: const DevEntity()),
        isTrue,
      );
    });

    test('DI.prod is a child of DI.root', () {
      final p = DI.prod;
      expect(p.parents.contains(DI.root), isTrue);
      expect(
        DI.root.isChildRegistered(groupEntity: const ProdEntity()),
        isTrue,
      );
    });

    test('DI.test is a child of DI.root', () {
      final t = DI.test;
      expect(t.parents.contains(DI.root), isTrue);
      expect(
        DI.root.isChildRegistered(groupEntity: const TestEntity()),
        isTrue,
      );
    });

    test('DI.theme is idempotent', () {
      expect(identical(DI.theme, DI.theme), isTrue);
    });

    test('DI.dev is idempotent', () {
      expect(identical(DI.dev, DI.dev), isTrue);
    });

    test('DI.prod is idempotent', () {
      expect(identical(DI.prod, DI.prod), isTrue);
    });

    test('DI.test is idempotent', () {
      expect(identical(DI.test, DI.test), isTrue);
    });

    test('theme/dev/prod/test are all different DI instances', () {
      expect(identical(DI.theme, DI.dev), isFalse);
      expect(identical(DI.dev, DI.prod), isFalse);
      expect(identical(DI.prod, DI.test), isFalse);
      expect(identical(DI.theme, DI.prod), isFalse);
    });
  });

  group('Hierarchy traversal', () {
    test('user registration is NOT visible from root', () {
      final g = UniqueEntity();
      DI.user.register<_Service>(_Service('user-only'), groupEntity: g).end();
      // Root cannot see down into descendants.
      expect(
        DI.root.isRegistered<_Service>(groupEntity: g, traverse: false),
        isFalse,
      );
      // Cleanup on the leaf.
      DI.user.unregister<_Service>(groupEntity: g, traverse: false).end();
    });

    test('register/get round-trip on DI.dev does not affect DI.test', () {
      final g = UniqueEntity();
      DI.dev.register<_Service>(_Service('dev'), groupEntity: g).end();
      expect(
        DI.dev.isRegistered<_Service>(groupEntity: g, traverse: false),
        isTrue,
      );
      expect(
        DI.test.isRegistered<_Service>(groupEntity: g, traverse: false),
        isFalse,
      );
      DI.dev.unregister<_Service>(groupEntity: g, traverse: false).end();
    });
  });
}
