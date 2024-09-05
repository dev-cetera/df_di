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
        GetFactoryImpl,
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

  //
  //
  //

  /// Default app group.
  static final app = DI.instantiate(
    onInstantiate: (di) {
      di.registerChild(
        group: Gr.globalGroup,
      );
      di.registerChild(group: Gr.sessionGroup);
      di.registerChild(group: Gr.devGroup);
      di.registerChild(group: Gr.prodGroup);
      di.registerChild(group: Gr.testGroup);
    },
  );

  /// Default global group.
  static DI get global => app.getChild(group: Gr.globalGroup);
  static DI get session => app.getChild(group: Gr.sessionGroup);
  static DI get dev => app.getChild(group: Gr.devGroup);
  static DI get prod => app.getChild(group: Gr.prodGroup);
  static DI get test => app.getChild(group: Gr.testGroup);

  factory DI.instantiate({
    Gr<Object>? focusGroup,
    DI? parent,
    void Function(DI di)? onInstantiate,
  }) {
    final instance = DI(
      focusGroup: focusGroup,
      parent: parent,
    );
    onInstantiate?.call(instance);
    return instance;
  }
}
