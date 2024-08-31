# Dart Package Template

<a href="https://www.buymeacoffee.com/robmllze" target="_blank"><img align="right" src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>

Dart & Flutter Packages by DevCetra.com & contributors.

[![Pub Package](https://img.shields.io/pub/v/df_di.svg)](https://pub.dev/packages/df_di)
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/robmllze/df_di/main/LICENSE)

---

## Summary

A flexible dependency injection (DI) package with Service classes to assist with state management. This package does not aim to replace existing DI solutions like [get_it](https://pub.dev/packages/get_it) but offers an alternative that integrates seamlessly with the other [DF packages](https://pub.dev/publishers/devcetra.com/packages).

## Features

- Extensive use of `FutureOr`, making it easy to work with synchronous and asynchronous dependencies.
- Register dependencies under a type and key, allowing for multiple dependencies of the same type.
- Lazy singleton and factory dependency registration.
- Abstract Service classes that integrate seamlessly.
- Well written comments for easy understanding.

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

### Registering a Dependency:

```dart
// Register a dependency under type "int" and defaultKey.
di.register<int>(1);
print(DIKey.defaultKey);

// Register a dependency under type "int" also but with a different key.
di.register(2, key: const DIKey('second'));

// Register a Future.
di.register<double>(Future.value(3.0));
```

### Unregistering a Dependency:

```dart
di.unregister<String>(); // Throws an error because there is no dependency registered under type "String".
```

### Getting a Dependency:

```dart
// Getting a dependency under type "int" and defaultKey.
print(di<int>()); // prints 1

// Register a dependency under type "int" also but with a different key.
print(di.get<int>(const DIKey('second'))); // prints 2

print(await di.get<double>()); // prints 3.0.
```

### Creating a new Service:

```dart
class FooBarService extends DisposableService {
  // Provide Points of Data (PODs) for the UI to consume, like ValueNotifiers or Streams.
  ValueListenable<String?> get vFooBar => _vFooBar;
  final _vFooBar = ValueNotifier<String?>(null);

  @override
  FutureOr<void> onInitService() async {
    _vFooBar.value = 'FooBar';
    // Put initialization logic here, like starting Streams. Update the PODs as
    // needed to notify the UI of changes.
  }

  @override
  FutureOr<void> onDispose() {
    _vFooBar.dispose();
    // Put cleanup logic here, like disposing resources and canceling Streams.
  }
}
```

### Registering and Using a Singleton Service:

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

```dart
di.registerSingletonService(SyncServiceExmple.new);
print(di.get<SyncServiceExmple>() is Future); // false
print(di.getSync<SyncServiceExmple>());  // use getSync/getSyncOrNull if you expect a sync

class SyncServiceExmple extends DisposableService {
  @override
  void onInitService() {}

  @override
  void onDispose() {}
}
```

### Creating an Async Service:

```dart
di.registerSingletonService(AsyncServiceExample.new);
print(di.get<AsyncServiceExample>() is Future); // true
print(di.getAsync<SyncServiceExmple>()); // use getAsync/getAsyncOrNull if you expect an async

class AsyncServiceExample extends DisposableService {
  @override
  Future<void> onInitService() async {
    await Future<void>.delayed(
      const Duration(seconds: 3),
    );
  }

  @override
  Future<void> onDispose() async {}
}
```


### Getting the State of the DI instance:

```dart
// Print the current state of di to understand what's registered.
print(di.registry.state);
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
- **Help clarify documentation:** Good documentation is key to accessibility. You can make it easier for others to get started by improving or expanding our documentation.
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
