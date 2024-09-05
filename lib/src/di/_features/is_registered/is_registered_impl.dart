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
base mixin IsRegisteredImpl on DIBase implements IsRegisteredIface {
  @override
  bool isRegistered<T extends Object, P extends Object>({
    Gr? group,
    bool getFromParents = true,
  }) {
    final dep = getDependencyOrNull1<T, P>(
      group: group,
      getFromParents: getFromParents,
    );
    final registered = dep != null;
    return registered;
  }

  @protected
  @override
  bool isRegisteredUsingExactType({
    required Gr type,
    Gr? paramsType,
    required Gr group,
    bool getFromParents = true,
  }) {
    final dep = getDependencyUsingExactTypeOrNull1(
      type: type,
      paramsType: paramsType,
      group: group,
      getFromParents: getFromParents,
    );
    final registered = dep != null;
    return registered;
  }

  @override
  bool isRegisteredUsingRuntimeType({
    required Type type,
    Type paramsType = Object,
    required Gr group,
    bool getFromParents = true,
  }) {
    return isRegisteredUsingExactType(
      type: Gr(type),
      paramsType: Gr(paramsType),
      group: group,
      getFromParents: getFromParents,
    );
  }
}
