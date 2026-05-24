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
// Audit pass 13: re-entrant update; advanced ECS state.

import 'package:df_di/df_di.dart';
import 'package:test/test.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // 1. World.update called recursively from inside a system's update —
  //    must not infinite-recurse / stack-overflow.
  // ─────────────────────────────────────────────────────────────────────────
  group('ECS: re-entrant update guard', () {
    test(
      'a system that calls world.update() from inside its own update '
      'does not stack-overflow',
      () {
        final w = World();
        var ticks = 0;
        w.addSystem(
          FunctionSystem((world, _) {
            ticks++;
            if (ticks < 5) {
              // Re-enter update. If unguarded → infinite recursion.
              world.update(Duration.zero);
            }
          }),
        );
        var didReturn = false;
        try {
          w.update(Duration.zero);
          didReturn = true;
        } on StackOverflowError {
          didReturn = false;
        }
        expect(
          didReturn,
          isTrue,
          reason: 'World.update from inside a system must terminate — either '
              'by detecting re-entry and skipping, or by treating it as a '
              'normal nested update sequence',
        );
        w.dispose();
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. World with an externally-supplied registry — using the SAME
  //    registry for two worlds should be possible but treated as
  //    "advanced usage". The worlds should at least not crash.
  // ─────────────────────────────────────────────────────────────────────────
  // (Skipped — DIRegistry isn't publicly constructible, so this scenario
  //  is naturally protected.)

  // ─────────────────────────────────────────────────────────────────────────
  // 3. World.dispose then world.update — already tested for "no-op". This
  //    pass: a long-running scenario verifies no GC pressure / stale-state.
  // ─────────────────────────────────────────────────────────────────────────
  group('ECS: post-dispose isolation', () {
    test(
      'a disposed world plus a fresh one: deps in the fresh world are not '
      'affected by the disposed one',
      () {
        final w1 = World();
        w1.spawn();
        w1.dispose();
        final w2 = World();
        final e = w2.spawn();
        expect(w2.entities.length, 1);
        expect(e.alive, isTrue);
        w2.dispose();
      },
    );
  });
}
