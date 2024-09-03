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

import 'package:meta/meta.dart';

import '../_index.g.dart';
import '/src/_index.g.dart';
import '../../_di_base.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
base mixin IsRegisteredImpl on DIBase implements IsRegisteredIface {
  @override
  bool isRegistered<T extends Object>({
    Descriptor? group,
  }) {
    final dep = getDependencyOrNull<T>(
      group: group,
    );
    final registered = dep != null;
    return registered;
  }

  @override
  bool isRegisteredUsingExactType({
    required Descriptor type,
    required Descriptor paramsType,
    required Descriptor group,
  }) {
    final dep = getDependencyUsingExactTypeOrNull(
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
    required Descriptor paramsType,
    required Descriptor group,
  }) {
    return isRegisteredUsingExactType(
      type: Descriptor.type(type),
      paramsType: paramsType,
      group: group,
    );
  }
}
