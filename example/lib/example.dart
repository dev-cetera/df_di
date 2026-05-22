// This example demonstrates dependency injection with df_di.

import 'dart:io' show stdout;

import 'package:df_di/df_di.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void _say(Object? message) => stdout.writeln(message);

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Example 1: A simple service class to demonstrate DI registration.
class UserService {
  UserService(this.id);

  final int id;
  bool _isDisposed = false;

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
      _say('UserService disposed');
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
    _say('Count incremented to: $_count');
  }

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) {
    return [
      (_) {
        _count = 0;
        _say('CounterService initialized');
        return syncUnit();
      },
    ];
  }

  @override
  TServiceResolvables<Unit> providePauseListeners(void _) {
    return [
      (_) {
        _say('CounterService paused');
        return syncUnit();
      },
    ];
  }

  @override
  TServiceResolvables<Unit> provideResumeListeners(void _) {
    return [
      (_) {
        _say('CounterService resumed');
        return syncUnit();
      },
    ];
  }

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) {
    return [
      (_) {
        _say('CounterService disposed with final count: $_count');
        return syncUnit();
      },
    ];
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Future<void> main() async {
  _say('=== df_di Example ===\n');

  // --- Part 1: Basic DI with UserService ---
  _say('--- Part 1: Basic DI Registration ---');

  // Create a future that waits for UserService to be registered.
  UNSAFE:
  final userServiceFuture = DI.global.untilSuper<UserService>().unwrap();

  // Register the service after a delay (simulating async initialization).
  Future<void>.delayed(const Duration(seconds: 1), () {
    DI.global
        .register<UserService>(
          UserService(123),
          onUnregister: Some((result) async {
            if (result.isOk()) {
              UNSAFE:
              (await result.unwrap().dispose().value).end();
            }
          }),
        )
        .end();
    _say('UserService registered');
  });

  final userService = await userServiceFuture;

  final userDataResult = await userService.getUserData().value;
  if (userDataResult.isOk()) {
    UNSAFE:
    _say('User data: ${userDataResult.unwrap()}');
  }

  (await DI.global.unregister<UserService>().value).end();
  _say('UserService unregistered\n');

  // --- Part 2: Service Lifecycle with CounterService ---
  _say('--- Part 2: Service Lifecycle ---');

  DI.global
      .register<CounterService>(
        CounterService(),
        onRegister: Some((service) => service.init()),
        onUnregister: const Some(ServiceMixin.unregister),
      )
      .end();

  UNSAFE:
  final counterService = await DI.global.untilSuper<CounterService>().unwrap();

  counterService.increment();
  counterService.increment();
  counterService.increment();
  _say('Current count: ${counterService.count}');

  (await counterService.pause().value).end();
  (await counterService.resume().value).end();

  (await DI.global.unregister<CounterService>().value).end();
  _say('CounterService unregistered\n');

  // --- Part 3: Hierarchical Containers ---
  _say('--- Part 3: Hierarchical Containers ---');

  DI.session.register<String>('session_token_123').end();

  // Access from user container (child of session).
  final token = DI.user<String>();
  _say('Token from DI.user: $token');

  _say(
    'Is String registered in DI.session? ${DI.session.isRegistered<String>()}',
  );
  _say('Is String registered in DI.user? ${DI.user.isRegistered<String>()}');

  DI.session.unregister<String>().end();

  _say('\n=== Example Complete ===');
}
