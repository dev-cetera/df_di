//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'entity.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// The fallback group entity used when no `groupEntity` is supplied to a
/// `register*` / `get*` call.
final class DefaultEntity extends Entity {
  const DefaultEntity() : super.reserved(-1001);
}

/// Group entity recommended for application-wide dependencies that should be
/// accessible regardless of the current scope. Backs [DI.global].
final class GlobalEntity extends Entity {
  const GlobalEntity() : super.reserved(-1002);
}

/// Group entity recommended for session-scoped dependencies (e.g. anything
/// tied to the current sign-in). Backs [DI.session].
final class SessionEntity extends Entity {
  const SessionEntity() : super.reserved(-1003);
}

/// Group entity recommended for user-specific dependencies (preferences,
/// per-user state). Backs [DI.user].
final class UserEntity extends Entity {
  const UserEntity() : super.reserved(-1004);
}

/// Group entity recommended for theme-related dependencies. Backs [DI.theme].
final class ThemeEntity extends Entity {
  const ThemeEntity() : super.reserved(-1005);
}

/// Group entity recommended for production-only dependencies. Backs [DI.prod].
final class ProdEntity extends Entity {
  const ProdEntity() : super.reserved(-1006);
}

/// Group entity recommended for development-only dependencies such as
/// debugging tools or mock services. Backs [DI.dev].
final class DevEntity extends Entity {
  const DevEntity() : super.reserved(-1007);
}

/// Group entity recommended for test-only dependencies. Backs [DI.test].
final class TestEntity extends Entity {
  const TestEntity() : super.reserved(-1008);
}
