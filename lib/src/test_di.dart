import 'dart:async';

import '_dependency.dart';
import '_registry.dart';
import 'di_key.dart';

class TestDI {
  final registry = Registry();

  TestDI? parent;

  DIKey focusGroup = DIKey.defaultGroup;

  void register<T extends Object>(
    T value, {
    DIKey? groupKey,
  }) {
    final key = groupKey ?? focusGroup;
    final metadata = DependencyMetadata(
      index: -1, // TODO: Count index
      groupKey: key,
      isValid: () => true,
      onUnregister: (_) {},
    );
    _registerDependency<T>(
      dependency: Dependency(
        value: value,
        metadata: metadata,
      ),
    );
  }

  void _registerDependency<T extends Object>({
    required Dependency<T> dependency,
    bool override = false,
  }) {
    final groupKey = dependency.metadata.groupKey;
    if (override) {
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
  }) {
    return _getDependencyOrNull<T>(groupKey: groupKey)?.value as FutureOr<T>?;
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
