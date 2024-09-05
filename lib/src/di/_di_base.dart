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

abstract base class DIBase
    implements
        ChildIface,
        DebugIface,
         RegisterUsingRuntimeTypeIface,
        FocusGroupIface,
        GetDependencyIface,
        GetFactoryIface,
        GetIface,
        GetUsingExactTypeIface,
        IsRegisteredIface,
        RegisterDependencyIface,
        RegisterIface,
        RemoveDependencyIface,
        UnregisterIface,
        UntilIface {
  /// A type-safe registry that stores all dependencies.
  @protected
  final registry = Registry();

  /// Tracks the registration count, assigning a unique index number to each
  /// registration.
  @protected
  var registrationCount = 0;

  final DIBase? parent;

  DIBase({
    Gr? focusGroup,
    this.parent,
  }) : focusGroup = focusGroup ?? Gr.defaultGroup;

  @override
  Gr focusGroup;
}
