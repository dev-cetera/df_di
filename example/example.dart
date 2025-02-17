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

// import 'dart:async';

// import 'package:df_di/df_di.dart';
import 'package:df_di/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// Iterable<int> sort(Iterable<int> values) sync* {
//   for (final e in values) {}
// }

Future<Object> main() async {
  final di = DI();

  // di.register<int>(unsafe: () async => 1);
  // print(di.registry.state);
  // print(await di.getUnsafeK(TypeEntity(int)));
  // print(di.registry.state);
  // print(await di.getUnsafeK(TypeEntity(int)));
  // print(di.registry.state);
  di.registerLazy<List<int>>(() => Async.unsafe(() async => [123]));

  print(await di.getSingleton<List<int>>().unwrap().unwrap());

  // final g = di.get<Lazy<List<int>>>();
  // print(await g.unwrap().sync().unwrap().unwrap().singleton.unwrap());

  // print(di.getSingleton<List<int>>().unwrap().async().unwrap().unwrap());

  // final option = di.get<Lazy<List<int>>>();
  // if (option.isNone()) {
  //   return const None();
  // }
  // final result = option.unwrap().sync().unwrap().value;
  // print(result);

  // final b = option.unwrap();
  // final c = b.sync().unwrap().value;
  // final d = c.unwrap();
  // final e = await d.singleton.async().unwrap().unwrap();
  // print(e);

  // value = di.getSingleton<List<int>>().unwrap();

  //value.async().unwrap(); //.unwrap().value.then((e) => e.unwrap());

  //print(value.unwrap());
  // // print(value.unwrap().unwrapSync().unwrap());
  // print(di.getUnsafe<Lazy<List<int>>>());

  // await di.getSingleton<List<int>>().value;
  // final a = await l.unwrapAsync();
  // print(a);
  // final l2 = di.getSingleton<List<int>>();
  // final b = await l2.unwrapAsync();
  // print(a == b);
  // di.resetSingleton<List<int>>().value;
  // final l3 = di.getSingleton<List<int>>();
  // final c = await l3.unwrapAsync();
  // final l4 = di.getSingleton<List<int>>();
  // await l4.value;
  // final d = l4.unwrapSync();
  // print(di.registry.state);
  // print(a == c);
  // final a = await l.unwrapAsync();
  // print(await l.unwrapAsync());
  // print(di.getSingletonUnsafe<List<int>>() == l.unwrapSync());

  // final a = TypeEntity(List, [int]);
  // final c = TypeEntity(List, [TypeEntity(TypeEntity(TypeEntity(int)))]);
  // print(a);
  // print(c);

  // final di = DI();
  // final a = di.register<int>(unsafe: () => Future.delayed(const Duration(seconds: 3), () => 2));
  // // print(a);
  // final b =
  //     di.register<String>(unsafe: () => Future.delayed(const Duration(seconds: 3), () => 'hello'));
  // // print(b);
  // final parent = DI();
  // parent.register<DIBase>(unsafe: () => di);
  //di.register<DIBase>(unsafe: () => child);

  // print((await parent.untilK(TypeEntity(int)).value).ok().unwrap());
  // print((await parent.untilK(TypeEntity(String)).value).ok().unwrap());
  // print((await parent.until<int>().value).ok().unwrap());
  // print((await parent.until<String>().value).ok().unwrap());

  // Future.delayed(const Duration(seconds: 4), () {
  //   di.register<String>(unsafe: () => 'Hello World!');
  //   print(di.completers.unwrap().registry.state);
  // });

  // di.until<String>().map((e) {
  //   print(e);
  //   return e;
  // });

  // print(di.completers.unwrap().registry.state);

  // print(value.ifAsync((e) => e.value.then((e) => e.ifOk((e) => print(e.value)))));
  //print(di.registry.state);

  //di.registry.removeDependency<Future<int>>();

  //print(di.isRegisteredK(TypeEntity(int)));

  // print(
  //   di.isRegisteredK(TypeEntity(Async, [int])),
  // );

  // final a = await di.get<int>().unwrap().value;
  // print(a.unwrap());

  // final b = await di.getK(TypeEntity(Async, [int])).unwrap().value;
  // print(b.unwrap());

  //final a = await di.getK(TypeEntity(int)).map((e) => e.value).unwrap();

  //print(a.unwrap());

  // print(di
  //     .get<int>()
  //     .async()
  //     .unwrap()
  //     .value
  //     .then((e) => e.ifOk((e) => e.value.ifSome((e) => print(e.unwrap())))));
  //di.unregister<int>().ifSome((e) => print('SOME $e'));
  //print(di.get<int>().unwrap().isNone());
  //print(di.registry.state);
  return 1;
}
//   print('\n# Get access to the global DI container:\n');
//   final di = DI();
//   print('DI.global == di: ${DI.global == di}');

