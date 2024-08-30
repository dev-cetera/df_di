import 'package:df_di/df_di.dart';
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

    final helloAfter3SecondsA =
        Future.delayed(const Duration(seconds: 3), () => 'Hello after 3 seconds!');

    di.register<String>(
      helloAfter3SecondsA,
      onUnregister: (message) async {
        final m = await message;
        print('Unregister: $message');
      },
    );
    print('Unregistering...');
    await di.unregister<String>();
    print('UNREG!!!');

    // final helloAfter3SecondsB = di.get<Future<String>>();
    // print('Expected _Future<String>: $helloAfter3SecondsB');

    // final helloAfter3SecondsC = await di.get<String>();
    // print('Expected "Hello after 3 seconds!": $helloAfter3SecondsC');
  }
}
