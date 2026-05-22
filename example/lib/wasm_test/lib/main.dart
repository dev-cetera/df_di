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

// A focused Flutter Web harness that exercises the df_di `until*` family
// (every public member) on the dart2js and dart2wasm release pipelines.
//
// The dart2js release pipeline erases generic-parameter reification, which
// previously caused `_maybeFinish` to deliver a value to the wrong completer
// and hang `untilSuper<T>()` forever. The dart2wasm pipeline can reify
// differently again; this harness runs the same scenarios on whichever
// compiler the page was built with and prints PASS/FAIL on screen.
//
// Coverage (every public `until*` method in df_di):
//   • untilSuper<TSuper>()
//   • until<TSuper, TSub>()
//   • untilExactlyK<T>(Entity)
//   • untilExactlyT<T>(Type)
//   • untilLazySuper<TSuper>()
//   • untilLazy<TSuper, TSub>()                (safe with TSuper == TSub)
//   • untilLazySingletonSuper<TSuper>()
//   • untilLazySingleton<TSuper, TSub>()       (safe with TSuper == TSub)
//   • untilFactorySuper<TSuper>()
//   • untilFactory<TSuper, TSub>()             (safe with TSuper == TSub)
//   • untilFactoryExactlyK<T>(Entity)
//
// Plus minification-sensitive corners:
//   • immediate-resolution (already-registered) path
//   • async (Future) registration resolution
//   • subtype-covariant resolution (register<Cat> satisfies untilSuper<Animal>)
//   • groupEntity isolation
//   • strict-keying (lazy waiter ignores non-lazy register)
//
// Build & serve:
//   flutter build web --wasm   # dart2wasm release
//   flutter build web          # dart2js release
//   flutter run -d chrome      # debug — VM-like generics

import 'dart:async';
import 'dart:js_interop';

import 'package:df_di/df_di.dart';
import 'package:flutter/material.dart';

@JS('document')
external _JsDocument get _document;

extension type _JsDocument._(JSObject _) implements JSObject {
  external set title(String value);
  external _JsElement? getElementById(String id);
  external _JsElement createElement(String tag);
  external _JsElement get body;
}

extension type _JsElement._(JSObject _) implements JSObject {
  external set id(String value);
  external set textContent(String value);
  external set style(_JsCssStyle value);
  external _JsCssStyle get style;
  external void appendChild(_JsElement child);
}

extension type _JsCssStyle._(JSObject _) implements JSObject {
  external set display(String value);
}

void _publishResult(String value) {
  _document.title = value;
  var marker = _document.getElementById('__di_wasm_test_result__');
  if (marker == null) {
    marker = _document.createElement('div');
    marker.id = '__di_wasm_test_result__';
    marker.style.display = 'none';
    _document.body.appendChild(marker);
  }
  marker.textContent = value;
}

void main() {
  runApp(const _App());
}

// ─── App ─────────────────────────────────────────────────────────────────────

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'df_di wasm harness',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const _Harness(),
    );
  }
}

// ─── Test fixtures ───────────────────────────────────────────────────────────

abstract class _Animal {
  String name();
}

class _Cat extends _Animal {
  @override
  String name() => 'Cat';
}

class _Dog extends _Animal {
  @override
  String name() => 'Dog';
}

class _ServiceA {
  _ServiceA(this.tag);
  final String tag;
}

class _ServiceB {
  _ServiceB(this.tag);
  final String tag;
}

class _Config {
  _Config(this.value);
  final String value;
}

class _Repo {
  _Repo(this.tag);
  final String tag;
}

// ─── Harness ─────────────────────────────────────────────────────────────────

class _Harness extends StatefulWidget {
  const _Harness();

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final List<_Outcome> _results = [];
  bool _running = false;

