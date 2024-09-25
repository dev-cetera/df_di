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

// ignore_for_file: invalid_use_of_protected_member

import '/src/_internal.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class DI extends DIBase
    with
        SupportsTypeKeyMixin,
        SupportsRuntimeTypeMixin,
        SupportsConstructorsMixin,
        SupportsChildrenMixin,
        SupportsServicesMixin {
  /// Default app groupKey.
  static final app = DI();

  /// Default global groupKey.
  static DI get global => app.child(groupKey: DIKey.globalGroup);
  static DI get session => global.child(groupKey: DIKey.sessionGroup);
  static DI get user => session.child(groupKey: DIKey.userGroup);
  static DI get theme => app.child(groupKey: DIKey.themeGroup);
  static DI get dev => app.child(groupKey: DIKey.devGroup);
  static DI get prod => app.child(groupKey: DIKey.prodGroup);
  static DI get test => app.child(groupKey: DIKey.testGroup);
}
