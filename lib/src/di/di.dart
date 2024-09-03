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

import 'package:meta/meta.dart';

import '../utils/_type_safe_registry/type_safe_registry.dart';
import '/src/_index.g.dart';
import '_di_parts/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract base class DIBase
    implements
        ChildInter,
        DebugInter,
        FocusGroupInter,
        GetDependencyInter,
        GetFactoryInter,
        GetInter,
        GetUsingExactTypeInter,
        IsRegisteredInter,
        RegisterDependencyInter,
        RegisterInter,
        RemoveDependencyInter,
        UnregisterInter {
  /// A type-safe registry that stores all dependencies.
  @protected
  final registry = TypeSafeRegistry();

  /// Tracks the registration count, assigning a unique index number to each
  /// registration.
  @protected
  var registrationCount = 0;

  @protected
  E? getFirstNonNull<E>({
    required DIBase? child,
    required DIBase? parent,
    required E? Function(DI di) test,
  }) {
    for (final di in [child, parent].nonNulls) {
      final result = test(di as DI);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  final DIBase? parent;

  DIBase({
    Descriptor? focusGroup = Descriptor.defaultGroup,
    this.parent,
  }) : focusGroup = focusGroup ?? Descriptor.defaultGroup;

  @override
  Descriptor focusGroup;
}

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
      di.registerChild(group: Descriptor.globalGroup);
      di.registerChild(group: Descriptor.sessionGroup);
      di.registerChild(group: Descriptor.devGroup);
      di.registerChild(group: Descriptor.prodGroup);
      di.registerChild(group: Descriptor.testGroup);
    },
  );

  /// Default global group.
  static DI get global => app.getChild(group: Descriptor.globalGroup);
  static DI get session => app.getChild(group: Descriptor.sessionGroup);
  static DI get dev => app.getChild(group: Descriptor.devGroup);
  static DI get prod => app.getChild(group: Descriptor.prodGroup);
  static DI get test => app.getChild(group: Descriptor.testGroup);

  factory DI.instantiate({
    Descriptor<Object>? focusGroup = Descriptor.defaultGroup,
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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Exception thrown when attempting to register a dependency that is already registered.
final class DependencyAlreadyRegisteredException extends DFDIPackageException {
  DependencyAlreadyRegisteredException({
    required Object type,
    required Descriptor group,
  }) : super('Dependency of type $type in group $group is already registered.');
}

/// Exception thrown when a requested dependency is not found.
final class DependencyNotFoundException extends DFDIPackageException {
  DependencyNotFoundException({
    required Object type,
    required Descriptor group,
  }) : super('Dependency of type $type in group "$group" not found.');
}