  @override
  void initState() {
    super.initState();
    // Kick off the suite on first frame so the page can paint first.
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAll());
  }

  Future<void> _runAll() async {
    setState(() {
      _running = true;
      _results.clear();
    });

    // ── untilSuper ──────────────────────────────────────────────────────────

    await _run('untilSuper resolves when value is registered later', () async {
      final di = DI();
      final wait = di.untilSuper<_ServiceA>();
      unawaited(
        Future<void>.delayed(
          const Duration(milliseconds: 50),
          () => di.register<_ServiceA>(_ServiceA('A1')),
        ),
      );
      final v = await wait.toAsync().value.then((r) => r.unwrap());
      _expect(v.tag, 'A1');
    });

    await _run(
      'untilSuper resolves immediately when value is already registered',
      () async {
        final di = DI();
        di.register<_ServiceA>(_ServiceA('present')).end();
        final v = await di
            .untilSuper<_ServiceA>()
            .toAsync()
            .value
            .then((r) => r.unwrap());
        _expect(v.tag, 'present');
      },
    );

    await _run(
      'untilSuper does not cross-fire between unrelated types',
      () async {
        final di = DI();
        final waitA = di.untilSuper<_ServiceA>();
        final waitB = di.untilSuper<_ServiceB>();

        di.register<_ServiceA>(_ServiceA('only-A')).end();
        final a = await waitA.toAsync().value.then((r) => r.unwrap());
        _expect(a.tag, 'only-A');

        const pending = #pending;
        final bFuture = Future<Object>.value(waitB.toAsync().value);
        final raced = await Future.any<Object>([
          bFuture,
          Future<Object>.delayed(
            const Duration(milliseconds: 100),
            () => pending,
          ),
        ]);
        _expect(raced, pending);

        di.register<_ServiceB>(_ServiceB('B1')).end();
        final b = await waitB.toAsync().value.then((r) => r.unwrap());
        _expect(b.tag, 'B1');
      },
    );

    await _run('untilSuper resolves with a subtype', () async {
      final di = DI();
      final wait = di.untilSuper<_Animal>();
      unawaited(
        Future<void>.delayed(
          const Duration(milliseconds: 50),
          () => di.register<_Cat>(_Cat()),
        ),
      );
      final v = await wait.toAsync().value.then((r) => r.unwrap());
      _expect(v.name(), 'Cat');
    });

    await _run(
      'untilSuper<Animal> with register<Dog>(Dog()) resolves to a Dog (covariant)',
      () async {
        final di = DI();
        final wait = di.untilSuper<_Animal>();
        di.register<_Dog>(_Dog()).end();
        final v = await wait.toAsync().value.then((r) => r.unwrap());
        _expect(v.name(), 'Dog');
      },
    );

    await _run('untilSuper resolves an async (Future) registration', () async {
      final di = DI();
      final wait = di.untilSuper<_Config>();
      di
          .register<_Config>(
            Future<_Config>.delayed(
              const Duration(milliseconds: 40),
              () => _Config('async'),
            ),
          )
          .end();
      final v = await wait.toAsync().value.then((r) => r.unwrap());
      _expect(v.value, 'async');
    });

    await _run('untilSuper isolates across groupEntities', () async {
      final di = DI();
      final gA = TypeEntity('grpA');
      final gB = TypeEntity('grpB');
      final wA = di.untilSuper<_ServiceA>(groupEntity: gA);
      final wB = di.untilSuper<_ServiceA>(groupEntity: gB);
      di.register<_ServiceA>(_ServiceA('A-only'), groupEntity: gA).end();
      final a = await wA.toAsync().value.then((r) => r.unwrap());
      _expect(a.tag, 'A-only');

      // B-side must still be pending — race a 100ms sentinel.
      const pending = #pending;
      final raced = await Future.any<Object>([
        Future<Object>.value(wB.toAsync().value),
        Future<Object>.delayed(
          const Duration(milliseconds: 100),
          () => pending,
        ),
      ]);
      _expect(raced, pending);
    });

    // ── until<TSuper, TSub> ─────────────────────────────────────────────────

    await _run('until<TSuper, TSub> resolves on subtype registration',
        () async {
      final di = DI();
      final wait = di.until<_Animal, _Cat>();
      unawaited(
        Future<void>.delayed(
          const Duration(milliseconds: 50),
          () => di.register<_Cat>(_Cat()),
        ),
      );
      final v = await wait.toAsync().value.then((r) => r.unwrap());
      _expect(v.name(), 'Cat');
    });

    // ── untilExactlyK / untilExactlyT ───────────────────────────────────────

    await _run('untilExactlyK resolves on exact typeEntity match', () async {
      final di = DI();
      final entity = TypeEntity(_ServiceA);
      final wait = di.untilExactlyK<_ServiceA>(entity);
      unawaited(
        Future<void>.delayed(
          const Duration(milliseconds: 50),
          () => di
              .register<_ServiceA>(
                _ServiceA('exact'),
                enableUntilExactlyK: true,
              )
              .end(),
        ),
      );
      final v = await wait.toAsync().value.then((r) => r.unwrap());
      _expect(v.tag, 'exact');
    });

    await _run(
      'untilExactlyT(Type) is equivalent to untilExactlyK(TypeEntity(Type))',
      () async {
        final di = DI();
        final waitT = di.untilExactlyT<_ServiceA>(_ServiceA);
        final waitK = di.untilExactlyK<_ServiceA>(TypeEntity(_ServiceA));
        di
            .register<_ServiceA>(_ServiceA('TK'), enableUntilExactlyK: true)
            .end();
        final vT = await waitT.toAsync().value.then((r) => r.unwrap());
        final vK = await waitK.toAsync().value.then((r) => r.unwrap());
        _expect(vT.tag, 'TK');
        _expect(vK.tag, 'TK');
      },
    );

    await _run(
      'untilExactlyK epoch guard: re-register delivers fresh value',
      () async {
        final di = DI();
        final entity = TypeEntity(_ServiceA);

        final wait = di
            .untilExactlyK<_ServiceA>(entity)
            .toAsync()
            .value
            .then((r) => r.unwrap());

        di.register<_ServiceA>(_ServiceA('v1'), enableUntilExactlyK: true).end();
        await di.unregister<_ServiceA>().toAsync().value;
        di.register<_ServiceA>(_ServiceA('v2'), enableUntilExactlyK: true).end();

        final v = await wait;
        _expect(v.tag, 'v2');
      },
    );

    // ── untilLazySuper / untilLazy ──────────────────────────────────────────

    await _run('untilLazySuper resolves on a matching registerLazy', () async {
      final di = DI();
      final wait = di.untilLazySuper<_Repo>();
      unawaited(
        Future<void>.delayed(
          const Duration(milliseconds: 40),
          () => di.registerLazy<_Repo>(() => Sync.okValue(_Repo('L'))).end(),
        ),
      );
      final lazy = await wait.toAsync().value.then((r) => r.unwrap());
      final v = lazy.singleton.sync().unwrap().value.unwrap();
      _expect(v.tag, 'L');
    });

    await _run(
      'untilLazySuper ignores a non-lazy register (strict keying)',
      () async {
        final di = DI();
        final wait = di.untilLazySuper<_Repo>();
        di.register<_Repo>(_Repo('plain')).end();
        const pending = #pending;
        final raced = await Future.any<Object>([
          Future<Object>.value(wait.toAsync().value),
          Future<Object>.delayed(
            const Duration(milliseconds: 100),
            () => pending,
          ),
        ]);
        _expect(raced, pending);
      },
    );

    await _run('untilLazy<Repo, Repo> resolves on registerLazy<Repo>', () async {
      final di = DI();
      final wait = di.untilLazy<_Repo, _Repo>();
      di.registerLazy<_Repo>(() => Sync.okValue(_Repo('LL'))).end();
      final lazy = await wait.toAsync().value.then((r) => r.unwrap());
      final v = lazy.singleton.sync().unwrap().value.unwrap();
      _expect(v.tag, 'LL');
    });

    // ── untilLazySingletonSuper / untilLazySingleton ────────────────────────

    await _run(
      'untilLazySingletonSuper materializes the singleton',
      () async {
        final di = DI();
        var ctor = 0;
        final wait = di.untilLazySingletonSuper<_Repo>();
        unawaited(
          Future<void>.delayed(
            const Duration(milliseconds: 40),
            () => di
                .registerLazy<_Repo>(() {
                  ctor++;
                  return Sync.okValue(_Repo('LS'));
                })
                .end(),
          ),
        );
        final v = await wait.toAsync().value.then((r) => r.unwrap());
        _expect(v.tag, 'LS');
        _expect(ctor, 1);
      },
    );

    await _run(
      'untilLazySingleton<Repo, Repo> resolves on registerLazy<Repo>',
      () async {
        final di = DI();
        final wait = di.untilLazySingleton<_Repo, _Repo>();
        di.registerLazy<_Repo>(() => Sync.okValue(_Repo('LSS'))).end();
        final v = await wait.toAsync().value.then((r) => r.unwrap());
        _expect(v.tag, 'LSS');
      },
    );

    // ── untilFactorySuper / untilFactory ────────────────────────────────────

    await _run('untilFactorySuper mints fresh instances per wait', () async {
      final di = DI();
      var ctor = 0;
      di
          .registerConstructor<_Repo>(() => _Repo('F${++ctor}'))
          .end();
      final a = await di
          .untilFactorySuper<_Repo>()
          .toAsync()
          .value
          .then((r) => r.unwrap());
      final b = await di
          .untilFactorySuper<_Repo>()
          .toAsync()
          .value
          .then((r) => r.unwrap());
      _expect(a.tag, 'F1');
      _expect(b.tag, 'F2');
      _expect(identical(a, b), false);
    });

    await _run(
      'untilFactory<Repo, Repo> mints fresh instances per wait',
      () async {
        final di = DI();
        var ctor = 0;
        di
            .registerConstructor<_Repo>(() => _Repo('FF${++ctor}'))
            .end();
        final a = await di
            .untilFactory<_Repo, _Repo>()
            .toAsync()
            .value
            .then((r) => r.unwrap());
        final b = await di
            .untilFactory<_Repo, _Repo>()
            .toAsync()
            .value
            .then((r) => r.unwrap());
        _expect(a.tag, 'FF1');
        _expect(b.tag, 'FF2');
        _expect(identical(a, b), false);
      },
    );

    await _run(
      'untilFactorySuper ignores a non-lazy register (strict keying)',
      () async {
        final di = DI();
        final wait = di.untilFactorySuper<_Repo>();
        di.register<_Repo>(_Repo('plain')).end();
        const pending = #pending;
        final raced = await Future.any<Object>([
          Future<Object>.value(wait.toAsync().value),
          Future<Object>.delayed(
            const Duration(milliseconds: 100),
            () => pending,
          ),
        ]);
        _expect(raced, pending);
      },
    );

    // ── untilFactoryExactlyK / untilFactoryExactlyT ─────────────────────────

    await _run(
      'untilFactoryExactlyK takes the INNER typeEntity and matches a K register',
      () async {
        final di = DI();
        // Pass the INNER type entity (Repo). The method wraps it as
        // TypeEntity(Lazy, [Repo]) internally.
        final wait = di.untilFactoryExactlyK<_Repo>(TypeEntity(_Repo));
        unawaited(
          Future<void>.delayed(
            const Duration(milliseconds: 40),
            () => di
                .register<Lazy<_Repo>>(
                  Lazy<_Repo>(() => Sync.okValue(_Repo('strict'))),
                  enableUntilExactlyK: true,
                )
                .end(),
          ),
        );
        final v = await wait.toAsync().value.then((r) => r.unwrap());
        _expect(v.tag, 'strict');
      },
    );

    await _run(
      'untilFactoryExactlyT(Type) matches a K-flagged Lazy<T> registration',
      () async {
        final di = DI();
        final wait = di.untilFactoryExactlyT<_Repo>(_Repo);
        unawaited(
          Future<void>.delayed(
            const Duration(milliseconds: 40),
            () => di
                .register<Lazy<_Repo>>(
                  Lazy<_Repo>(() => Sync.okValue(_Repo('T-strict'))),
                  enableUntilExactlyK: true,
                )
                .end(),
          ),
        );
        final v = await wait.toAsync().value.then((r) => r.unwrap());
        _expect(v.tag, 'T-strict');
      },
    );

    await _run(
      'untilLazyExactlyT(Type) resolves with the Lazy<T> on K register',
      () async {
        final di = DI();
        final wait = di.untilLazyExactlyT<_Repo>(_Repo);
        unawaited(
          Future<void>.delayed(
            const Duration(milliseconds: 40),
            () => di
                .register<Lazy<_Repo>>(
                  Lazy<_Repo>(() => Sync.okValue(_Repo('lazyT'))),
                  enableUntilExactlyK: true,
                )
                .end(),
          ),
        );
        final lazy = await wait.toAsync().value.then((r) => r.unwrap());
        final v = lazy.singleton.sync().unwrap().value.unwrap();
        _expect(v.tag, 'lazyT');
      },
    );

    await _run(
      'untilLazySingletonyExactlyT(Type) materializes the singleton',
      () async {
        final di = DI();
        var ctor = 0;
        final wait = di.untilLazySingletonyExactlyT<_Repo>(_Repo);
        unawaited(
          Future<void>.delayed(
            const Duration(milliseconds: 40),
            () => di
                .register<Lazy<_Repo>>(
                  Lazy<_Repo>(() {
                    ctor++;
                    return Sync.okValue(_Repo('lazySingT'));
                  }),
                  enableUntilExactlyK: true,
                )
                .end(),
          ),
        );
        final v = await wait.toAsync().value.then((r) => r.unwrap());
        _expect(v.tag, 'lazySingT');
        _expect(ctor, 1);
      },
    );

    if (!mounted) return;
    setState(() => _running = false);
    final passed = _results.where((r) => r.pass).length;
    final total = _results.length;
    if (passed == total && total > 0) {
      _publishResult('__DI_WASM_TEST__:PASS:$total');
    } else {
      final failed = _results.where((r) => !r.pass).map((r) => r.name).join('|');
      _publishResult('__DI_WASM_TEST__:FAIL:$passed/$total:$failed');
    }
  }

  Future<void> _run(String name, FutureOr<void> Function() body) async {
    final stopwatch = Stopwatch()..start();
    Object? failure;
    StackTrace? trace;
    try {
      await body();
    } catch (e, st) {
      failure = e;
      trace = st;
    }
    stopwatch.stop();
    if (!mounted) return;
    setState(() {
      _results.add(_Outcome(
        name: name,
        pass: failure == null,
        durationMs: stopwatch.elapsedMilliseconds,
        error: failure?.toString(),
        trace: trace?.toString(),
      ));
    });
  }

  void _expect(Object actual, Object expected) {
    if (actual != expected) {
      throw 'Expected $expected, got $actual';
    }
  }

  @override
  Widget build(BuildContext context) {
    final passed = _results.where((r) => r.pass).length;
    final total = _results.length;
    final allDone = !_running;
    final allPass = allDone && passed == total && total > 0;
    final statusColor = !allDone
        ? Colors.amber
        : allPass
            ? Colors.green
            : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('df_di wasm harness'),
        backgroundColor: statusColor,
        actions: [
          IconButton(
            onPressed: _running ? null : _runAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _StatusBanner(
            running: _running,
            passed: passed,
            total: total,
            allPass: allPass,
          ),
          const SizedBox(height: 12),
          ..._results.map(_ResultTile.new),
        ],
      ),
    );
  }
}

