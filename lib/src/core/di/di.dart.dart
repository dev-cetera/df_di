//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// ignore_for_file: invalid_use_of_protected_member

import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class DI extends DIBase
    with
        SupportsMixinK,
        SupportsMixinT,
        SupportsConstructorsMixin,
        SupportsConstructorsMixinK,
        SupportsConstructorsMixinT,
        SupportsChildrenMixin,
        SupportsServicesMixin,
        SupportsServicesMixinK,
        SupportsServicesMixinT {
  /// A predefined container recommended for application-wide dependencies.
  /// This container serves as the parent for other containers.
  static final root = DI();

  /// A predefined container recommended for global dependencies. This
  /// container is a child of [root].
  @pragma('vm:prefer-inline')
  static DI get global => root.child(groupEntity: const GlobalEntity());

  /// A predefined container recommended for session-specific dependencies.
  /// This container is a child of [global].
  @pragma('vm:prefer-inline')
  static DI get session => global.child(groupEntity: const SessionEntity());

  /// A predefined container recommended for user-specific dependencies.
  /// This container is a child of [session].
  @pragma('vm:prefer-inline')
  static DI get user => session.child(groupEntity: const UserEntity());

  /// A predefined container recommended for theme-related objects.
  /// This container is a child of [root].
  @pragma('vm:prefer-inline')
  static DI get theme => root.child(groupEntity: const ThemeEntity());

  /// A predefined container recommended for objects intended for development
  /// environments. This container is a child of [root].
  @pragma('vm:prefer-inline')
  static DI get dev => root.child(groupEntity: const DevEntity());

  /// A predefined container recommended for objects intended for production
  /// environments. This container is a child of [root].
  @pragma('vm:prefer-inline')
  static DI get prod => root.child(groupEntity: const ProdEntity());

  /// A predefined container recommended for objects intended for testing
  /// environments. This container is a child of [root].
  @pragma('vm:prefer-inline')
  static DI get test => root.child(groupEntity: const TestEntity());
}
