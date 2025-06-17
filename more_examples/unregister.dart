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

import 'package:df_di/df_di.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() async {
  final di = DI();
  di.register<int>(
    1,
    onUnregister: (value) {
      print('Unregistering value: $value');
      return null;
    },
  );
  di.register<int>(
    2,
    groupEntity: Entity.obj('group2'),
    onUnregister: (value) {
      print('Unregistering value: $value');
      return null;
    },
  );
  // di.unregisterT(
  //   int,
  //   groupEntity: Entity.obj('group2'),
  // );
  di
      .unregisterAll(
        onBeforeUnregister: (value) {
          print('Before unregistering value: $value');
          return null;
        },
        onAfterUnregister: (value) {
          print('After unregistering value: $value');
          return null;
        },
      )
      .end();
}
