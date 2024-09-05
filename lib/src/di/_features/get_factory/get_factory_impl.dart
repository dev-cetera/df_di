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

import '/src/_internal.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
base mixin GetFactoryImpl on DIBase implements GetFactoryIface {
  @protected
  @override
  FutureOr<T> getFactory<T extends Object, P extends Object>(
    P params, {
    Gr? group,
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

  @protected
  @override
  FutureOr<T>? getFactoryOrNull<T extends Object, P extends Object>(
    P params, {
    Gr? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final dep = registry.getDependencyOrNull<FactoryInst<T, P>>(
      group: focusGroup,
    );
    final casted = (dep?.value as FactoryInst?)?.cast<T, P>();
    final result = casted?.constructor(params);
    return result;
  }

  @protected
  @override
  FutureOr<Object> getFactoryUsingExactType({
    required Gr type,
    required Object params,
    Gr? group,
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

  @protected
  @override
  @pragma('vm:prefer-inline')
  FutureOr<Object> getFactoryUsingRuntimeType(
    Type type,
    Object params, {
    Gr? group,
  }) {
    return getFactoryUsingExactType(
      type: Gr(type),
      params: params,
    );
  }

  @protected
  @override
  FutureOr<Object>? getFactoryUsingExactTypeOrNull({
    required Gr type,
    required Object params,
    Gr? group,
  }) {
    final focusGroup = preferFocusGroup(group);
    final dep = registry.getDependencyUsingExactTypeOrNull(
      type: type,
      group: focusGroup,
    );
    final result = (dep?.value as FactoryInst?)?.constructor(params);
    return result;
  }

  @protected
  @override
  @pragma('vm:prefer-inline')
  FutureOr<Object>? getFactoryUsingRuntimeTypeOrNull(
    Type type,
    Object params, {
    Gr? group,
  }) {
    return getFactoryUsingExactTypeOrNull(
      type: Gr(type),
      params: params,
    );
  }
}
