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

/// A flexible and extensive Dependency Injection (DI) class for managing
/// dependencies across an application.
base class DI extends DIBase
    with
        ChildMixin,
        DebugMixin,
        FocusGroupMixin,
        GetDependencyMixin,
        GetMixin,
        GetUsingExactTypeMixin,
        IsRegisteredMixin,
        RegisterDependencyMixin,
        RegisterMixin,
        RegisterUsingRuntimeTypeMixin,
        RemoveDependencyMixin,
        UnregisterMixin,
        UntilMixin {
  /// The number of dependencies registered in this instance.
  int get length => registrationCount;

  /// Creates a new instance of the DI class. Prefer using [global], unless
  /// there's a specific need for a separate instance.

  DI({
    super.focusGroup,
    super.parent,
  });

  /// Default app typeGroup.
  static final app = DI();

  /// Default global typeGroup.
  static DI get global => app.child(typeGroup: DIKey.globalGroup);
  static DI get session => global.child(typeGroup: DIKey.sessionGroup);
  static DI get dev => app.child(typeGroup: DIKey.devGroup);
  static DI get prod => app.child(typeGroup: DIKey.prodGroup);
  static DI get test => app.child(typeGroup: DIKey.testGroup);
}