//   print(
//     '\n# Get the state of the global DI container (prints an empty map):\n',
//   );
//   print(di.registry.state);

//   print('\n# Create a new DI container:\n');
//   print(DI());

//   print('\n# Use any of the pre-defined containers for your app:\n');
//   print(DI.app); // You can store app settings in here.
//   print(DI.app); // You can contain the global state in here.
//   print(DI.global); // You can contain stuff for the active session in here.
//   print(DI.dev); // A container you can use for or development-only.
//   print(DI.test); // A container you can use for or test-only.
//   print(DI.prod); // A container you can use for or production-only.

//   // Or create your own custom containers:
//   final di1 = DI();
//   print(di1);
//   final di2 = DI();
//   print(di2);

//   print('\n# Register the universe and everything:\n');
//   di.register<int>(42);
//   print(di.getOrNull<int>());

//   print('\n# Register Futures:\n');
//   DI.prod.register<double>(Future<double>.value(pi));
//   di.register<double>(
//     Future.delayed(const Duration(milliseconds: 10), () => pi),
//   );
//   print('PI is ${await DI.prod.getOrNull<double>()}');

//   print('Get access to the global DI container:\n\n');
//   di.register(Future.value('Hello, DI!'));

//   // Register FooBarService as a lazy singleton.
//   di.registerLazyService(FooBarService.new);

//   print(di.registry.state.entries);

//   final fooBarService1 = await di.getServiceSingletonOrNull<FooBarService>();
//   final fooBarService2 = await di.getServiceSingletonT(FooBarService);
//   print(fooBarService1 == fooBarService2);

//   print(di.registry.state.entries);

//   print('TIME TO UNREG 1');

//   await di.unregister<int>();
//   print('TIME TO UNREG 2');
//   await di.unregister<String>();
//   print('TIME TO UNREG 3');
//   //await di.unregister<Constructor<FooBarService>>();
//   print('TIME TO UNREG 4');

//   await di.unregisterAll(
//     onAfterUnregister: (dependency) {
//       print('Unregistered: ${dependency.value}');
//     },
//   ).thenOr((_) {
//     // Completes when all dependencies are unregistered and removed
//     // from di.
//     print('Unregistered all!');
//   });

//   print('TIME TO UNREG 5');
// }

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// /// A new service class that extends [Service].
// ///
// /// - Register via `di.initSingletonService(FooBarService.new);`
// /// - Get via `di.get<FooBarService>();`
// /// - Unregister via `di.unregister<FooBarService>();`
// final class FooBarService extends Service {
//   @override
//   ServiceListeners provideDisposeListeners() {
//     return [
//       ...super.provideDisposeListeners(),
//     ];
//   }

//   @override
//   ServiceListeners provideInitListeners() {
//     return [
//       ...super.provideInitListeners(),
//       (_) => print('Disposed $FooBarService'),
//     ];
//   }
// }

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// final class CountingService extends StreamService<int, bool> {
//   @override
//   Stream<int> provideInputStream(_) async* {
//     for (var n = 0; n < 100; n++) {
//       await Future<void>.delayed(const Duration(seconds: 1));
//       yield n;
//     }
//   }

//   @override
//   ServiceListeners<bool> provideInitListeners() {
//     return [
//       ...super.provideInitListeners(),
//     ];
//   }

//   @override
//   ServiceListeners provideDisposeListeners() {
//     return [
//       ...super.provideDisposeListeners(),
//       (_) => print('Disposed $FooBarService'),
//     ];
//   }

//   @override
//   ServiceListeners<int> provideOnPushToStreamListeners() {
//     return [
//       ...super.provideOnPushToStreamListeners(),
//       (data) => print('[CountingService]: $data'),
//     ];
//   }
// }

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// // An example of a service that DI will treat as sync.
// final class SyncServiceExmple extends Service {
//   @override
//   ServiceListeners provideInitListeners() {
//     return [
//       ...super.provideInitListeners(),
//       (_) => 1,
//     ];
//   }

//   @override
//   ServiceListeners provideDisposeListeners() {
//     return [
//       ...super.provideDisposeListeners(),
//       (_) async => 1,
//     ];
//   }
// }

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// // An example of a service that DI will treat as async.
// final class AsyncServiceExample extends Service {
//   @override
//   ServiceListeners provideInitListeners() {
//     return [
//       ...super.provideInitListeners(),
//       (_) async => 1,
//     ];
//   }

//   @override
//   ServiceListeners provideDisposeListeners() {
//     return [
//       ...super.provideDisposeListeners(),
//       (_) => 1,
//     ];
//   }
// }
