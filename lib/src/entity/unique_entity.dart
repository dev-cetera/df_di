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
import 'dart:typed_data' show Uint8List;

import 'package:df_log/df_log.dart' show Log;

import 'entity.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An [Entity] identified by a 128-bit RFC 4122 v4 [uuid]. Equality always
/// consults the UUID, so id collisions with other entities (32-bit hash
/// space) are harmless. Sendable across isolates: the UUID survives a
/// `SendPort` round trip and the receiving instance compares equal to the
/// original.
final class UniqueEntity extends Entity implements StrictEqualityEntity {
  final String uuid;

  UniqueEntity._(this.uuid) : super.reserved(_idFromUuid(uuid));

  factory UniqueEntity() => UniqueEntity._(_generateUuid());

  // The id is derived from the UUID's hashCode so HashMap performance is
  // preserved. Range sits below the reserved-entity range (-1001..-1008)
  // and within dart2js's 53-bit safe-integer floor.
  static int _idFromUuid(String uuid) {
    final h = uuid.hashCode;
    return -10001 - (h & 0x3fffffff);
  }

  static String _generateUuid() {
    final random = _safeRandom();
    final bytes = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      bytes[i] = random.nextInt(256);
    }
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UniqueEntity && uuid == other.uuid;
  }

  @override
  @pragma('vm:prefer-inline')
  int get hashCode => id;

  @override
  String toString() => 'UniqueEntity($uuid)';

  static bool _loggedFallback = false;

  static Random _safeRandom() {
    try {
      return Random.secure();
    } on UnsupportedError {
      if (!_loggedFallback) {
        _loggedFallback = true;
        Log.err(
          'UniqueEntity: Random.secure() is unsupported on this platform; '
          'falling back to Random(). UUIDs still carry 128 bits of '
          'platform entropy but are not cryptographic.',
        );
      }
      return Random();
    }
  }
}
