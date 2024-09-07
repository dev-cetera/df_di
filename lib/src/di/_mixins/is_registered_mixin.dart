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
    DIKey? typeGroup,
    bool getFromParents = true,
  }) {
    final dep = getDependencyOrNull1<T, P>(
      typeGroup: typeGroup,
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
    required DIKey typeGroup,
    bool getFromParents = true,
  }) {
    final dep = getDependencyUsingExactTypeOrNull1(
      type: type,
      paramsType: paramsType,
      typeGroup: typeGroup,
      getFromParents: getFromParents,
    );
    final registered = dep != null;
    return registered;
  }

  @override
  bool isRegisteredUsingRuntimeType({
    required Type type,
    Type paramsType = Object,
    required DIKey typeGroup,
    bool getFromParents = true,
  }) {
    return isRegisteredUsingExactType(
      type: DIKey(type),
      paramsType: DIKey(paramsType),
      typeGroup: typeGroup,
      getFromParents: getFromParents,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
abstract interface class IsRegisteredInterface {
  /// Checks if a dependency is registered under [T] and [typeGroup].
  bool isRegistered<T extends Object, P extends Object>({
    DIKey? typeGroup,
    bool getFromParents = true,
  });

  /// Checks if a dependency is registered under [type] and [typeGroup].

  bool isRegisteredUsingExactType({
    required DIKey type,
    DIKey? paramsType,
    required DIKey typeGroup,
    bool getFromParents = true,
  });

  bool isRegisteredUsingRuntimeType({
    required Type type,
    Type paramsType = Object,
    required DIKey typeGroup,
    bool getFromParents = true,
  });
}
