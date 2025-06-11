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

//

// import 'package:df_di/df_di.dart';

// import 'package:test/test.dart';

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// void main() {
//   group(
//     'Testing unregister',
//     () {
//       test(
//         '- Unregistering completed futures',
//         () async {
//           final di = DI();
//           final a = await di.register<int>(
//             Future.value(1),
//             onUnregister: (e) {
//               print('Unregistering $e');
//             },
//           );
//           final b = await di.register<double>(
//             Future.value(2.0),
//             onUnregister: (e) {
//               print('Unregistering $e');
//             },
//           );
//           expect(
//             1,
//             a,
//           );
//           expect(
//             2.0,
//             b,
//           );
//           expect(
//             2,
//             di.registry.getGroup(groupEntity: di.focusGroup).length,
//           );
//           expect(
//             1,
//             await di.getOrNull<int>(),
//           );
//           expect(
//             2.0,
//             await di.getOrNull<double>(),
//           );
//           expect(
//             2,
//             di.registry.getGroup(groupEntity: di.focusGroup).length,
//           );
//           di.unregister<int>();
//           di.unregister<double>();
//           expect(
//             0,
//             di.registry.getGroup(groupEntity: di.focusGroup).length,
//           );
//         },
//       );
//       test(
//         '- Unregistering uncompleted futures',
//         () async {
//           final di = DI();
//           di.register<int>(
//             Future.value(1),
//             onUnregister: (e) {
//               print('Unregistering $e');
//             },
//           );
//           di.getOrNull<int>();
//           di.unregister<int>();
//         },
//       );
//       test(
//         '- Unregistering all',
//         () async {
//           final di = DI();
//           di.register<int>(1, groupEntity: const Entity(1));
//           di.register<int>(2, groupEntity: const Entity(2));
//           di.register<int>(3, groupEntity: const Entity(3));
//           di.register<int>(4, groupEntity: const Entity(4));
//           // final values = di.unregisterAll().thenOr((e) => e.map((e) => e.value).toList());
//           // expect(
//           //   '[4, 3, 2, 1]',
//           //   values.toString(),
//           // );
//         },
//       );
//     },
//   );
// }
