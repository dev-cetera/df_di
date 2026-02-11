// This example demonstrates dependency injection with df_di.
// ignore_for_file: avoid_print

import 'package:df_di/df_di.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Example 1: A simple service class to demonstrate DI registration.
class UserService {
  final int id;
  bool _isDisposed = false;

  UserService(this.id);

  Async<Map<String, dynamic>> getUserData() {
    return Async(() async {
      if (_isDisposed) {
        throw Err('UserService has already been disposed!');
      }
      await Future<void>.delayed(const Duration(seconds: 1));
      return {'id': id, 'name': 'John Doe'};
    });
  }

  Async<Unit> dispose() {
    return Async(() async {
      if (_isDisposed) {
        throw Err('UserService has already been disposed!');
      }
      _isDisposed = true;
      print('UserService disposed');
      return Unit();
    });
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Example 2: A Service with lifecycle management.
final class CounterService extends Service {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    print('Count incremented to: $_count');
  }

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) {
    return [
      (_) {
        _count = 0;
        print('CounterService initialized');
        return syncUnit();
      },
    ];
  }

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) {
    return [
      (_) {
        print('CounterService paused');
        return syncUnit();
      },
    ];
  }

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) {
    return [
      (_) {
        print('CounterService resumed');
        return syncUnit();
      },
    ];
  }

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) {
    return [
      (_) {
        print('CounterService disposed with final count: $_count');
        return syncUnit();
      },
    ];
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Future<void> main() async {
  print('=== df_di Example ===\n');

  // --- Part 1: Basic DI with UserService ---
  print('--- Part 1: Basic DI Registration ---');

  UNSAFE:
  {
    // Create a future that waits for UserService to be registered
    final userServiceFuture = DI.global.untilSuper<UserService>().unwrap();

    // Register the service after a delay (simulating async initialization)
    Future.delayed(const Duration(seconds: 1), () {
      DI.global
          .register<UserService>(
            UserService(123),
            onUnregister: (result) {
              if (result.isOk()) {
                final userService = result.unwrap();
                // ignore: void_checks
                return Future.value(userService.dispose().unwrap());
              }
              return null;
            },
          )
          .end;
      print('UserService registered');
    });

    // Wait for the service to be registered
    final userService = await userServiceFuture;

    // Use the service
    final userDataResult = await userService.getUserData().value;
    if (userDataResult.isOk()) {
      print('User data: ${userDataResult.unwrap()}');
    }

    // Unregister the service (triggers dispose via onUnregister)
    final _ = await DI.global.unregister<UserService>().value;
    print('UserService unregistered\n');
  }

  // --- Part 2: Service Lifecycle with CounterService ---
  print('--- Part 2: Service Lifecycle ---');

  // Register CounterService with lifecycle callbacks
  DI.global.register<CounterService>(
    CounterService(),
    onRegister: (service) => service.init(),
    onUnregister: ServiceMixin.unregister,
  );

  // Wait for initialization to complete
  final counterService = await DI.global.untilSuper<CounterService>().unwrap();

  // Use the service
  counterService.increment();
  counterService.increment();
  counterService.increment();
  print('Current count: ${counterService.count}');

  // Demonstrate pause/resume
  await counterService.pause().value;
  await counterService.resume().value;

  // Unregister (triggers dispose via ServiceMixin.unregister)
  await DI.global.unregister<CounterService>().value;
  print('CounterService unregistered\n');

  // --- Part 3: Hierarchical Containers ---
  print('--- Part 3: Hierarchical Containers ---');

  // Register in session container
  DI.session.register<String>('session_token_123');

  // Access from user container (child of session)
  final token = DI.user<String>();
  print('Token from DI.user: $token');

  // Check registration
  print(
    'Is String registered in DI.session? ${DI.session.isRegistered<String>()}',
  );
  print('Is String registered in DI.user? ${DI.user.isRegistered<String>()}');

  // Clean up
  DI.session.unregister<String>();

  print('\n=== Example Complete ===');
}
