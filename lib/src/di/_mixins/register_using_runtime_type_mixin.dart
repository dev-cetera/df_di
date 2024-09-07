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
base mixin RegisterUsingRuntimeTypeMixin on DIBase implements RegisterUsingRuntimeTypeInterface {
  @override
  void registerUsingRuntimeType(
    FutureOr<Object> value, {
    DIKey? groupKey,
    OnUnregisterCallback<Object>? onUnregister,
  }) {
    _register(
      value,
      eventualType: value.runtimeType,
      groupKey: groupKey,
      onUnregister: onUnregister,
    );
  }

  void _register(
    FutureOr<Object> value, {
    required Type eventualType,
    DIKey? groupKey,
    OnUnregisterCallback<Object>? onUnregister,
    DependencyValidator? condition,
  }) {
    final fg = preferFocusGroup(groupKey);
    if (value is Future<Object>) {
      final baseValue = FutureOrInst((_) => value);
      final type = _convertBaseValueType(baseValue.runtimeType, value.runtimeType);
      registerDependencyUsingExactType(
        type: type,
        dependency: Dependency(
          value: baseValue,
          metadata: DependencyMetadata(
            index: registrationCount++,
            initialType: baseValue.runtimeType,
            groupKey: fg,
            onUnregister: onUnregister != null
                ? (e) => e.runtimeType == eventualType ? onUnregister(e) : null
                : null,
            condition: condition,
          ),
        ),
      );
    } else {
      registerDependencyUsingExactType(
        type: DIKey(value.runtimeType),
        dependency: Dependency(
            value: value,
            metadata: DependencyMetadata(
              index: registrationCount++,
              initialType: value.runtimeType,
              groupKey: fg,
              onUnregister: onUnregister != null
                  ? (e) => e.runtimeType == eventualType ? onUnregister(e) : null
                  : null,
              condition: condition,
            )),
      );
    }
    // If there's a completer waiting for this value that was registered via the until() function,
    // complete it.
    final type = DIKey(value.runtimeType);
    (getUsingExactTypeOrNull(
      type: DIKey.fromType(
        baseType: InternalCompleterOr,
        subTypes: [type],
      ),
      groupKey: DIKey(type),
    ) as InternalCompleterOr?)
        ?.internalValue
        .complete(value);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

DIKey _convertBaseValueType(Type baseValueType, Type valueType) {
  final futureIdentifierLength = '$Future'.replaceAll('<$dynamic>', '').length;
  final t0 = valueType.toString();
  final t1 = t0.substring(futureIdentifierLength + 1, t0.length - 1);
  final t2 = DIKey.fromType(baseType: baseValueType, subTypes: [t1]);
  return t2;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
abstract interface class RegisterUsingRuntimeTypeInterface {
  void registerUsingRuntimeType(
    FutureOr<Object> value, {
    DIKey? groupKey,
    OnUnregisterCallback<Object>? onUnregister,
  });
}