// ─── UI bits ─────────────────────────────────────────────────────────────────

class _Outcome {
  _Outcome({
    required this.name,
    required this.pass,
    required this.durationMs,
    this.error,
    this.trace,
  });
  final String name;
  final bool pass;
  final int durationMs;
  final String? error;
  final String? trace;
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.running,
    required this.passed,
    required this.total,
    required this.allPass,
  });

  final bool running;
  final int passed;
  final int total;
  final bool allPass;

  @override
  Widget build(BuildContext context) {
    final color = running
        ? Colors.amber
        : allPass
            ? Colors.green
            : Colors.red;
    final label = running
        ? 'Running…  $passed / $total'
        : allPass
            ? 'PASS  ($passed / $total)'
            : 'FAIL  ($passed / $total)';
    return Container(
      key: const ValueKey('status-banner'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            running
                ? Icons.hourglass_bottom
                : allPass
                    ? Icons.check_circle
                    : Icons.error,
            color: color,
            size: 32,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile(this.outcome);
  final _Outcome outcome;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          outcome.pass ? Icons.check_circle : Icons.cancel,
          color: outcome.pass ? Colors.green : Colors.red,
        ),
        title: Text(outcome.name),
        subtitle: outcome.pass
            ? Text('OK in ${outcome.durationMs} ms')
            : Text(
                'FAIL in ${outcome.durationMs} ms\n${outcome.error}\n${outcome.trace ?? ''}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
        isThreeLine: !outcome.pass,
      ),
    );
  }
}
