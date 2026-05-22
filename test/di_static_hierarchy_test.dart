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

// Tests for the static `DI.root` / `DI.global` / `DI.session` / `DI.user` /
// `DI.theme` / `DI.dev` / `DI.prod` / `DI.test` accessors — these define a
// shared global container hierarchy that the rest of an app builds against.
// Each test cleans up its registration to avoid leaking state into others
// (the static accessors share one root instance).

import 'package:df_di/df_di.dart';
import 'package:test/test.dart' as t;

// ─── Fixtures ────────────────────────────────────────────────────────────────

final class StaticToken {
  StaticToken(this.value);
  final String value;
}

final class StaticConfig {
  StaticConfig(this.label);
  final String label;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  // Use prefixed `t.test` so the name doesn't shadow `DI.test`.

  t.tearDown(() async {
    // Best-effort cleanup so tests don't leak shared state into each other.
    for (final di in [
      DI.test,
      DI.user,
      DI.session,
      DI.global,
      DI.theme,
      DI.dev,
      DI.prod,
    ]) {
      UNSAFE:
      (await di.unregister<StaticToken>().toAsync().value).end();
      UNSAFE:
      (await di.unregister<StaticConfig>().toAsync().value).end();
    }
  });

  t.group('static DI accessors', () {
    t.test('DI.global is a child of DI.root', () {
      DI.global.register<StaticToken>(StaticToken('g')).end();
      // The child container traverses up to root by default — but the value
      // is in DI.global directly, so a `traverse:false` lookup also finds it.
      t.expect(
        DI.global.isRegistered<StaticToken>(traverse: false),
        t.isTrue,
      );
    });

    t.test('DI.session inherits from DI.global via traversal', () {
      DI.global.register<StaticConfig>(StaticConfig('shared')).end();

      // Child sees parent's value when traverse is the default (true).
      t.expect(DI.session.isRegistered<StaticConfig>(), t.isTrue);
      // Without traversal, the child container is empty.
      t.expect(
        DI.session.isRegistered<StaticConfig>(traverse: false),
        t.isFalse,
      );

      UNSAFE:
      t.expect(
        DI.session.getSyncOrNone<StaticConfig>().unwrap().label,
        'shared',
      );
    });

    t.test('DI.user inherits transitively from session and global', () {
      DI.global.register<StaticToken>(StaticToken('from-global')).end();

      UNSAFE:
      t.expect(
        DI.user.getSyncOrNone<StaticToken>().unwrap().value,
        'from-global',
      );
    });

    t.test('child registration in DI.session shadows DI.global', () {
      DI.global.register<StaticConfig>(StaticConfig('global')).end();
      DI.session.register<StaticConfig>(StaticConfig('session')).end();

      UNSAFE:
      t.expect(
        DI.session.getSyncOrNone<StaticConfig>().unwrap().label,
        'session',
      );
      // user still resolves through session (its parent).
      UNSAFE:
      t.expect(
        DI.user.getSyncOrNone<StaticConfig>().unwrap().label,
        'session',
      );
      // global keeps its own value.
      UNSAFE:
      t.expect(
        DI.global.getSyncOrNone<StaticConfig>().unwrap().label,
        'global',
      );
    });

    t.test('repeated access to a static accessor returns the same instance',
        () {
      t.expect(identical(DI.global, DI.global), t.isTrue);
      t.expect(identical(DI.session, DI.session), t.isTrue);
      t.expect(identical(DI.user, DI.user), t.isTrue);
    });

    t.test('different accessors of the same parent are distinct containers',
        () {
      // global / theme / dev / prod / test all hang off root in different
      // group entities — they must be different DI instances.
      t.expect(identical(DI.global, DI.theme), t.isFalse);
      t.expect(identical(DI.dev, DI.prod), t.isFalse);
    });
  });
}
