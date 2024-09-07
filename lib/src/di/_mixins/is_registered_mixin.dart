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
base mixin IsRegisteredMixin on DIBase implements IsRegisteredInterface {
  @override
  bool isRegistered<T extends Object, P extends Object>({
    DIKey? groupKey,
    bool getFromParents = true,
  }) {
    final dep = getDependencyOrNull1<T, P>(
      groupKey: groupKey,
      getFromParents: getFromParents,
    );
    final registered = dep != null;
    return registered;
  }

  @protected
  @override
  bool isRegisteredUsingExactType({
    required DIKey type,
    DIKey? paramsType,
    required DIKey groupKey,
    bool getFromParents = true,
  }) {
    final dep = getDependencyUsingExactTypeOrNull1(
      type: type,
      paramsType: paramsType,
      groupKey: groupKey,
      getFromParents: getFromParents,
    );
    final registered = dep != null;
    return registered;
  }

  @override
  bool isRegisteredUsingRuntimeType({
    required Type type,
    Type paramsType = Object,
    required DIKey groupKey,
    bool getFromParents = true,
  }) {
    return isRegisteredUsingExactType(
      type: DIKey(type),
      paramsType: DIKey(paramsType),
      groupKey: groupKey,
      getFromParents: getFromParents,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
abstract interface class IsRegisteredInterface {
  /// Checks if a dependency is registered under [T] and [groupKey].
  bool isRegistered<T extends Object, P extends Object>({
    DIKey? groupKey,
    bool getFromParents = true,
  });

  /// Checks if a dependency is registered under [type] and [groupKey].

  bool isRegisteredUsingExactType({
    required DIKey type,
    DIKey? paramsType,
    required DIKey groupKey,
    bool getFromParents = true,
  });

  bool isRegisteredUsingRuntimeType({
    required Type type,
    Type paramsType = Object,
    required DIKey groupKey,
    bool getFromParents = true,
  });
}
