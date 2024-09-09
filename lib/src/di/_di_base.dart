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
        ChildInterface,
        DebugInterface,
        RegisterUsingRuntimeTypeInterface,
        FocusGroupInterface,
        GetDependencyInterface,
        GetInterface,
        GetUsingExactTypeInterface,
        IsRegisteredInterface,
        RegisterDependencyInterface,
        RegisterInterface,
        RemoveDependencyInterface,
        UnregisterInterface,
        UntilInterface {
  /// A type-safe registry that stores all dependencies.

  final registry = DIRegistry();

  /// Tracks the registration count, assigning a unique index number to each
  /// registration.
  @protected
  var registrationCount = 0;

  final DIBase? parent;

  DIBase({
    DIKey? focusGroup,
    this.parent,
  }) : focusGroup = focusGroup ?? DIKey.defaultGroup;

  @override
  DIKey focusGroup;

  @override
  String toString() {
    return [
      if (parent != null) parent?.toString(),
      '[$DI $hashCode]',
    ].join('; ');
  }
}
