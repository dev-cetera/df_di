//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/src/_internal.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
abstract interface class RegisterIface {
  /// Registers the [value] under type [T] and the specified [group], or
  /// under [Gr.defaultGroup] if no group is provided.
  ///
  /// Optionally provide an [onUnregister] callback to be called on [unregister].
  ///
  /// Throws [DependencyAlreadyRegisteredException] if a dependency with the
  /// same type [T] and [group] already exists.
  ///
  /// Consider passing [FactoryInst] or [SingletonInst] as the [value]. These
  /// types trigger a special behavious witin this class:
  ///
  /// - [FactoryInst] Creates a new instance each time [get] is called.
  /// - [SingletonInst] Creates a single instance the first time [get] is called
  /// and returns the same instance for all subsequent calls.
  ///
  /// Consider the following example:
  ///
  /// ```dart
  /// // Example.
  ///  var i = 0;
  ///  di.register(i);
  ///  i++;
  ///  print(di.get<int>()); // prints 0
  ///  di.unregister<int>();
  ///  di.register(SingletonInst<int>(() => ++i));
  ///  print(di.get<int>()); // prints 2
  ///  print(di.get<int>()); // prints 2 again
  ///  di.unregister<int>();
  ///  di.register(Factory<int>(() => ++i));
  ///  print(di.get<int>()); // prints 3
  ///  print(di.get<int>()); // prints 4
  ///  print(di.get<int>()); // prints 5
  /// ```
  void register<T extends Object>(
    FutureOr<T> value, {
    Gr? group,
    OnUnregisterCallback<T>? onUnregister,
  });

  /// Registers a [Service] as a singleton. When [get] is first called
  /// with [T] and [group], [DI] creates, initializes, and returns a new instance
  /// of [T]. All subsequent calls to [get] return the same instance.
  ///
  /// ```dart
  /// // Example:
  /// di.initSingletonService(FooBarService.new);
  /// final fooBarService1 = di.get<FooBarService>();
  /// final fooBarService2 = di.get<FooBarService>();
  /// print(fooBarService1 == fooBarService2); // true
  /// ```
  void registerSingletonService<T extends Service<Object>>(
    Constructor<T> constructor, {
    Gr? group,
  });

  /// Registers a [Service] as a factory. Each time [get] is called
  /// with T] and [group], [DI] creates, initializes, and returns a new instance
  /// of [T].
  ///
  /// ```dart
  /// // Example:
  /// di.registerFactoryService(FooBarService.new);
  /// final fooBarService1 = di.get<FooBarService>();
  /// final fooBarService2 = di.get<FooBarService>();
  /// print(fooBarService1 == fooBarService2); // false
  /// ```
  void registerFactoryService<T extends Service<P>, P extends Object>(
    Constructor<T> constructor, {
    Gr? group,
  });

  /// Registers a singleton instance of [T] with the given [constructor]. When
  /// [get] is called with [T] and [group], the same instance will be returned.
  ///
  /// ```dart
  /// di.registerSingleton(FooBarService.new);
  /// final fooBarService1 = di.get<FooBarService>();
  /// final fooBarService2 = di.get<FooBarService>();
  /// print(fooBarService1 == fooBarService2); // true
  /// ```
  void registerSingleton<T extends Object>(
    InstConstructor<T, Object> constructor, {
    Gr? group,
    OnUnregisterCallback<T>? onUnregister,
  });

  /// Registers a factory that creates a new instance of [T] each time [get] is
  /// called with [T] and [group].
  ///
  /// ```dart
  /// di.registerFactory(FooBarService.new);
  /// final fooBarService1 = di.get<FooBarService>();
  /// final fooBarService2 = di.get<FooBarService>();
  /// print(fooBarService1 == fooBarService2); // false
  /// ```
  void registerFactory<T extends Object, P extends Object>(
    InstConstructor<T, P> constructor, {
    Gr? group,
  });
}
