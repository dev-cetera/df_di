// //.title
// // ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// //
// // Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// // source code is governed by an MIT-style license described in the LICENSE
// // file located in this project's root directory.
// //
// // See: https://opensource.org/license/mit
// //
// // ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// //.title~

// import 'dart:async';

// import 'package:df_di/df_di.dart';

// // import 'package:test/test.dart';

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// void main() async {
//   DI.session.registerLazyService(UserStreamingService.new);
//   print(await DI.session.getServiceSingleton<UserStreamingService>());
//   await Future.delayed(
//     const Duration(seconds: 3),
//     () => DI.session.unregister<UserStreamingService>(),
//   );

//   // group(
//   //   '1',
//   //   () {
//   //     test('- 1', () async {
//   //       DI.session.registerService(UserStreamingService.new);
//   //     });
//   //   },
//   // );
// }

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// final class UserStreamingService extends StreamService<Map<String, dynamic>, Object?> {
//   UserStreamingService();

//   @override
//   ServiceListeners<Object?> provideInitListeners() {
//     return [
//       ...super.provideInitListeners(),
//       (_) => super.initialData,
//     ];
//   }

//   @override
//   Stream<Map<String, dynamic>> provideInputStream(_) {
//     return StreamUtility.i.newPoller<Map<String, dynamic>>(
//       () async {
//         return {'id': 'pu_1s3hs64kshs74bms'};
//       },
//       const Duration(seconds: 1),
//     );
//   }

//   @override
//   // ignore: invalid_override_of_non_virtual_member
//   FutureOr<void> dispose() async {
//     await super.dispose();
//     print('Done!');
//   }

//   @override
//   ServiceListeners<Map<String, dynamic>> provideOnPushToStreamListeners() {
//     return [
//       ...super.provideOnPushToStreamListeners(),
//       (data) => print(data),
//     ];
//   }
// }
