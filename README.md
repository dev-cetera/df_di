<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img align="right" src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="48"></a>
<a href="https://discord.gg/gEQ8y2nfyX" target="_blank"><img align="right" src="https://raw.githubusercontent.com/dev-cetera/resources/refs/heads/main/assets/icons/discord_icon/discord_icon.svg" height="48"></a>

Dart & Flutter Packages by dev-cetera.com & contributors.

[![sponsor](https://img.shields.io/badge/sponsor-grey?logo=github-sponsors)](https://github.com/sponsors/dev-cetera)
[![patreon](https://img.shields.io/badge/patreon-grey?logo=patreon)](https://www.patreon.com/c/RobertMollentze)
[![pub](https://img.shields.io/pub/v/df_di.svg)](https://pub.dev/packages/df_di)
[![tag](https://img.shields.io/badge/tag-v0.15.0-purple?logo=github)](https://github.com/dev-cetera/df_di/tree/v0.15.0)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/dev-cetera/df_di/main/LICENSE)

---

<!-- BEGIN _README_CONTENT -->

`df_di` is a lightweight, powerful "dependency injection" package for Dart and Flutter that makes your app modular, testable, and easy to maintain. It stops the confusion of finding and tracking services, like APIs or databases. With `df_di`, you store these services in "containers" that make them easy to access whenever you need them.

Why choose `df_di`? It’s inspired by [get_it](https://pub.dev/packages/get_it) but adds better type safety via monads provided by [df_safer_dart](https://pub.dev/packages/df_safer_dart), more robust async support, better debuggability and a very powerful `until` function that waits for dependencies to be ready, and much more. Whether you’re building a small Flutter app or a large-scale project, `df_di` keeps your code clean and your dependencies accessible.

## Quick Start: Managing a User Service

Let’s dive into a real-world example: managing a `UserService` that fetches user data. This shows how **df_di** containers shine in a Flutter app.

### Step 1: Create a User Service

```dart
class UserService {
  Future<String> getUserName() async {
    // Simulate fetching user data
    await Future.delayed(Duration(seconds: 1));
    return 'Alice';
  }

  Future<void> logOut() async {
    // Simulate the logout process.
    await Future.delayed(Duration(seconds: 1));
  }
}
```

### Step 2: Register the Service in a Container

Use a container to store the `UserService`. Here, we’ll put it in `DI.global` for app-wide access.

```dart
import 'package:df_di/df_di.dart';

void main() {
  // Register the UserService in the global container
  DI.global.register<UserService>(
    UserService(),
    onUnregister: (result) => result.unwrap().logOut(),
  );
}
```

- **`DI.global`**: A built-in container for app-wide dependencies.
- **`register<UserService>`**: Stores the `UserService` instance, tagged by its type.

### Step 3: Access the Service Anywhere

Retrieve the `UserService` from the container and use it in your Flutter widget.

```dart
import 'package:flutter/material.dart';

class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: DI.global<UserService>().getUserName(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        return Text('Welcome, ${snapshot.data ?? 'Guest'}!');
      },
    );
  }
}
```

- **`DI.global<UserService>()`**: Grabs the `UserService` from the container.
- The widget uses the service to fetch and display the user’s name.

This is the quick way, but it assumes the service exists. Let’s see a safer approach.

## Step 4: Safe Dependency Access

To avoid crashes if a dependency is missing, use `getSyncOrNone`:

```dart
void showUser() {
  final maybeService = DI.global.getSyncOrNone<UserService>();
  if (maybeService.isSome()) {
    print('Service found: ${maybeService.unwrap()}');
  } else {
    print('No UserService registered.');
  }
}
```

- **`getSyncOrNone<UserService>()`**: Returns `Some<UserService>` if found, or `None` if not.
- This prevents errors and lets you handle missing dependencies gracefully.

## Step 5: Hierarchical Containers

**df_di**’s containers can form a hierarchy, letting you scope dependencies. Built-in containers include:

- **`DI.global`**: For app-wide services (e.g., `UserService`).
- **`DI.session`**: For session-specific data (e.g., a logged-in user’s ID).
- **`DI.user`**: For user-specific data.

Child containers inherit from parents. Here’s an example:

```dart
void setupSession() {
  // Register a session ID in the session container
  DI.session.register<String>('session_123');

  // Access it from the user container
  final sessionId = DI.user<String>();
  print(sessionId); // Outputs: session_123
}
```

- **`DI.user`**: A child of `DI.session`, which is a child of `DI.global`.
- If `DI.user` doesn’t have a `String`, it checks `DI.session`, then `DI.global`.

You can also create custom hierarchies:

```dart
final featureContainer = DI();
final screenContainer = DI(parent: featureContainer);

featureContainer.register<String>('Feature data');
print(screenContainer<String>()); // Outputs: Feature data
```

## Step 6: Handling Async Dependencies

Need a dependency that’s not ready yet, like user data from an API? Wait for it with `untilSuper`:

```dart
Future<void> waitForService() async {
  // If UserService isn't registered yet, it will just wait until it finds one.
  // IMPORTANT: When using this function, make sure that XXX in untilSuper<XXX> is the
  // super-most class or matches the exact type registered. In the case of UserService,
  // this satisfies the requirement.
  final service = await DI.global.untilSuper<UserService>().unwrap();
  print(await service.getUserName()); // Outputs: Alice
}
```

- **`untilSuper<UserService>()`**: Waits until a `UserService` is registered in the container or its parents.
- Perfect for Flutter’s `FutureBuilder` to display data once it’s available.

## Step 7: Lazy Initialization

Save resources by registering dependencies that only create when needed:

```dart
DI.global.registerConstructor(UserService.new);

// This will create a new instance each time.
final a = DI.global.getLazySingletonSyncOrNone<UserService>(); // Created only now
final b = DI.global.getLazySingletonSyncOrNone<UserService>(); // NOT created again
print(a.unwrap() == b.unwrap()); // Outputs: true

// This will create a new instance each time.
final c = DI.global.getLazyFactorySyncOrNone<UserService>();
final d = DI.global.getLazyFactorySyncOrNone<UserService>();
print(c.unwrap() == d.unwrap()); // Outputs: false
```

- **`registerConstructor`**: The `UserService` is built only when first requested.

## Step 8: Cleaning Up

Remove dependencies when they’re no longer needed:

```dart
DI.session.register<String>('Temporary data');
DI.session.unregister<String>();

print(DI.session.isRegistered<String>()); // Outputs: true
```

You can also remove all dependencies all at once, i.e. when you log the user out of a session:

```dart
// This will unregister all dependencies in the reverse order by which they were registered.
DI.session.unregisterAll();
```

<!-- END _README_CONTENT -->

---

☝️ Please refer to the [API reference](https://pub.dev/documentation/df_di/) for more information.

---

## 💬 Contributing and Discussions

This is an open-source project, and we warmly welcome contributions from everyone, regardless of experience level. Whether you're a seasoned developer or just starting out, contributing to this project is a fantastic way to learn, share your knowledge, and make a meaningful impact on the community.

### ☝️ Ways you can contribute

- **Buy me a coffee:** If you'd like to support the project financially, consider [buying me a coffee](https://www.buymeacoffee.com/dev_cetera). Your support helps cover the costs of development and keeps the project growing.
- **Find us on Discord:** Feel free to ask questions and engage with the community here: https://discord.gg/gEQ8y2nfyX.
- **Share your ideas:** Every perspective matters, and your ideas can spark innovation.
- **Help others:** Engage with other users by offering advice, solutions, or troubleshooting assistance.
- **Report bugs:** Help us identify and fix issues to make the project more robust.
- **Suggest improvements or new features:** Your ideas can help shape the future of the project.
- **Help clarify documentation:** Good documentation is key to accessibility. You can make it easier for others to get started by improving or expanding our documentation.
- **Write articles:** Share your knowledge by writing tutorials, guides, or blog posts about your experiences with the project. It's a great way to contribute and help others learn.

No matter how you choose to contribute, your involvement is greatly appreciated and valued!

### ☕ We drink a lot of coffee...

If you're enjoying this package and find it valuable, consider showing your appreciation with a small donation. Every bit helps in supporting future development. You can donate here: https://www.buymeacoffee.com/dev_cetera

<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="40"></a>

## 🧑‍⚖️ License

This project is released under the [MIT License](https://raw.githubusercontent.com/dev-cetera/df_di/main/LICENSE). See [LICENSE](https://raw.githubusercontent.com/dev-cetera/df_di/main/LICENSE) for more information.

