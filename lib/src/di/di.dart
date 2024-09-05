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
        ChildImpl,
        DebugImpl,
        FocusGroupImpl,
        GetDependencyImpl,
        GetImpl,
        GetUsingExactTypeImpl,
        IsRegisteredImpl,
        RegisterDependencyImpl,
        RegisterImpl,
        RegisterUsingRuntimeTypeImpl,
        RemoveDependencyImpl,
        UnregisterImpl,
        UntilImpl {
  /// The number of dependencies registered in this instance.
  int get length => registrationCount;

  /// Creates a new instance of the DI class. Prefer using [global], unless
  /// there's a specific need for a separate instance.

  DI({
    super.focusGroup,
    super.parent,
  });

  /// Default app group.
  static final app = DI();

  /// Default global group.
  static DI get global => app.child(group: Gr.globalGroup);
  static DI get session => global.child(group: Gr.sessionGroup);
  static DI get dev => app.child(group: Gr.devGroup);
  static DI get prod => app.child(group: Gr.prodGroup);
  static DI get test => app.child(group: Gr.testGroup);
}
