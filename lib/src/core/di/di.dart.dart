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
        SupportsConstructorsMixinT,
        SupportsChildrenMixin,
        SupportsServicesMixin,
        SupportsServicesMixinT {
  /// A predefined container recommended for application-wide dependencies.
  /// This container serves as the parent for other containers.
  static final app = DI();

  // /// A predefined container recommended for global dependencies. This
  // /// container is a child of [app].
  // static DI get global => app.child(groupEntity: DefaultEntities.GLOBAL_GROUP.entity);

  // /// A predefined container recommended for session-specific dependencies.
  // /// This container is a child of [global].
  // static DI get session => global.child(groupEntity: DefaultEntities.SESSION_GROUP.entity);

  // /// A predefined container recommended for user-specific dependencies.
  // /// This container is a child of [session].
  // static DI get user => session.child(groupEntity: DefaultEntities.USER_GROUP.entity);

  // /// A predefined container recommended for theme-related objects.
  // /// This container is a child of [app].
  // static DI get theme => app.child(groupEntity: DefaultEntities.THEME_GROUP.entity);

  // /// A predefined container recommended for objects intended for development
  // /// environments. This container is a child of [app].
  // static DI get dev => app.child(groupEntity: DefaultEntities.DEV_GROUP.entity);

  // /// A predefined container recommended for objects intended for production
  // /// environments. This container is a child of [app].
  // static DI get prod => app.child(groupEntity: DefaultEntities.PROD_GROUP.entity);

  // /// A predefined container recommended for objects intended for testing
  // /// environments. This container is a child of [app].
  // static DI get test => app.child(groupEntity: DefaultEntities.TEST_GROUP.entity);
}
