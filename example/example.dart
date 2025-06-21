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

/// A simple service to manage user data.
class UserService {
  //
  //
  //

  final int id;
  bool _isDisposed = false;

  //
  //
  //

  UserService(this.id);

  //
  //
  //

  /// Gets the user data for the user identified by [id].
  Async<Map<String, dynamic>> getUserData() {
    // Any errors thrown witin Async will be passed to the Async instance
    // returned.
    return Async(() async {
      if (_isDisposed) {
        throw Err('UserService has already been disposed!');
      }
      await Future<void>.delayed(const Duration(seconds: 1));
      return {'id': id, 'name': 'John Doe'};
    });
  }

  //
  //
  //

  /// Cleans up resources used by the service.
  Async<void> dispose() {
    return Async(() async {
      if (_isDisposed) {
        throw Err('UserService has already been disposed!');
      }
      _isDisposed = true;
      return Unit();
    });
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Future<void> main() async {
  UNSAFE:
  {
    // Create some future to a resource that may not yet exist in DI.global that
    // we can await later.
    final userServiceFuture = DI.global.untilSuper<UserService>().unwrap();

    // Register the service after a delay.

    // This simulates a part of your application that initializes and provides
    // the service, for example, after a user logs in.
    Future.delayed(const Duration(seconds: 2), () {
      DI.global
          .register<UserService>(
            UserService(123),
            // Handle what happens when we unregister the dependency.
            onUnregister: (result) {
              if (result.isOk()) {
                final userService = result.unwrap();
                return Future<void>.value(userService.dispose().unwrap());
              }
              return null;
            },
          )
          .end;
    });

    // Await the service and use it.

    // Execution will pause here until the `Future.delayed` block above registers
    // the service, which in turn completes the `userServiceFuture`.
    final userService = await userServiceFuture;

    final userDataResult = await userService.getUserData().value;
    if (userDataResult.isOk()) {
      final userData = userDataResult.unwrap();
      print(userData);
    } else {
      print('Error: ${userDataResult.err()}');
    }

    // Unregister the service to trigger cleanup.

    // This is useful when a user logs out or a feature is no longer needed.
    // Calling `unregister` will trigger the `onUnregister` callback we defined.
    final _ = await DI.global.unregister<UserService>().value;

    final isRegistered = DI.global.isRegistered<UserService>();
    print('Is UserService still registered? $isRegistered');

    // Let's see what happens if we get try and a dependency that is no longer
    // egistered.
    final userDataOpt = DI.global.get<UserService>();
    if (userDataOpt.isSome()) {
      print('This should never print!');
    } else {
      print('No UserService is registeted here! This is expected!');
    }

    // Let's see what happens if we get try and dispose the service again!
    userService.dispose().unwrap().catchError((Object e) {
      print(e);
    });
  }
}
