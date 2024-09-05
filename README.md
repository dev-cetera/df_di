# DI

<a href="https://www.buymeacoffee.com/robmllze" target="_blank"><img align="right" src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>

Dart & Flutter Packages by DevCetra.com & contributors.

[![Pub Package](https://img.shields.io/pub/v/df_di.svg)](https://pub.dev/packages/df_di)
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/robmllze/df_di/main/LICENSE)

---

## Summary

This package provides a powerful and flexible dependency injection (DI) system, coupled with service classes for seamless state management in Dart.

## Features

- Robust FutureOr support for handling both synchronous and asynchronous dependencies and callbacks.
- Register dependencies by type and group, enabling management of multiple dependencies of the same type.
- Hierarchical DI with scoped dependencies through child containers.
- Retrieve dependencies by runtime type or generic type.
- Factory dependencies and lazy initialization for singleton dependencies.
- Service classes that automatically handle cleanup when they are unregistered.

For a full feature set, please refer to the [API reference](https://pub.dev/documentation/df_di/).

## Quickstart

### Creating a DI container:

```dart
// Access the global DI instance anywhere in your app.
DI.global;

// Or create your own DI container.
final di = DI();

// Create nested child containers, useful for scoping dependencies in modular apps.
final scopedDi = di.child().child().child(group: Gr('moduleGroup'));
```

### Registering Dependencies:

```dart
// Register the answer to life, the universe and everything.
di.register<int>(42);

// Register an integer under a specific group, useful in environments like testing.
di.register<int>(0, group: Gr.testGroup);

// Register a Future as a dependency.
di.register(Future.value('Hello, DI!'));
print(di.get<String>()); // Instance of 'Future<String>'

// Register a singleton that lazily initializes. The result will always be 1.
int n = 0;
di.registerLazySingleton<int>(() => n + 1);

// Register a factory that returns a new instance each time.
di.registerFactory(() => DateTime.now());
```

### Unregistering Dependencies:

```dart
// Unregister a specific type.
di.unregister<int>();
Type intType = int;
di.unregisterUsingRuntimeType(intType);

// Unregister all dependencies, resetting the container.
di.unregisterAll();

// Unregister child containers when they’re no longer needed.
di.unregisterChild();
```

### Getting Dependencies:

```dart
// Retrieve a registered integer dependency.
print(di<int>()); // 42
Type intType = int;
print(di.getUsingRuntimeType(intType)); // 42

// Retrieve a dependency registered under a specific group.
print(di.get<int>(group: Gr('testGroup'))); // 0

// Handle asynchronous dependencies.
final greeting = await di.get<String>();
print(greeting); // Hello, DI!

// Retrieve a factory-registered dependency.
final now = di.getFactory<DateTime>();
print(now); // Current timestamp
await Future.delayed(Duration(seconds: 1));
final now1 = di.getFactoryUsingRuntimeType(DateTime);
print(now1);  // A second later
```

### Real-World Example - UserService:

```dart
final class UserService extends Service<Object> {
  final _userName = ValueNotifier<String>('Guest');

  // Getter for the UI to consume.
  ValueListenable<String> get userName => _userName;

  @override
  Future<void> onInitService(_) async {
    // Simulate loading user data.
    await Future.delayed(Duration(seconds: 2));
    _userName.value = 'John Doe';
  }

  @override
  void onDispose() {
    _userName.dispose(); // Cleanup resources.
  }
}

// Register the service.
di.registerLazySingletonService(UserService.new);

// Access the service.
final userService = await di.get<UserService>();
print(userService.userName.value); // John Doe
```

### Handling Synchronous and Asynchronous Services:

#### Service with Synchronous Initialization and Asynchronous Disposal

```dart
final class SyncInitAsyncDisposeService extends Service<Object> {
  // di<SyncInitAsyncDisposeService>() will not return a Future.
  @override
  void onInitService(_) {
    // Synchronous initialization logic
  }

  // di.unregister<SyncInitAsyncDisposeService>() will return a Future.
  @override
  Future<void> onDispose() async {
    // Asynchronous cleanup logic
  }
}

// Register and use the service.
di.registerLazySingletonService(SyncInitAsyncDisposeService.new);
final service = di.get<SyncInitAsyncDisposeService>();
await di.unregister<SyncInitAsyncDisposeService>();
```

#### Service with Asynchronous Initialization and Synchronous Disposal

```dart
final class AsyncInitSyncDisposeService extends Service<Object> {
  // di<AsyncInitSyncDisposeService>() will not return a Future.
  @override
  Future<void> onInitService(_) async {
    await Future.delayed(Duration(seconds: 3));
    // Asynchronous initialization logic
  }

  // di.unregister<AsyncInitSyncDisposeService>() will not return a Future.
  @override
  void onDispose() {
    // Synchronous cleanup logic
  }
}

// Register and use the service.
di.registerLazySingletonService(AsyncInitSyncDisposeService.new);
final service = await di.get<AsyncInitSyncDisposeService>();
di.unregister<AsyncInitSyncDisposeService>();
```

### Getting the State for Debugging:

```dart
// Print the current state of the DI container.
print(di.registry.state);

// Check if a specific type is registered.
print(di.isRegistered<int>()); // true

// Inspect how a dependency was registered.
print(di.registrationType<String>()); // FactoryInst<String>
```

## Installation

Use this package as a dependency by adding it to your `pubspec.yaml` file (see [here](https://pub.dev/packages/df_di/install)).

---

## Contributing and Discussions

This is an open-source project, and we warmly welcome contributions from everyone, regardless of experience level. Whether you're a seasoned developer or just starting out, contributing to this project is a fantastic way to learn, share your knowledge, and make a meaningful impact on the community.

### Ways you can contribute:

- **Buy me a coffee:** If you'd like to support the project financially, consider [buying me a coffee](https://www.buymeacoffee.com/robmllze). Your support helps cover the costs of development and keeps the project growing.
- **Share your ideas:** Every perspective matters, and your ideas can spark innovation.
- **Report bugs:** Help us identify and fix issues to make the project more robust.
- **Suggest improvements or new features:** Your ideas can help shape the future of the project.
- **Help clarify documentation:** Good documentation is group to accessibility. You can make it easier for others to get started by improving or expanding our documentation.
- **Write articles:** Share your knowledge by writing tutorials, guides, or blog posts about your experiences with the project. It's a great way to contribute and help others learn.

No matter how you choose to contribute, your involvement is greatly appreciated and valued!

---

### Chief Maintainer:

📧 Email _Robert Mollentze_ at robmllze@gmail.com

### Dontations:

If you're enjoying this package and find it valuable, consider showing your appreciation with a small donation. Every bit helps in supporting future development. You can donate here:

https://www.buymeacoffee.com/robmllze

---

## License

This project is released under the MIT License. See [LICENSE](https://raw.githubusercontent.com/robmllze/df_di/main/LICENSE) for more information.
