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

import '../utils/_type_safe_registry/type_safe_registry.dart';
import '/src/_index.g.dart';
import '_di_parts1/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract base class DIBase
    implements
        ChildIface,
        DebugIface,
        FocusGroupIface,
        GetDependencyIface,
        GetFactoryIface,
        GetIface,
        GetUsingExactTypeIface,
        IsRegisteredIface,
        RegisterDependencyIface,
        RegisterIface,
        RemoveDependencyIface,
        UnregisterIface {
  /// A type-safe registry that stores all dependencies.
  @protected
  final registry = TypeSafeRegistry();

  /// Tracks the registration count, assigning a unique index number to each
  /// registration.
  @protected
  var registrationCount = 0;

  @protected
  E? getFirstNonNull<E>({
    required DIBase? child,
    required DIBase? parent,
    required E? Function(DI di) test,
  }) {
    for (final di in [child, parent].nonNulls) {
      final result = test(di as DI);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  final DIBase? parent;

  DIBase({
    Descriptor? focusGroup = Descriptor.defaultGroup,
    this.parent,
  }) : focusGroup = focusGroup ?? Descriptor.defaultGroup;

  @override
  Descriptor focusGroup;
}
