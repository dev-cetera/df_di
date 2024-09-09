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

// ignore_for_file: invalid_use_of_protected_member

import '/src/_internal.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
base mixin RegisterMixin on DIBase implements RegisterInterface {
  @override
  void register<T extends Object>(
    FutureOr<T> value, {
    DIKey? groupKey,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    _register<T, Object, T>(
      value,
      groupKey: groupKey,
      onUnregister: onUnregister,
    );
  }

  @override
  void registerSingletonService<T extends Service<Object>>(
    Constructor<T> constructor, {
    DIKey? groupKey,
  }) {
    registerSingleton<T>(
      () {
        final instance = constructor();
        return instance.thenOr((e) => e.initService(Object()).thenOr((e) => instance));
      },
      groupKey: groupKey,
      onUnregister: (e) {
        return e.thenOr((e) {
          return e.initialized.thenOr((_) {
            return e.dispose();
          });
        });
      },
    );
  }

  @override
  void registerFactoryService<T extends Service<P>, P extends Object>(
    Constructor<T> constructor, {
    DIKey? groupKey,
  }) {
    registerFactory<T, P>(
      (params) => constructor().thenOr((e) => e.initService(params).thenOr((_) => e)),
      groupKey: groupKey,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  void registerFactory<T extends Object, P extends Object>(
    InstConstructor<T, P> constructor, {
    DIKey? groupKey,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    _register<Inst<T, P>, P, T>(
      Inst<T, P>(constructor),
      groupKey: groupKey,
      onUnregister: onUnregister,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  void registerSingleton<T extends Object>(
    Constructor<T> constructor, {
    DIKey? groupKey,
    OnUnregisterCallback<T>? onUnregister,
  }) {
    register<SingletonWrapper<T>>(SingletonWrapper<T>(constructor),
        groupKey: preferFocusGroup(groupKey),
        onUnregister: (e) => e.thenOr((i) => i.instance.thenOr((e) => onUnregister?.call(e))));
  }

  void _register<T extends Object, P extends Object, R extends Object>(
    FutureOr<T> value, {
    DIKey? groupKey,
    OnUnregisterCallback<R>? onUnregister,
    DependencyValidator? validator,
  }) {
    final fg = preferFocusGroup(groupKey);
    registerDependency<FutureOrInst<T, P>, P>(
      dependency: Dependency(
        value: FutureOrInst<T, P>((_) => value),
        metadata: DependencyMetadata(
          index: registrationCount++,
          groupKey: fg,
          onUnregister: onUnregister != null ? (e) => e is R ? onUnregister(e) : null : null,
          validator: validator,
        ),
      ),
    );
    // If there's a completer waiting for this value that was registered via the until() function,
    // complete it.
    getOrNull<InternalCompleterOr<T>>(groupKey: DIKey(T))
        ?.thenOr((e) => e.internalValue.complete(value));
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
abstract interface class RegisterInterface {
  /// Registers the [value] under type [T] and the specified [groupKey], or
  /// under [DIKey.defaultGroup] if no groupKey is provided.
  ///
  /// Optionally provide an [onUnregister] callback to be called on [unregister].
  ///
  /// Throws [DependencyAlreadyRegisteredException] if a dependency with the
  /// same type [T] and [groupKey] already exists.
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
    DIKey? groupKey,
    OnUnregisterCallback<T>? onUnregister,
  });

  /// Registers a [Service] as a singleton. When [get] is first called
  /// with [T] and [groupKey], [DI] creates, initializes, and returns a new instance
  /// of [T]. All subsequent calls to [get] return the same instance.
  ///
  /// ```dart
  /// // Example:
  /// di.initSingletonService(FooBarService.new)
  /// final fooBarService1 = di.get<FooBarService>();
  /// final fooBarService2 = di.get<FooBarService>();
  /// print(fooBarService1 == fooBarService2); // true
  /// ```
  void registerSingletonService<T extends Service<Object>>(
    Constructor<T> constructor, {
    DIKey? groupKey,
  });

  /// Registers a [Service] as a factory. Each time [get] is called
  /// with T] and [groupKey], [DI] creates, initializes, and returns a new instance
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
    DIKey? groupKey,
  });

  /// Registers a singleton instance of [T] with the given [constructor]. When
  /// [get] is called with [T] and [groupKey], the same instance will be returned.
  ///
  /// ```dart
  /// di.registerSingleton(FooBarService.new);
  /// final fooBarService1 = di.get<FooBarService>();
  /// final fooBarService2 = di.get<FooBarService>();
  /// print(fooBarService1 == fooBarService2); // true
  /// ```
  void registerSingleton<T extends Object>(
    Constructor<T> constructor, {
    DIKey? groupKey,
    OnUnregisterCallback<T>? onUnregister,
  });

  /// Registers a factory that creates a new instance of [T] each time [get] is
  /// called with [T] and [groupKey].
  ///
  /// ```dart
  /// di.registerFactory(FooBarService.new);
  /// final fooBarService1 = di.get<FooBarService>();
  /// final fooBarService2 = di.get<FooBarService>();
  /// print(fooBarService1 == fooBarService2); // false
  /// ```
  void registerFactory<T extends Object, P extends Object>(
    InstConstructor<T, Object> constructor, {
    DIKey? groupKey,
    OnUnregisterCallback<T>? onUnregister,
  });
}
