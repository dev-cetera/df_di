```dart
// 1. Create a new helper class for the fluent API
class DependencyRequest<T extends Object> {
  final DI _di;
  final Entity _groupEntity;
  final bool _traverse;

  DependencyRequest(this._di, this._groupEntity, this._traverse);

  /// Retrieves the dependency as a lazy-loaded singleton.
  Option<Resolvable<T>> asSingleton() {
    return _di.getLazySingleton<T>(groupEntity: _groupEntity, traverse: _traverse);
  }

  /// Retrieves a new instance of the dependency every time.
  Option<Resolvable<T>> asFactory() {
    return _di.getFactory<T>(groupEntity: _groupEntity, traverse: _traverse);
  }

  /// Retrieves the dependency, which may be sync or async.
  Option<Resolvable<T>> value() {
    return _di.get<T>(groupEntity: _groupEntity, traverse: _traverse);
  }
}

// 2. Add a new, simplified `fetch` method to DIBase
// File: lib/src/core/di/_di_base.dart
base class DIBase {
  // ... existing methods

  /// Initiates a request to fetch a dependency of type [T].
  /// Returns a request object for a fluent API.
  ///
  /// Example:
  /// final service = di.fetch<MyService>().asSingleton().unwrap();
  /// final data = di.fetch<Data>().value().unwrap();
  DependencyRequest<T> fetch<T extends Object>({
    Entity groupEntity = const DefaultEntity(),
    bool traverse = true,
  }) {
    final g = groupEntity.preferOverDefault(focusGroup);
    return DependencyRequest<T>(this as DI, g, traverse);
  }
}
```
