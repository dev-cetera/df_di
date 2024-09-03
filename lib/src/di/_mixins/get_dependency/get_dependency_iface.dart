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

import '/src/_index.g.dart';
import '../../../_dependency.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
abstract interface class GetDependencyIface {
  @protected
  Dependency<Object> getDependency<T extends Object>({
    Id? group,
  });

  @protected
  Dependency<Object> getDependencyUsingExactType({
    required Id type,
    required Id paramsType,
    required Id group,
  });

  @protected
  Dependency<Object>? getDependencyOrNull<T extends Object>({
    Id? group,
  });

  @protected
  Dependency<Object>? getDependencyUsingExactTypeOrNull({
    required Id type,
    required Id paramsType,
    Id? group,
  });

  @protected
  Dependency<Object> getDependencyUsingRuntimeType({
    required Type type,
    required Id paramsType,
    required Id group,
  });

  @protected
  Dependency<Object>? getDependencyUsingRuntimeTypeOrNull({
    required Type type,
    required Id paramsType,
    Id? group,
  });
}
