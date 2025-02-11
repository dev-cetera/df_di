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

// import 'package:df_di/df_di.dart';
// import 'package:df_di/src/_common.dart';

// import 'package:test/test.dart';

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// void main() {
//   group(
//     'Testing children',
//     () {
//       test(
//         '- Testing if a child gets created and unregistered',
//         () async {
//           final di = DI();
//           final child = DI();
//           di.register(unsafe: () => child);
//           final gotChild = di.getSync<DI>().unwrap().value.unwrap();
//           expect(
//             child,
//             gotChild,
//           );
//           di.unregister<DI>();
//         },
//       );
//       test(
//         '- Testing singletons',
//         () async {
//           final di = DI();
//           di.registerLazy<int>(() => const Sync(Ok(1)));
//           expect(
//             1,
//             di.getSingleton<int>().sync().unwrap().value.unwrap().unwrap(),
//           );
//         },
//       );
//       test(
//         '- Testing singletons',
//         () async {
//           final c1 = DI();
//           c1.register<int>(unsafe: () => 1);
//           final c4 = c1.child().child().child().child();
//           expect(
//             1,
//             c4.getOrNone<int>().unwrap(),
//           );
//           //c1.unregisterConstructor<DIContainer>();
//         },
//       );
//     },
//   );
// }
