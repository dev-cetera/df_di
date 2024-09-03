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

import 'package:meta/meta.dart';

import '../_index.g.dart';
import '/src/_index.g.dart';
import '../../_di_base.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
base mixin GetFactoryImpl on DIBase implements GetFactoryIface {
  @override
  FutureOr<T> getFactory<T extends Object, P extends Object>(
    P params, {
    Id? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final result = getFactoryOrNull<T, P>(params, group: focusGroup);
    if (result == null) {
      throw DependencyNotFoundException(
        type: T,
        group: focusGroup,
      );
    }
    return result;
  }

  @override
  FutureOr<T>? getFactoryOrNull<T extends Object, P extends Object>(
    P params, {
    Id? group,
  }) {
    return getFirstNonNull(
      child: this,
      parent: parent,
      test: (di) => _getFactoryOrNull<T, P>(
        di: di,
        params: params,
        group: group,
      ),
    );
  }

  @override
  FutureOr<Object> getFactoryUsingExactType({
    required Id type,
    required Object params,
    Id? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final result = getFactoryUsingExactTypeOrNull(
      type: type,
      params: params,
      group: focusGroup,
    );
    if (result == null) {
      throw DependencyNotFoundException(
        type: Object,
        group: focusGroup,
      );
    }
    return result;
  }

  @override
  @pragma('vm:prefer-inline')
  FutureOr<Object> getFactoryUsingRuntimeType({
    required Type type,
    required Object params,
    Id? group,
  }) {
    return getFactoryUsingExactType(
      type: TypeId(type),
      params: params,
    );
  }

  @override
  FutureOr<Object>? getFactoryUsingExactTypeOrNull({
    required Id type,
    required Object params,
    Id? group,
  }) {
    return getFirstNonNull(
      child: this,
      parent: parent,
      test: (di) => _getFactoryUsingExactTypeOrNull(
        di: di,
        params: params,
        type: type,
        group: group,
      ),
    );
  }

  @override
  @pragma('vm:prefer-inline')
  FutureOr<Object>? getFactoryUsingRuntimeTypeOrNull({
    required Type type,
    required Object params,
    Id? group,
  }) {
    return getFactoryUsingExactTypeOrNull(
      type: TypeId(type),
      params: params,
    );
  }
}

FutureOr<T>? _getFactoryOrNull<T extends Object, P extends Object>({
  required DI di,
  required P params,
  Id? group,
}) {
  final focusGroup = di.preferFocusGroup(group);
  final dep = di.registry.getDependencyOrNull<FactoryInst<T, P>>(
    group: focusGroup,
  );
  final casted = (dep?.value as FactoryInst?)?.cast<T, P>();
  final result = casted?.constructor(params);
  return result;
}

FutureOr<Object>? _getFactoryUsingExactTypeOrNull({
  required DI di,
  required Object params,
  required Id type,
  Id? group,
}) {
  final focusGroup = di.preferFocusGroup(group);
  final dep = di.registry.getDependencyUsingExactTypeOrNull(
    type: type,
    group: focusGroup,
  );
  final result = (dep?.value as FactoryInst?)?.constructor(params);
  return result;
}
