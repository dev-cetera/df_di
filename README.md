<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img align="right" src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="48"></a>
<a href="https://discord.gg/gEQ8y2nfyX" target="_blank"><img align="right" src="https://raw.githubusercontent.com/dev-cetera/resources/refs/heads/main/assets/discord_icon/discord_icon.svg" height="48"></a>

Dart & Flutter Packages by dev-cetera.com & contributors.

[![Pub Package](https://img.shields.io/pub/v/df_di.svg)](https://pub.dev/packages/df_di)
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/dev-cetera/df_di/main/LICENSE)

---

## Summary

Efficiently structure and manage the essential dependencies of your code, such as services, data, and utilities. This package helps you organize and access these dependencies using containers that store and provide them when needed, making your app more adaptable, testable, maintainable, and easier to debug.

Inspired by [get_it](https://pub.dev/packages/get_it/), it offers a flexible, faster solution with enhanced async handling, support for retrieving dependencies by runtime or generic type, and a hierarchical container structure. This approach allows nested child containers that inherit from parent containers, all while providing clearer, more concise documentation.

For a full feature set, please refer to the [API reference](https://pub.dev/documentation/df_di/).

## Use Case 1

Your app probably contains classes that act as managers, helpers, or services, for example:

```dart
class UserManager {
  final String uid;
  const UserManager(this.uid);

  String? _userName;
  String get userName => _userName ?? 'Guest';

  Future<void> loadUserData() async {
    // TODO: Implement functionality to load user data here.
    _userName = 'John Doe'; // Example of loaded data

  }
}
```

You can register dependencies like the `UserManager` above in the dedicated `DI.session` container. This container is one of many pre-defined containers you can use and is specifically intended to store dependencies that should persist throughout the app’s session (from login to logout):

```dart
Future<void> logIn() async {
  // TODO: Log in and get the current user's uid.
  final userManger = UserManager(uid);
  await userManger.loadUserData();
  // Register the UserManager in the session container once loaded.
  DI.session.register<UserManager>(userManager);
}
```

You can now use the `until` method that will only complete with an instance of `UserManager` once one has been registered in the `DI.session` container:

```dart
Widget build(BuildContext contect) {
  return FutureBuilder<UserManager>(
    future:  DI.session.until<UserManager>(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator();
      } else if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      } else {
        return Text('Hello, ${snapshot.data?.userName}');
      }
    },
  );
}
```

Upon logging out, the `DI.session` ssion container can be cleared and reset for future use. Dependencies are unregistered in the reverse order of their registration, ensuring proper resource cleanup:

```dart
Future<void> logOut() async {
  // TODO: Log out the user.r
  DI.session.unregisterAll();
}
```

## Use Case 2

Define a custom type to hold a `String` representing the getConfig API endpoint URL. Avoid registering types like `String` or `Map` in a container, as doing so introduces ambiguity about what will be retrieved.

```dart
class GetConfigEndpointUrl {
  final String value;
  const GetConfigEndpointUrl(this.value);
}

void setupEndpoints() {
  DI.global.register<GetConfigEndpointUrl>(
    GetConfigEndpointUrl('https://api.example.com/getConfig'),
  );
}
```

Define a class that is responsible for loading configuration data from the endpoint provided by `ConfigApiEndpointUrl`.

```dart
class ConfigManager {
  Map<String, dynamic> _data = {};
  Map<String, dynamic> get data => _data;

  Future<void> loadDataFromApi() async {
      // Don't proceed until ConfigApiEndpointUrl is registered.
      final endpointUrl = (await DI.global.until<ConfigApiEndpointUrl>()).value;
      // TODO: Get the data from the API...
      _data = {'latestVersion': '1.2.3+4'}; // Example of data from API.
  }

  String? get latestVersion => _data['latestVersion'] as String?;
}
```

Configure the app using the provided API and register the `ConfigManager`. This can only be done once thanks to the `isRegistered` check.

```dart
Future<void> configure() {
  if (!isRegistered<ConfigManager>()) {
    final configManager = ConfigManager();
    await configManager.loadDataFromApi();
    DI.global.register<ConfigManager>(configManager);
  }
}
```

If you’re confident that `ConfigManager` is already registered in the container, you can fetch it directly. Otherwise, check with `isRegistered` or use the `until` method.

```dart
Future<void> doStuff() async {
  final configManager = DI.global<ConfigManager>().latestVersion;
}
```

## Quickstart

### Store a dependency in a container:

```dart
// Access the global DI instance anywhere in your app.
DI.global;

// Or create your own DI container.
final di = DI();

// Create nested child containers, useful for scoping dependencies in modular apps.
final scopedDi = di.child().child().child(groupEntity: Entity('moduleGroup'));
```

```dart
// Access the global DI instance anywhere in your app.
DI.global;

// Or create your own DI container.
final di = DI();

// Create nested child containers, useful for scoping dependencies in modular apps.
final scopedDi = di.child().child().child(groupEntity: Entity('moduleGroup'));
```

### Registering Dependencies:

```dart
// Register the answer to life, the universe and everything.
di.register<int>(42);

// Register an integer under a specific groupEntity, useful in environments like testing.
di.register<int>(0, groupEntity: Entity.testGroup);

// Register a Future as a dependency.
di.register(Future.value('Hello, DI!'));
print(di.get<String>()); // Instance of 'Future<String>'

// Register a factory or lazy singleton constructor.
int n = 0;
di.registerLazy<int>(() => n + 1);
di.registerLazy(() => DateTime.now());
```

### Unregistering Dependencies:

```dart
// Unregister a specific type.
  di.unregister<int>();
  di.unregisterT(int);

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
print(di.getT(intType)); // 42

// Retrieve a dependency registered under a specific groupEntity.
print(di.get<int>(groupEntity: Entity('testGroup'))); // 0

// Handle asynchronous dependencies.
final greeting = await di.get<String>();
print(greeting); // Hello, DI!

// Retrieve a factory-registered dependency.
final now = di.getFactory<DateTime>();
print(now); // Current timestamp
await Future.delayed(Duration(seconds: 1));
final now1 = di.getFactoryT(DateTime);
print(now1);  // A second later
```

### Real-World Example - UserService:

```dart
final class UserService extends Service {
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
di.registerService(UserService.new);

// Access the service.
final userService = await di.getServiceSingleton<UserService>();
print(userService.userName.value); // John Doe
```

### Handling Synchronous and Asynchronous Services:

#### Service with Synchronous Initialization and Asynchronous Disposal

```dart
final class SyncInitAsyncDisposeService extends Service {
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
di.registerService(SyncInitAsyncDisposeService.new);
final service = di.getServiceSingleton<SyncInitAsyncDisposeService>();
await di.unregister<SyncInitAsyncDisposeService>();
```

#### Service with Asynchronous Initialization and Synchronous Disposal

```dart
final class AsyncInitSyncDisposeService extends Service {
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
di.registerService(AsyncInitSyncDisposeService.new);
final service = await di.getServiceSingleton<AsyncInitSyncDisposeService>();
di.unregister<AsyncInitSyncDisposeService>();
```

### Getting the State for Debugging:

```dart
// Print the current state of the DI container.
print(di.registry.state);

// Check if a specific type is registered.
print(di.isRegistered<int>()); // true
```

---

<!-- <a href="https://medium.com/@dev-cetera" target="_blank"><img src="https://raw.githubusercontent.com/dev-cetera/resources/refs/heads/main/assets/medium_logo/medium_logo.svg" height="20"></a>

[Dependency Injection Tutorial for Flutter]() - This article explains what Dependency Injection (DI) is and how to use it effectively in Flutter, improving code structure and testability by decoupling components.

[State Management Done Right in Flutter]() - This article covers showcases techniques to manage app state efficiently and ensuring scalability and maintainability. -->

## Contributing and Discussions

This is an open-source project, and we warmly welcome contributions from everyone, regardless of experience level. Whether you're a seasoned developer or just starting out, contributing to this project is a fantastic way to learn, share your knowledge, and make a meaningful impact on the community.

### Ways you can contribute

- **Buy me a coffee:** If you'd like to support the project financially, consider [buying me a coffee](https://www.buymeacoffee.com/dev_cetera). Your support helps cover the costs of development and keeps the project growing.
- **Find us on Discord:** Feel free to ask questions and engage with the community here: https://discord.gg/gEQ8y2nfyX.
- **Share your ideas:** Every perspective matters, and your ideas can spark innovation.
- **Help others:** Engage with other users by offering advice, solutions, or troubleshooting assistance.
- **Report bugs:** Help us identify and fix issues to make the project more robust.
- **Suggest improvements or new features:** Your ideas can help shape the future of the project.
- **Help clarify documentation:** Good documentation is key to accessibility. You can make it easier for others to get started by improving or expanding our documentation.
- **Write articles:** Share your knowledge by writing tutorials, guides, or blog posts about your experiences with the project. It's a great way to contribute and help others learn.

No matter how you choose to contribute, your involvement is greatly appreciated and valued!

### We drink a lot of coffee...

If you're enjoying this package and find it valuable, consider showing your appreciation with a small donation. Every bit helps in supporting future development. You can donate here: https://www.buymeacoffee.com/dev_cetera

<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="40"></a>

## License

This project is released under the MIT License. See [LICENSE](https://raw.githubusercontent.com/dev-cetera/df_type/main/LICENSE) for more information.
