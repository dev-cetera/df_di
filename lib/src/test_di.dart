import 'dart:async';

import 'package:df_type/df_type.dart';

import '_dependency.dart';
import '_registry.dart';
import 'di_key.dart';

class TestDI {
  final registry = Registry();

  TestDI? parent;

  DIKey focusGroup = DIKey.defaultGroup;

  void register<T extends Object>(
    FutureOr<T> value, {
    DIKey? groupKey,
  }) {
    final key = groupKey ?? focusGroup;
    final metadata = DependencyMetadata(
      index: -1, // TODO: Count index
      groupKey: key,
      isValid: () => true,
      onUnregister: (_) {},
    );
    _registerDependency<FutureOr<T>>(
      dependency: Dependency(
        value: value,
        metadata: metadata,
      ),
    );

    /// TODO: TEST and set traverse to false
    // If there's a completer waiting for this value that was registered via the untilOrNull() function,
    // complete it.
    getOrNull<_Completer<T>>(
      groupKey: DIKey(_Completer<T>),
    )?.thenOr((e) => e.complete(value));
  }

  // what happens when you do an await or and there are pending completers? must complete the completer if it exists or something
  FutureOr<void> unregister<T extends Object>({
    DIKey? groupKey,
  }) {
    final key = groupKey ?? focusGroup;
    final removed = registry.removeDependency<T>(groupKey: key);
    return removed?.metadata.onUnregister?.call(removed);
  }

  void _registerDependency<T extends Object>({
    required Dependency<T> dependency,
    bool overrideExisting = false,
  }) {
    final groupKey = dependency.metadata.groupKey;
    if (overrideExisting) {
      final test = _getDependencyOrNull<T>(
        groupKey: groupKey,
        traverse: false,
      );
      if (test != null) {
        // TODO: Throw error!
      }
    }
    registry.setDependency<T>(
      dependency: dependency,
    );
  }

  FutureOr<T>? getOrNull<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
    bool registerFutureResults = true,
    bool unregisterFutures = false,
  }) {
    final key = groupKey ?? focusGroup;
    final test = _getDependencyOrNull<T>(
      groupKey: key,
      traverse: traverse,
    )?.value;
    switch (test) {
      case Future<T> _:
        return test.then((e) async {
          if (registerFutureResults) {
            register<T>(e, groupKey: key); // on unregister
          }
          if (unregisterFutures) {
            unregister<T>(groupKey: key); // on unregister
          }
          return e;
        });
      case T _:
        return test;
      default:
        return null;
    }
  }

  FutureOr<T>? untilOrNull<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
    bool registerFutureResults = true,
    bool unregisterFutures = false,
  }) {
    final key = groupKey ?? focusGroup;

    // Check if the dependency is already registered.
    final test = getOrNull<T>(groupKey: key);
    if (test != null) {
      // Return the dependency if it is already registered.
      return test;
    }

    // If it's not already registered, register a Completer for the type
    // inside the untilsContainer.
    final completerGroup = DIKey(_Completer<T>); //!!! Make
    final completer = _Completer<T>();
    register<_Completer<T>>(completer, groupKey: completerGroup);
    // Wait for the register function to complete the Completer, then unregister
    // the completer before returning the value...
    return completer.futureOr.thenOr((value) {
      return unregister<_Completer<T>>(groupKey: completerGroup).thenOr((_) {
        return value;
      });
    });
  }

  Dependency? _getDependencyOrNull<T extends Object>({
    DIKey? groupKey,
    bool traverse = true,
  }) {
    final key = groupKey ?? focusGroup;
    final dependency = registry.getDependencyOrNull<FutureOr<T>>(
      groupKey: key,
    );
    if (dependency != null) {
      final isValid = dependency.metadata.isValid?.call() ?? true;
      if (isValid) {
        return dependency;
      } else {
        // TODO: Throw error!
      }
    }
    if (traverse) {
      return parent?._getDependencyOrNull<FutureOr<T>>(
        groupKey: key,
      );
    } else {
      return null;
    }
  }
}

typedef _Completer<T> = CompleterOr<FutureOr<T>>;
