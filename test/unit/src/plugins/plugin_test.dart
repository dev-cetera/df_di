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

// Unit tests for `lib/src/plugins/plugin.dart`.
//
// Covers the `Plugin` abstract base + `PluginHostX` extension: installing a
// plugin creates a fresh child `DI` scope keyed by `plugin.id`; install /
// uninstall hooks fire in order; registrations made in `install` persist into
// the plugin's scope; `installPlugin` is idempotent; `uninstallPlugin` is a
// no-op for non-installed plugins; uninstall cascades `dispose()` on any
// `ServiceMixin` values registered in the scope; and distinct `id`s allow
// two instances of the same `Plugin` subclass to coexist.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

final class _Config {
  const _Config(this.value);
  final String value;
}

/// A bare-bones `ServiceMixin` value so we can verify the dispose cascade.
final class _BoundService extends Service {
  _BoundService(this.log);
  final List<String> log;

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) {
          log.add('svc.init');
          return syncUnit();
        },
      ];

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) => [];

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) => [];

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [
        (_) {
          log.add('svc.dispose');
          return syncUnit();
        },
      ];
}

/// A minimal fake plugin that records install/uninstall hook invocations and
/// registers a value + a service into the plugin scope.
final class _FakePlugin extends Plugin {
  const _FakePlugin(this.log, {this.value = 'fake'});
  final List<String> log;
  final String value;

  @override
  Resolvable<Unit> install(DI scope) {
    log.add('install');
    scope.register(_Config(value)).end();
    return scope.registerAndInitService(_BoundService(log));
  }

  @override
  Resolvable<Unit> uninstall(DI scope) {
    log.add('uninstall');
    return syncUnit();
  }
}

/// Two coexisting plugin instances of the same subclass, disambiguated by
/// overriding [id].
final class _NamedFakePlugin extends Plugin {
  const _NamedFakePlugin(this.name);
  final String name;

  @override
  Entity get id => TypeEntity(_NamedFakePlugin, [name]);

  @override
  Resolvable<Unit> install(DI scope) {
    scope.register(_Config(name)).end();
    return syncUnit();
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Awaits [r] and returns the unwrapped value or fails the test on Err.
Future<T> awaitOk<T extends Object>(Resolvable<T> r) async {
  final result = await r.value;
  return switch (result) {
    Ok(value: final v) => v,
    Err(:final error) => fail('Expected Ok, got Err: $error'),
  };
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('Plugin: construction & defaults', () {
    test('default id is TypeEntity(runtimeType)', () {
      final log = <String>[];
      final p = _FakePlugin(log);
      expect(p.id, TypeEntity(_FakePlugin));
    });

    test('installPlugin creates a child scope keyed by plugin.id', () async {
      final host = DI();
      final log = <String>[];
      final p = _FakePlugin(log);

      final scope = await awaitOk(host.installPlugin(p));
      expect(host.hasPlugin(p), isTrue);
      // Re-querying the child by the same entity returns the same scope.
      expect(identical(host.child(groupEntity: p.id), scope), isTrue);
    });
  });

  group('Plugin: install hook & scope registrations', () {
    test('install hook fires and registrations persist into the scope',
        () async {
      final host = DI();
      final log = <String>[];
      final p = _FakePlugin(log, value: 'alpha');

      final scope = await awaitOk(host.installPlugin(p));
      expect(log, ['install', 'svc.init']);
      expect(scope.getSyncUnsafe<_Config>().value, 'alpha');
    });

    test('installPlugin is idempotent (second call does not re-run install)',
        () async {
      final host = DI();
      final log = <String>[];
      final p = _FakePlugin(log);

      final a = await awaitOk(host.installPlugin(p));
      final b = await awaitOk(host.installPlugin(p));
      expect(identical(a, b), isTrue);
      // Install hook fires only once.
      expect(log.where((l) => l == 'install').length, 1);
      expect(log.where((l) => l == 'svc.init').length, 1);
    });

    test('two plugins sharing a class but distinct id coexist independently',
        () async {
      final host = DI();
      final a = const _NamedFakePlugin('alpha');
      final b = const _NamedFakePlugin('beta');

      final sa = await awaitOk(host.installPlugin(a));
      final sb = await awaitOk(host.installPlugin(b));

      expect(identical(sa, sb), isFalse);
      expect(host.hasPlugin(a), isTrue);
      expect(host.hasPlugin(b), isTrue);
      expect(sa.getSyncUnsafe<_Config>().value, 'alpha');
      expect(sb.getSyncUnsafe<_Config>().value, 'beta');
    });
  });

  group('Plugin: uninstall', () {
    test('uninstall fires the hook before tearing down the scope', () async {
      final host = DI();
      final log = <String>[];
      final p = _FakePlugin(log);

      await awaitOk(host.installPlugin(p));
      await awaitOk(host.uninstallPlugin(p));

      // uninstall hook fires BEFORE the unregister cascade that disposes
      // services held in the scope.
      expect(log, ['install', 'svc.init', 'uninstall', 'svc.dispose']);
      expect(host.hasPlugin(p), isFalse);
    });

    test('uninstall on a not-installed plugin is a no-op (Ok)', () async {
      final host = DI();
      final log = <String>[];
      final p = _FakePlugin(log);
      expect(host.hasPlugin(p), isFalse);
      await awaitOk(host.uninstallPlugin(p));
      expect(host.hasPlugin(p), isFalse);
    });

    test('uninstalling one plugin does not affect siblings', () async {
      final host = DI();
      final logA = <String>[];
      final a = _FakePlugin(logA, value: 'a');
      final b = const _NamedFakePlugin('b');

      await awaitOk(host.installPlugin(a));
      final scopeB = await awaitOk(host.installPlugin(b));

      await awaitOk(host.uninstallPlugin(a));

      expect(host.hasPlugin(a), isFalse);
      expect(host.hasPlugin(b), isTrue);
      expect(scopeB.getSyncUnsafe<_Config>().value, 'b');
    });

    test('re-install after uninstall produces a fresh scope', () async {
      final host = DI();
      final log = <String>[];
      final p = _FakePlugin(log);

      final s1 = await awaitOk(host.installPlugin(p));
      await awaitOk(host.uninstallPlugin(p));
      final s2 = await awaitOk(host.installPlugin(p));

      // After teardown, a new install creates a new scope (identity differs).
      expect(identical(s1, s2), isFalse);
      // install hook fired twice.
      expect(log.where((l) => l == 'install').length, 2);
      expect(log.where((l) => l == 'svc.init').length, 2);
    });
  });
}
