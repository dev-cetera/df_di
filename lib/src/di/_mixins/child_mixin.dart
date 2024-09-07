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
base mixin ChildMixin on DIBase implements ChildInterface {
  @override
  @pragma('vm:prefer-inline')
  void registerChild({
    DIKey? typeGroup,
    DIKey? childGroup,
  }) {
    registerSingleton<DI>(
      () => DI(
        focusGroup: preferFocusGroup(childGroup),
        parent: this,
      ),
      typeGroup: preferFocusGroup(typeGroup),
      onUnregister: (e) => e.unregisterAll(),
    );
  }

  @override
  @pragma('vm:prefer-inline')
  DI getChild({DIKey? typeGroup}) => getSingleton<DI>(
        typeGroup: typeGroup,
        getFromParents: false,
      ) as DI;

  @override
  DI child({
    DIKey? typeGroup,
    DIKey? childGroup,
  }) {
    final registered = isRegistered<SingletonWrapper<DI>, Object>(
      typeGroup: typeGroup,
      getFromParents: false,
    );
    if (!registered) {
      registerChild(
        typeGroup: typeGroup,
        childGroup: childGroup,
      );
    }
    return getChild(
      typeGroup: typeGroup,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  void unregisterChild({DIKey? typeGroup}) => unregister<DI>(typeGroup: typeGroup);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
abstract interface class ChildInterface {
  void registerChild({
    DIKey? typeGroup,
    DIKey? childGroup,
  });

  DI getChild({
    DIKey? typeGroup,
  });

  DI child({
    DIKey? typeGroup,
    DIKey? childGroup,
  });

  void unregisterChild({
    DIKey? typeGroup,
  });
}
