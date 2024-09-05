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
base mixin RegisterUsingRuntimeTypeImpl on DIBase implements RegisterUsingRuntimeTypeIface {
  @override
  void registerUsingRuntimeType(
    FutureOr<Object> value, {
    Gr? group,
    OnUnregisterCallback<Object>? onUnregister,
  }) {
    _register(
      value,
      eventualType: value.runtimeType,
      group: group,
      onUnregister: onUnregister,
    );
  }

  void _register(
    FutureOr<Object> value, {
    required Type eventualType,
    Gr? group,
    OnUnregisterCallback<Object>? onUnregister,
    GetDependencyCondition? condition,
  }) {
    final fg = preferFocusGroup(group);
    if (value is Future<Object>) {
      final baseValue = FutureInst((_) => value);
      final type = _convertBaseValueType(baseValue.runtimeType, value.runtimeType);
      registerDependencyUsingExactType(
        type: type,
        dependency: Dependency(
          value: baseValue,
          registrationIndex: registrationCount++,
          group: fg,
          onUnregister: onUnregister != null
              ? (e) => e.runtimeType == eventualType ? onUnregister(e) : null
              : null,
          condition: condition,
        ),
      );
    } else {
      registerDependencyUsingExactType(
        type: Gr(value.runtimeType),
        dependency: Dependency(
          value: value,
          registrationIndex: registrationCount++,
          group: fg,
          onUnregister: onUnregister != null
              ? (e) => e.runtimeType == eventualType ? onUnregister(e) : null
              : null,
          condition: condition,
        ),
      );
    }
    // If there's a completer waiting for this value that was registered via the until() function,
    // complete it.
    final type = Gr(value.runtimeType);
    (getUsingExactTypeOrNull(
      type: Gr.fromType(
        baseType: InternalCompleterOr,
        subTypes: [type],
      ),
      group: Gr(type),
    ) as InternalCompleterOr?)
        ?.internalValue
        .complete(value);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Gr _convertBaseValueType(Type baseValueType, Type valueType) {
  final futureIdentifierLength = '$Future'.replaceAll('<$dynamic>', '').length;
  final t0 = valueType.toString();
  final t1 = t0.substring(futureIdentifierLength + 1, t0.length - 1);
  final t2 = Gr.fromType(baseType: baseValueType, subTypes: [t1]);
  return t2;
}
