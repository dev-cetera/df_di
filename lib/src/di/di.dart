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
        RemoveDependencyImpl,
        UnregisterImpl {
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
        group: Id.globalGroup,
      );
      di.registerChild(group: Id.sessionGroup);
      di.registerChild(group: Id.devGroup);
      di.registerChild(group: Id.prodGroup);
      di.registerChild(group: Id.testGroup);
    },
  );

  /// Default global group.
  static DI get global => app.getChild(group: Id.globalGroup);
  static DI get session => app.getChild(group: Id.sessionGroup);
  static DI get dev => app.getChild(group: Id.devGroup);
  static DI get prod => app.getChild(group: Id.prodGroup);
  static DI get test => app.getChild(group: Id.testGroup);

  factory DI.instantiate({
    Id<Object>? focusGroup = Id.defaultGroup,
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
