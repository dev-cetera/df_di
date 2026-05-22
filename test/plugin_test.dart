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

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

final class _ThemeColors {
  const _ThemeColors(this.primary);
  final String primary;
}

final class _ThemeTypography {
  const _ThemeTypography(this.fontFamily);
  final String fontFamily;
}

final class _ThemeAudio extends Service {
  _ThemeAudio(this.log);
  final List<String> log;

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) => [
        (_) {
          log.add('audio.init');
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
          log.add('audio.dispose');
          return syncUnit();
        },
      ];
}

final class _DarkThemePlugin extends Plugin {
  const _DarkThemePlugin(this.log);
  final List<String> log;

  @override
  Resolvable<Unit> install(DI scope) {
    log.add('install');
    scope.register(const _ThemeColors('#000000')).end();
    scope.register(const _ThemeTypography('Inter')).end();
    return scope.registerAndInitService(_ThemeAudio(log));
  }

  @override
  Resolvable<Unit> uninstall(DI scope) {
    log.add('uninstall');
    return syncUnit();
  }
}

final class _LightThemePlugin extends Plugin {
  const _LightThemePlugin();

  @override
  Resolvable<Unit> install(DI scope) {
    scope.register(const _ThemeColors('#FFFFFF')).end();
    return syncUnit();
  }
}

/// Two plugins of the same class — disambiguated via [id] override.
final class _NamedPlugin extends Plugin {
  const _NamedPlugin(this.name);
  final String name;

  @override
  Entity get id => TypeEntity(_NamedPlugin, [name]);

  @override
  Resolvable<Unit> install(DI scope) {
    scope.register(_ThemeColors(name)).end();
    return syncUnit();
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Awaits [resolvable] and returns the unwrapped value, failing the test if
/// the resolution settled as `Err`. Centralises the unsafe boundary so test
/// bodies stay declarative.
Future<T> awaitOk<T extends Object>(Resolvable<T> resolvable) async {
  final result = await resolvable.value;
  return switch (result) {
    Ok(value: final v) => v,
    Err(:final error) => fail('Expected Ok, got Err: $error'),
  };
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('Plugin: install', () {
    test(
      'install registers dependencies in the plugin scope',
      () async {
        final host = DI();
        final log = <String>[];
        final plugin = _DarkThemePlugin(log);

        final scope = await awaitOk(host.installPlugin(plugin));

        expect(host.hasPlugin(plugin), isTrue);
        expect(scope.getSyncUnsafe<_ThemeColors>().primary, '#000000');
        expect(scope.getSyncUnsafe<_ThemeTypography>().fontFamily, 'Inter');
        expect(log, ['install', 'audio.init']);
      },
    );

    test('install is idempotent — second call does not re-run install',
        () async {
      final host = DI();
      final log = <String>[];
      final plugin = _DarkThemePlugin(log);

      final s1 = await awaitOk(host.installPlugin(plugin));
      final s2 = await awaitOk(host.installPlugin(plugin));

      expect(identical(s1, s2), isTrue);
      expect(log, ['install', 'audio.init']); // not duplicated
    });

    test(
      'two plugins of the same subclass need distinct id to coexist',
      () async {
        final host = DI();
        final a = const _NamedPlugin('alpha');
        final b = const _NamedPlugin('beta');

        final sa = await awaitOk(host.installPlugin(a));
        final sb = await awaitOk(host.installPlugin(b));

        expect(identical(sa, sb), isFalse);
        expect(sa.getSyncUnsafe<_ThemeColors>().primary, 'alpha');
        expect(sb.getSyncUnsafe<_ThemeColors>().primary, 'beta');
        expect(host.hasPlugin(a), isTrue);
        expect(host.hasPlugin(b), isTrue);
      },
    );
  });

  group('Plugin: uninstall', () {
    test(
      'uninstall tears down the scope and cascades service dispose',
      () async {
        final host = DI();
        final log = <String>[];
        final plugin = _DarkThemePlugin(log);

        await awaitOk(host.installPlugin(plugin));
        expect(host.hasPlugin(plugin), isTrue);

        await awaitOk(host.uninstallPlugin(plugin));

        expect(host.hasPlugin(plugin), isFalse);
        // `uninstall` hook fires *before* the scope teardown, then services
        // get disposed via the unregister cascade.
        expect(log, ['install', 'audio.init', 'uninstall', 'audio.dispose']);
      },
    );

    test('uninstall on a not-installed plugin is a no-op', () async {
      final host = DI();
      final plugin = const _LightThemePlugin();

      expect(host.hasPlugin(plugin), isFalse);
      // Should resolve as Ok without throwing.
      await awaitOk(host.uninstallPlugin(plugin));
      expect(host.hasPlugin(plugin), isFalse);
    });

    test(
      'uninstalling one plugin does not affect siblings',
      () async {
        final host = DI();
        final logA = <String>[];
        final a = _DarkThemePlugin(logA);
        final b = const _LightThemePlugin();

        await awaitOk(host.installPlugin(a));
        final scopeB = await awaitOk(host.installPlugin(b));

        await awaitOk(host.uninstallPlugin(a));

        expect(host.hasPlugin(a), isFalse);
        expect(host.hasPlugin(b), isTrue);
        expect(scopeB.getSyncUnsafe<_ThemeColors>().primary, '#FFFFFF');
      },
    );
  });

  group('Plugin: theme swap', () {
    test(
      'swap = uninstall current + install new, with full teardown of old',
      () async {
        final host = DI();
        final darkLog = <String>[];
        final dark = _DarkThemePlugin(darkLog);
        final light = const _LightThemePlugin();

        // Start dark.
        final darkScope = await awaitOk(host.installPlugin(dark));
        expect(darkScope.getSyncUnsafe<_ThemeColors>().primary, '#000000');

        // Swap to light.
        await awaitOk(host.uninstallPlugin(dark));
        final lightScope = await awaitOk(host.installPlugin(light));

        expect(host.hasPlugin(dark), isFalse);
        expect(host.hasPlugin(light), isTrue);
        expect(lightScope.getSyncUnsafe<_ThemeColors>().primary, '#FFFFFF');
        expect(
          darkLog,
          ['install', 'audio.init', 'uninstall', 'audio.dispose'],
        );
      },
    );
  });
}
