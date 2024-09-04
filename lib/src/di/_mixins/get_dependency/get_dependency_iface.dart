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
abstract interface class GetDependencyIface {
  @protected
  Dependency<Object> getDependency1<T extends Object>({
    Id? group,
  });

  @protected
  Dependency<Object> getDependencyUsingExactType1({
    required Id type,
    Id? paramsType,
    Id? group,
  });

  @protected
  Dependency<Object>? getDependencyOrNull1<T extends Object>({
    Id? group,
  });

  @protected
  Dependency<Object>? getDependencyUsingExactTypeOrNull1({
    required Id type,
    Id? paramsType,
    Id? group,
  });

  @protected
  Dependency<Object> getDependencyUsingRuntimeType1({
    required Type type,
    Id? paramsType,
    Id? group,
  });

  @protected
  Dependency<Object>? getDependencyUsingRuntimeTypeOrNull1({
    required Type type,
    Id? paramsType,
    Id? group,
  });
}
