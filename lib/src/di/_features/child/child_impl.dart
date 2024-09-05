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
base mixin ChildImpl on DIBase implements ChildIface {
  @override
  @pragma('vm:prefer-inline')
  void registerChild({
    Gr? childGroup,
    Gr? group,
  }) {
    final childFocusGroup = preferFocusGroup(childGroup);
    final focusGroup = preferFocusGroup(group);
    registerLazySingleton<DI>(
      (_) => DI(focusGroup: childFocusGroup, parent: this),
      group: focusGroup,
      onUnregister: (e) => e.unregisterAll(),
    );
  }

  @override
  @pragma('vm:prefer-inline')
  DI getChild({Gr? group}) => getSync<DI>(group: group);

  @override
  DI child({
    Gr? childGroup,
    Gr? group,
  }) {
    if (!isRegistered<DI, Object>()) {
      registerChild(
        childGroup: childGroup,
        group: group,
      );
    }
    return getChild(
      group: group,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  void unregisterChild({Gr? group}) => unregister<DI>(group: group);
}
