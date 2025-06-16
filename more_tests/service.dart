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

import 'package:test/test.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() {
  test('Testing the registration and initialization of a service.', () async {
    final di = DI();
    final service = TestService();
    final _ = await di
        .registerLazy<TestService>(() => Sync.value(Ok(service)))
        .value;
    print('Just registered...');
    final value1 = await di.getLazySingletonUnsafe<TestService>();
    final value2 = await di.getLazySingletonUnsafe<TestService>();
    expect(value1, service);
    expect(value1, value2);
  });
}

base class TestService extends Service {
  @override
  provideInitListeners() {
    return [
      (_) {
        print('Initializing TestService!!!');
        return SYNC_NONE;
      },
    ];
  }

  @override
  provideDisposeListeners() {
    return [];
  }

  @override
  providePauseListeners() {
    return [];
  }

  @override
  provideResumeListeners() {
    return [];
  }
}
