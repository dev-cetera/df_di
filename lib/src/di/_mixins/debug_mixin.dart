//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/src/_internal.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
base mixin DebugMixin on DIBase implements DebugInterface {
  @visibleForTesting
  @override
  @pragma('vm:prefer-inline')
  Type initialType<T extends Object, P extends Object>({
    DIKey? groupKey,
  }) {
    return getDependency1<T, P>(groupKey: groupKey, getFromParents: true).metadata!.initialType;
  }

  @visibleForTesting
  @override
  @pragma('vm:prefer-inline')
  int index<T extends Object, P extends Object>({
    DIKey? groupKey,
  }) {
    return getDependency1<T, P>(groupKey: groupKey, getFromParents: true).metadata!.index!;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
abstract interface class DebugInterface {
  /// Useful for debugging.
  Type initialType<T extends Object, P extends Object>({
    DIKey? groupKey,
  });

  /// Useful for debugging.
  int index<T extends Object, P extends Object>({
    DIKey? groupKey,
  });
}
