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

import 'dart:async';

import 'package:df_type/df_type.dart';
import 'package:meta/meta.dart';

import '../_index.g.dart';
import '/src/_index.g.dart';
import '../../_di_base.dart';
import '../../../_dependency.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
base mixin UnregisterImpl on DIBase implements UnregisterIface {
  @override
  FutureOr<void> unregisterAll({
    void Function(Dependency<Object> dependency)? onUnregister,
  }) {
    final foc = FutureOrController<void>();
    final dependencies =
        registry.state.values.fold(<Dependency<Object>>[], (buffer, e) => buffer..addAll(e.values));
    dependencies.sort((a, b) => b.registrationIndex.compareTo(a.registrationIndex));
    for (final dep in dependencies) {
      final a = dep.onUnregister;
      final b = onUnregister;
      foc.addAll([
        if (a != null) (_) => a(dep.value),
        if (b != null) (_) => b(dep),
      ]);
    }
    foc.add((_) => registry.clearRegistry());
    return foc.complete();
  }

  @override
  FutureOr<void> unregister<T extends Object>({
    Id? group,
  }) {
    return unregisterUsingExactType(
      type: TypeId(T),
      paramsType: TypeId(Object),
      group: group,
    );
  }

  @override
  FutureOr<void> unregisterUsingExactType({
    required Id type,
    required Id paramsType,
    Id? group,
  }) {
    final dep = removeDependencyUsingExactType(
      type: type,
      paramsType: paramsType,
      group: group,
    );
    return dep.onUnregister?.call(dep.value);
  }

  @override
  FutureOr<void> unregisterUsingRuntimeType({
    required Type type,
    required Id paramsType,
    Id? group,
  }) {
    return unregisterUsingExactType(
      type: TypeId(type),
      paramsType: paramsType,
      group: group,
    );
  }
}
