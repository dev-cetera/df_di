//.title
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
//.title~

import 'dart:math' show Random;

import 'entity.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Creates a new [UniqueEntity] with a unique ID.
///
/// ## Cross-isolate uniqueness
///
/// Static state (including the counter behind `UniqueEntity()`) is per-isolate
/// in Dart. A naive monotonic counter would mean two isolates each produce the
/// same id sequence (`-10001, -10002, …`), so a `UniqueEntity` sent across a
/// `SendPort` could silently collide with one generated locally.
///
/// To make `UniqueEntity` safe to send between isolates, each isolate carves
/// the negative-id space into fixed-size blocks and picks a random one at
/// first use:
///
/// ```
///   block_size  = 2^20  (~1M ids per block)
///   block_count = 2^30  (~1B possible blocks)
///   total range = 2^50  (well within dart2js's 53-bit safe-int range)
/// ```
///
/// Birthday-collision probability when `N` total blocks are picked across all
/// isolates is `≈ N² / 2^31` — for 1000 picks, ~0.05%; for typical use (a
/// handful of isolates each issuing far fewer than `2^20` ids), effectively
/// zero.
///
/// ## Within-isolate guarantees
///
/// Within a single isolate ids are strictly decreasing and unique. When an
/// isolate consumes a full `2^20` ids in one block, the next call re-seeds
/// from the random pool, **excluding every block already used by this
/// isolate**. So an isolate can never reissue an id it previously issued
/// (regardless of how many billions of `UniqueEntity()` calls it makes).
///
/// ## Failure modes
///
/// * `Random.secure()` is preferred for the seed, but if the platform does
///   not provide a cryptographic RNG the seed falls back to `Random()`.
///   Cross-isolate uniqueness then degrades to probabilistic uniqueness
///   based on the non-secure RNG's startup state — still suitable for
///   single-process use, weaker for adversarial inputs.
/// * On the highly improbable event that all `2^30` blocks have been
///   consumed by a single isolate (would require ~10^15 `UniqueEntity()`
///   calls), the re-seed loop would block forever. In practice this is
///   precluded by memory limits long before id exhaustion.
final class UniqueEntity extends Entity {
  static const _blockSize = 1 << 20;
  static const _blockCount = 1 << 30;

  /// Top of the current block (most-positive / first-issued id of the block).
  /// Lazily seeded on first `UniqueEntity()` call.
  static int _counter = 0;

  /// Inclusive floor of the current block (most-negative id of the block).
  /// When `_counter` would drop below this, the block is exhausted and a
  /// fresh block must be picked. Sentinel `0` until first seed (any id < 0
  /// triggers re-seed on first call).
  static int _floor = 0;

  /// Block indices already consumed by this isolate. Re-seed excludes these
  /// so an isolate never reissues an id it previously issued. Grows by one
  /// entry per re-seed, not per `UniqueEntity()` call — typical workloads
  /// never re-seed, so this set stays at size 0 forever.
  static final Set<int> _usedBlocks = <int>{};

  UniqueEntity() : super.reserved(_next());

  static int _next() {
    if (_counter <= _floor) _seedBlock();
    return _counter--;
  }

  static void _seedBlock() {
    final random = _safeRandom();
    int blockIndex;
    // Reject any block this isolate has already drawn. _blockCount is far
    // larger than any realistic re-seed count, so this loop is O(1) in
    // expectation and bounded by _blockCount in the worst case.
    do {
      blockIndex = random.nextInt(_blockCount);
    } while (!_usedBlocks.add(blockIndex));
    final top = -10001 - blockIndex * _blockSize;
    _counter = top;
    _floor = top - _blockSize + 1;
  }

  /// Prefers `Random.secure()`; falls back to `Random()` on platforms that
  /// lack a cryptographic RNG. The fallback weakens the random seed source
  /// but preserves the basic "different isolates pick different blocks with
  /// high probability" property because each isolate seeds its `Random()`
  /// independently using whatever entropy the platform provides at startup.
  static Random _safeRandom() {
    try {
      return Random.secure();
    } on UnsupportedError {
      return Random();
    }
  }
}
