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
base mixin UntilMixin on DIBase implements UntilInterface {
  @override
  FutureOr<T> until<T extends Object>({
    DIKey? groupKey,
  }) {
    // Check if the dependency is already registered.
    final test = getOrNull<T>(groupKey: groupKey);
    if (test != null) {
      // Return the dependency if it is already registered.
      return test;
    }
    // If it's not already registered, register a Completer for the type
    // inside the untilsContainer.
    final completerGroup = DIKey(T);
    final completer = InternalCompleterOr<T>._();
    register(completer, groupKey: completerGroup);

    // Wait for the Completer to complete, then get the dependency and return it.
    // The register function will complete the Completer when the dependency is
    // registered.
    final value = completer.internalValue.futureOr.thenOr((value) {
      unregister<InternalCompleterOr<T>>(groupKey: completerGroup);
      return get<T>(groupKey: groupKey);
    });
    return value;
  }

  @override
  FutureOr<Object> untilUsingRuntimeType(
    Type type, {
    DIKey? groupKey,
  }) {
    // Check if the dependency is already registered.
    final test = getUsingRuntimeTypeOrNull(type, groupKey: groupKey);
    if (test != null) {
      // Return the dependency if it is already registered.
      return test;
    }

    // If it's not already registered, register a Completer for the type
    // inside the untilsContainer.
    final completerGroup = DIKey(type);
    final completer = InternalCompleterOr<Object>._();
    registerUsingRuntimeType(completer, groupKey: groupKey);

    // Wait for the Completer to complete, then get the dependency and return it.
    // The register function will complete the Completer when the dependency is
    // registered.
    final value = completer.internalValue.futureOr.thenOr((value) {
      unregister<InternalCompleterOr<Object>>(groupKey: completerGroup);
      return getUsingRuntimeType(type, groupKey: groupKey);
    });
    return value;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A wrapper around CompleterOr for internal use to prevent direct access or
/// modification within the DI container. This is used internally.
@internal
@pragma('vm:keep-name')
class InternalCompleterOr<T extends Object> {
  InternalCompleterOr._();
  final internalValue = CompleterOr<T>();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
abstract interface class UntilInterface {
  FutureOr<T> until<T extends Object>({
    DIKey? groupKey,
  });

  FutureOr<Object> untilUsingRuntimeType(
    Type type, {
    DIKey? groupKey,
  });
}
