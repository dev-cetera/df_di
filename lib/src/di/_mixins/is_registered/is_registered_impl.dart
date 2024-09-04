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
  bool isRegistered<T extends Object>({
    Gr? group,
  }) {
    final dep = getDependencyOrNull1<T>(
      group: group,
    );
    final registered = dep != null;
    return registered;
  }

  @override
  bool isRegisteredUsingExactType({
    required Gr type,
    Gr? paramsType,
    required Gr group,
  }) {
    final dep = getDependencyUsingExactTypeOrNull1(
      type: type,
      paramsType: paramsType,
      group: group,
    );
    final registered = dep != null;
    return registered;
  }

  @override
  bool isRegisteredAsRuntimeType({
    required Type type,
    Gr? paramsType,
    required Gr group,
  }) {
    return isRegisteredUsingExactType(
      type: TypeGr(type),
      paramsType: paramsType,
      group: group,
    );
  }
}
