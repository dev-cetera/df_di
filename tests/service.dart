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

// ignore_for_file: invalid_use_of_protected_member

import 'package:df_di/df_di.dart';

import 'package:test/test.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() {
  test('Testing the registration and initialization of a service.', () async {
    final di = DI();
    final service = TestService();
    di.registerAndInitService<TestService>(service);
    print('Just registered...');
    final value1 = await di.getUnsafe<TestService>();
    final value2 = await di.getUnsafe<TestService>();
    expect(value1, service);
    expect(value1, value2);
  });
  test(
    'Testing the lazy registration and initialization of a service.',
    () async {
      final di = DI();
      final service = TestService();
      di.registerLazyServiceUnsafe<TestService>(constructor: () => service);
      print('Just registered...');
      final value1 = di.getServiceSingletonSync<TestService>();
      final value2 = di.getServiceSingletonSync<TestService>();
      expect(value1, service);
      expect(value1, value2);
    },
  );
}

base class TestService extends Service {
  @override
  provideInitListeners() {
    return [
      ...super.provideInitListeners(),
      (_) {
        print('Initializing TestService!!!');
      },
    ];
  }
}
