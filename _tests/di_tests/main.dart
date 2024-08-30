import 'package:df_di/df_di.dart';
import 'package:df_pod/df_pod.dart';
import 'package:flutter/foundation.dart';

void main() async {
  if (kDebugMode) {
    // di.register(1);
    // print('Expected 1: ${di.get<int>()}');
    // try {
    //   di.register(2);
    // } on DependencyAlreadyRegisteredException {
    //   print('Expected: DependencyAlreadyRegisteredException thrown');
    // }
    // di.register(3, key: const DIKey('3'));
    // print('Expected 3: ${di.get<int>(const DIKey('3'))}');

    // di.unregister<int>();
    // di.register<int>(4);
    // print('Expected 4: ${di.get<int>()}');

    // try {
    //   print(di.get());
    // } on DependencyNotFoundException {
    //   print('Expected: DependencyNotFoundException thrown');
    // }

    // var i = 0;
    // di.register(i);
    // i++;
    // print(di.get<int>()); // prints 0
    // di.unregister<int>();
    // di.register(Singleton<int>(() => ++i));
    // print(di.get<int>()); // prints 2
    // print(di.get<int>()); // prints 2 again
    // di.unregister<int>();
    // di.register(Factory<int>(() => ++i));
    // print(di.get<int>()); // prints 3
    // print(di.get<int>()); // prints 4
    // print(di.get<int>()); // prints 5

    //await di.unregister<String>();
    //print('UNREG!!!');

    // final helloAfter3SecondsB = di.get<Future<String>>();
    // print('Expected _Future<String>: $helloAfter3SecondsB');

    // final helloAfter3SecondsC = await di.get<String>();
    // print('Expected "Hello after 3 seconds!": $helloAfter3SecondsC');

    di.registerSingletonService(
      () => Future.delayed(const Duration(seconds: 3), () => Service.initService()),
    );

    final service = await di.get<Service>();

    service.dispose();

    print(service);
  }
}

class Service extends DisposableService {
  late final P<String> pTest = willDispose(Pod('test'));

  Service.initService() : super.initService();
}
