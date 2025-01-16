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

import '../../_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

enum DefaultEntities {
  /// A predefined entity recommended to use as the default group entity for
  /// dependencies. This entity can be utilized when no specific group is
  /// defined, allowing for a fallback option that simplifies dependency
  /// retrieval and management in the DI container.
  DEFAULT_GROUP(DefaultEntity()),

  /// A predefined entity recommended to use as the global group entity for
  /// dependencies. Use This entity for dependencies that need to be accessible
  /// throughout the entire application, regardless of the current scope or
  /// context. This is ideal for singleton services or configurations that
  /// should remain consistent across all parts of the application.
  GLOBAL_GROUP(Entity.reserved(-1002)),

  /// A predefined entity recommended to use as the session group entity for
  /// dependencies. This entity is intended for dependencies that should be
  /// specific to the current user's session, ensuring that the state
  /// and behavior are isolated from other sessions. It is useful for
  /// services that handle user-specific data or contexts.
  SESSION_GROUP(Entity.reserved(-1003)),

  /// A predefined entity recommended to use as the user group entity for
  /// dependencies. This entity is designed for managing dependencies
  /// that are user-specific, such as user preferences, settings,
  /// or any other data that varies from user to user. It helps
  /// organize services related to user management.
  USER_GROUP(Entity.reserved(-1004)),

  /// A predefined entity recommended to use as the theme group entity for
  /// dependencies. This entity is suitable for managing theme-related
  /// services or configurations that control the application's
  /// visual appearance. It allows for easy access and modification
  /// of UI themes, such as light or dark modes.
  THEME_GROUP(Entity.reserved(-1005)),

  /// A predefined entity recommended to use as the production group entity for
  /// dependencies. This entity is intended for services that are specific
  /// to the production environment, ensuring that production-only
  /// configurations or resources are appropriately managed and
  /// distinguished from other environments (like development or testing).
  PROD_GROUP(Entity.reserved(-1006)),

  /// A predefined entity recommended to use as the development group entity for
  /// dependencies. This entity is useful for managing services that are
  /// intended for development purposes, such as debugging tools,
  /// mock services, or any other resources that assist during the
  /// development process. It helps isolate development-specific
  DEV_GROUP(Entity.reserved(-1007)),

  /// A predefined entity recommended to use as the test group entity for
  /// dependencies. This entity is designated for managing services that
  /// are utilized during testing, allowing for easy access to mock
  /// dependencies, test doubles, or any configurations necessary
  /// for unit tests and integration tests. It ensures that test
  /// services do not interfere with the application's production or
  /// development dependencies.
  TEST_GROUP(Entity.reserved(-1008));

  final Entity entity;
  const DefaultEntities(this.entity);
}
