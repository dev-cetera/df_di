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
    DIKey? groupKey,
    DIKey? childGroup,
  }) {
    registerSingleton<DI>(
      () => DI(
        focusGroup: preferFocusGroup(childGroup),
        parent: this,
      ),
      groupKey: preferFocusGroup(groupKey),
      onUnregister: (e) => e.unregisterAll(),
    );
  }

  @override
  @pragma('vm:prefer-inline')
  DI getChild({DIKey? groupKey}) => getSingleton<DI>(
        groupKey: groupKey,
        getFromParents: false,
      ) as DI;

  @override
  DI child({
    DIKey? groupKey,
    DIKey? childGroup,
  }) {
    final registered = isRegistered<SingletonWrapper<DI>, Object>(
      groupKey: groupKey,
      getFromParents: false,
    );
    if (!registered) {
      registerChild(
        groupKey: groupKey,
        childGroup: childGroup,
      );
    }
    return getChild(
      groupKey: groupKey,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  void unregisterChild({DIKey? groupKey}) => unregister<DI>(groupKey: groupKey);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
abstract interface class ChildInterface {
  void registerChild({
    DIKey? groupKey,
    DIKey? childGroup,
  });

  DI getChild({
    DIKey? groupKey,
  });

  DI child({
    DIKey? groupKey,
    DIKey? childGroup,
  });

  void unregisterChild({
    DIKey? groupKey,
  });
}
