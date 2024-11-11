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

import 'dart:async';

import 'package:df_di/df_di.dart';

// import 'package:test/test.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() async {
  DI.session.registerLazyService(UserStreamingService.new);
  print(await DI.session.getServiceSingleton<UserStreamingService>());
  Future.delayed(
    const Duration(seconds: 3),
    () => DI.session.unregister<UserStreamingService>(),
  );

  // group(
  //   '1',
  //   () {
  //     test('- 1', () async {
  //       DI.session.registerService(UserStreamingService.new);
  //     });
  //   },
  // );
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class UserStreamingService
    extends StreamService<Map<String, dynamic>, Object?> {
  UserStreamingService();

  @override
  Future<void> onInitService(_) async {
    await super.initialData;
  }

  @override
  FutureOr<void> onResetService(_) {}

  @override
  void onPushToStream(Map<String, dynamic> data) {
    print(data);
    super.onPushToStream(data);
  }

  @override
  Stream<Map<String, dynamic>> provideInputStream(_) {
    return StreamUtility.i.newPoller<Map<String, dynamic>>(
      () async {
        return {'id': 'pu_1s3hs64kshs74bms'};
      },
      const Duration(seconds: 1),
    );
  }

  @override
  FutureOr<void> onDispose() {}
}
