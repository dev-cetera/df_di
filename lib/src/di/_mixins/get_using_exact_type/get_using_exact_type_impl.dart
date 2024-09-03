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

// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:df_type/df_type.dart';
import 'package:meta/meta.dart';

import '../_index.g.dart';
import '/src/_index.g.dart';
import '../../_di_base.dart';
import '../../../_dependency.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
base mixin GetUsingExactTypeImpl on DIBase implements GetUsingExactTypeIface {
  @override
  FutureOr<Object> getUsingExactType({
    required Id type,
    Id? group,
  }) {
    final dep = _get(type: type, group: group);
    return dep.thenOr((dep) {
      if (dep.condition?.call(this) ?? true) {
        return dep.value;
      } else {
        // TODO: Need a specific error.
        throw Error();
      }
    });
  }

  @override
  FutureOr<Object> getUsingRuntimeType(
    Type type, {
    Id? group,
  }) {
    return getUsingExactType(
      type: TypeId(type),
      group: group,
    );
  }

  @protected
  FutureOr<Dependency<Object>> _get({
    required Id type,
    Id? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final result = getFirstNonNull(
      child: this,
      parent: parent,
      test: (di) => _getInternal(
        di: di,
        type: type,
        group: focusGroup,
      ),
    );
    if (result == null) {
      throw DependencyNotFoundException(
        type: type,
        group: focusGroup,
      );
    }
    return result;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

FutureOr<Dependency<Object>>? _getInternal({
  required DI di,
  required Id type,
  required Id group,
}) {
  // Sync types.
  {
    final dep = di.registry.getDependencyUsingExactTypeOrNull(
      type: type,
      group: group,
    );
    if (dep != null) {
      return dep;
    }
  }
  // Future types.
  {
    final genericType = GenericTypeId<FutureInst>([type, TypeId(Object)]);
    final res = _inst(
      di: di,
      type: type,
      genericType: genericType,
      group: group,
    );
    if (res != null) {
      return res;
    }
  }
  // Singleton types.
  {
    final genericType = GenericTypeId<SingletonInst>([type, TypeId(Object)]);
    final res = _inst(
      di: di,
      type: type,
      genericType: genericType,
      group: group,
    );
    if (res != null) {
      return res;
    }
  }
  return null;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

FutureOr<Dependency<Object>>? _inst({
  required DI di,
  required Id type,
  required Id genericType,
  required Id group,
}) {
  final dep = di.registry.getDependencyUsingExactTypeOrNull(
    type: genericType,
    group: group,
  );
  if (dep != null) {
    final value = dep.value;
    return value.thenOr((value) {
      return (value as Inst).constructor(-1);
    }).thenOr((newValue) {
      return di.registerDependencyUsingExactType(
        type: type,
        dependency: dep.reassign(newValue),
        suppressDependencyAlreadyRegisteredException: true,
      );
    }).thenOr((_) {
      return di.registry.removeDependencyUsingExactType(
        type: genericType,
        group: group,
      );
    }).thenOr((_) {
      return di._get(
        type: type,
        group: group,
      );
    });
  }
  return null;
}
