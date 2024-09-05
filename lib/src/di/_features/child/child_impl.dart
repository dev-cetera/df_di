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
    Gr? group,
    Gr? childGroup,
  }) {
    registerSingleton<DI>(
      () => DI(
        focusGroup: preferFocusGroup(childGroup),
        parent: this,
      ),
      group: preferFocusGroup(group),
      onUnregister: (e) => e.unregisterAll(),
    );
  }

  @override
  @pragma('vm:prefer-inline')
  DI getChild({Gr? group}) => getSingleton<DI>(
        group: group,
        getFromParents: false,
      ) as DI;

  @override
  DI child({
    Gr? group,
    Gr? childGroup,
  }) {
    final registered = isRegistered<SingletonWrapper<DI>, Object>(
      group: group,
      getFromParents: false,
    );
    if (!registered) {
      registerChild(
        group: group,
        childGroup: childGroup,
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
