# DF - DI (Dependency Injection)

<a href="https://www.buymeacoffee.com/robmllze" target="_blank"><img align="right" src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>

Dart & Flutter Packages by DevCetra.com & contributors.

[![Pub Package](https://img.shields.io/pub/v/df_di.svg)](https://pub.dev/packages/df_di)
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/robmllze/df_di/main/LICENSE)

---

## Summary

This package offers a powerful and versatile dependency injection system along with service classes for easy state management.

## Features

- Robust support for `FutureOr`, facilitating seamless handling of both synchronous and asynchronous dependencies and callbacks.
- Ability to register dependencies using both “type” and “group”, enabling the management of multiple dependencies of the same type.
- 
- Supports standard features like factory dependencies and lazy initialization for singleton dependencies.
- Abstract service classes that integrate effortlessly with your application.
- Clear and comprehensive documentation for easy understanding.
- Code snippets for Visual Studio Code [here](https://raw.githubusercontent.com/robmllze/df_di/main/.vscode/snippets.code-snippets).

For a full feature set, please refer to the [API reference](https://pub.dev/documentation/df_di/).

## Quickstart

### Creating a DI instance:

```dart
// Access the global DI instance from anywhere in your app.
di;
DI.global;

// Or create a local DI instance.
final local = DI.newInstance();
```

### Registering Dependencies:

```dart
// Register a dependency under type "int" and defaultKey.
di.register<int>(1);
print(Identifier.defaultId);

// Register a dependency under type "int" also but with a different group.
di.register(2, group: const DIKey('second'));

// Register a Future.
di.register<double>(Future.value(3.0));

int counter = 0;
di.registerSingleton<int>(() => ++counter), group: const DIKey('singleton-counter'));
di.registerFactory<int>(() async => ++counter, group: const DIKey('factory-counter'));
```

### Unregistering Dependencies:

```dart
// Throws an error because there is no dependency registered under type "String".
FutureOr<void> futureOr = di.unregister<String>();

// Unregister all dependencies in the reverse order of their registration, effectively resetting the instance di.
futureOr = di.unregisterAll();
```

### Getting Dependencies:

```dart
// Getting a dependency under type "int" and defaultKey.
FutureOr<void> futureOr = di<int>();
print(futureOr); // prints 1

// Register a dependency under type "int" also but with a different group.
print(di.get<int>(const DIKey('second'))); // prints 2

print(await di.get<double>()); // prints 3.0.

print(await di.getFactory<double>(group: const DIKey('factory-counter'))); // prints 1.
print(await di.getFactory<double>(group: const DIKey('factory-counter'))); // prints 2.
print(await di.get<double>(group: const DIKey('factory-counter'))); // prints 3.
print(await di.get<double>(group: const DIKey('factory-counter'))); // prints 4.
```

### Creating a new Singleton Service:

```dart
final class FooBarService extends Service {
  // Provide objects that the UI can consume, like ValueNotifiers or Streams, etc.
  ValueListenable<String?> get vFooBar => _vFooBar;
  final _vFooBar = ValueNotifier<String?>(null);

  @override
  FutureOr<void> onInitService() async {
    _vFooBar.value = 'FooBar';
    // Put initialization logic here, like starting Streams.
  }

  // Always called when unregistering a service.
  @override
  FutureOr<void> onDispose() {
    _vFooBar.dispose();
    // Put cleanup logic here, like disposing resources and canceling Streams.
  }
}
```

### Registering and Using Singleton Services:

```dart
// Register FooBarService as a lazy singleton.
di.registerSingletonService(FooBarService.new);

// Initialize the service, get it, and use it.
final fooBarService1 = await di.get<FooBarService>();
final fooBarService2 = di.get<FooBarService>();
print(fooBarService1 == fooBarService2); // prints true

print(fooBarService.vFooBar.value); // prints "FooBar"
```

### Creating a Sync Service:

Notice how onInitService isn't a Future. This means that DI will treat it as sync.

```dart
final class SyncServiceExmple extends Service {
  @override
  void onInitService() {}

  // Always called when unregistering a service.
  @override
  void onDispose() {}
}

di.registerSingletonService(SyncServiceExmple.new);

// Use get that returns FutureOr<T> if you don't know what to expect.
print(await di.get<SyncServiceExmple>() is Future); // false

// Use call/getSync/getSyncOrNull if you expect a sync.
print(di<SyncServiceExmple>());
print(di.getSync<SyncServiceExmple>());
print(di.getSyncOrNull<SyncServiceExmple>());
```

### Creating an Async Service:

Notice how onInitService is a Future. This means that DI will treat it as async.

```dart
final class AsyncServiceExample extends Service {
  @override
  Future<void> onInitService() async {
    await Future<void>.delayed(
      const Duration(seconds: 3),
    );
  }

  // Always called when unregistering a service.
  @override
  Future<void> onDispose() async {}
}

di.registerSingletonService(AsyncServiceExample.new);

// Use get that returns FutureOr<T> if you don't know what to expect.
print(await di.get<AsyncServiceExample>() is Future); // true

 // Use getAsync or getAsyncOrNull if you expect an async.
print(await di.getAsync<AsyncServiceExample>());
print(await di.getAsyncOrNull<AsyncServiceExample>());
```

### Getting the State for Debugging:

```dart
// Print the current state of di to understand what's registered.
print(di.registry.state);

// Check if there's a dependency under "int" and Identifier.defaultId.
print(di.isRegistered<int>());
print(di.registry.getDependency<T>() != null);

// Check how the dependency under "String" and Identifier.defaultId got initially registered.
di.registerFactory<String>(() => 'Hello World');
print(di<String>()); // prints "Hello World".
print(registrationType<String>()); // prints" FactoryInst<String>"

// Print the registration index of dependency under "int" and Identifier.defaultId.
print(di.registrationIndex<int>());
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
