//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:df_debouncer/df_debouncer.dart';
import '/src/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Defines the possible lifecycle states of a [Service].
enum _ServiceState {
  uninitialized,
  initializing,
  initialized,
  disposing,
  disposed,
}

/// A base class for services that require initialization and disposal
/// management.
///
/// This class provides a robust, state-managed structure for service
/// lifecycles, ensuring they are properly initialized and disposed of, even
/// under concurrent access. It is intended for use within a Dependency
/// Injection (DI) system.
abstract class Service<TParams extends Option> {
  Service();

  static Resolvable<None> unregister(Result<Service> e) {
    return Resolvable(() => consec(e.unwrap().dispose(), (_) => const None()));
  }

  // --- STATE MANAGEMENT ------------------------------------------------------

  var _state = _ServiceState.uninitialized;
  // ✅ Use SafeFinisher<None> to signal completion of void operations.
  SafeFinisher<None>? _operationFinisher;

  /// Returns `true` if the service has been successfully initialized.
  bool get initialized => _state == _ServiceState.initialized;

  /// Returns `true` if the service has been disposed or is being disposed.
  bool get disposed => _state == _ServiceState.disposed || _state == _ServiceState.disposing;

  // --- INITIALIZATION OF SERVICE ---------------------------------------------

  /// Initializes the service, making it ready for use.
  ///
  /// This method is idempotent and safe to call multiple times. If called
  /// while already initializing, it returns the `FutureOr` of the ongoing operation.
  /// Throws a [StateError] if called on a disposed or disposing service.
  @nonVirtual
  FutureOr<void> init(TParams params) {
    if (_state == _ServiceState.initialized) return null;

    if (_state == _ServiceState.initializing) {
      return consec(_operationFinisher!.resolvable().value, (_) {});
    }

    if (disposed) {
      throw StateError('Cannot initialize a service that has been disposed.');
    }

    _state = _ServiceState.initializing;
    _operationFinisher = SafeFinisher<None>();

    try {
      final sequential = Sequential();
      sequential.addAll([
        ...provideInitListeners().map((e) => (_) => e(params)),
        (_) => _state = _ServiceState.initialized,
      ]);

      // ✅ Chain the sequential operation to the finisher's completion.
      return consec(
        sequential.last,
        (_) {
          _operationFinisher!.finish(const None());
        },
        onError: (e) {
          _operationFinisher!.resolve(Sync.value(Err(e)));
        },
      );
    } catch (e) {
      _state = _ServiceState.disposed;
      _operationFinisher!.resolve(Sync.value(Err(e)));
      rethrow;
    }
  }

  /// Provides listeners to be executed sequentially during `init`.
  @mustCallSuper
  TServiceListeners<TParams> provideInitListeners() => [];

  // --- RESTARTING OF SERVICE -------------------------------------------------

  late TParams _params;

  /// Restarts the service by calling `init` again after a full `dispose`.
  ///
  /// Uses a debouncer to prevent rapid-fire restarts. This is safe to call
  /// at any time, as it relies on the robust `init` and `dispose` logic.
  @nonVirtual
  @pragma('vm:prefer-inline')
  FutureOr<void> restartService(TParams params) {
    _params = params;
    return _restartDebouncer.call();
  }

  late final _restartDebouncer = Debouncer(
    delay: Duration.zero,
    // ✅ Correctly chain FutureOr operations.
    onWaited: () => consec(dispose(), (_) => init(_params)),
  );

  // --- DISPOSAL OF SERVICE ---------------------------------------------------

  /// Provides listeners to be executed sequentially during `dispose`.
  @mustCallSuper
  TServiceListeners<void> provideDisposeListeners() => [];

  /// Disposes of this service, making it unusable for garbage collection.
  ///
  /// This method is idempotent. If called while already disposing, it returns
  /// the `FutureOr` of the ongoing operation.
  @protected
  @nonVirtual
  FutureOr<void> dispose() {
    if (_state == _ServiceState.disposed || _state == _ServiceState.disposing) {
      return consec(_operationFinisher?.resolvable().value, (_) {});
    }

    if (_state == _ServiceState.uninitialized) {
      _state = _ServiceState.disposed;
      return null;
    }

    // Await any ongoing initialization to finish before disposing.
    return consec(_operationFinisher?.resolvable().value, (_) {
      _state = _ServiceState.disposing;
      _operationFinisher = SafeFinisher<None>();

      try {
        final sequential = Sequential();
        sequential.addAll([
          ...provideDisposeListeners().map((e) => (_) => e(null)),
          (_) => _state = _ServiceState.disposed,
        ]);

        return consec(
          sequential.last,
          (_) {
            _operationFinisher!.finish(const None());
          },
          onError: (e) {
            _state = _ServiceState.disposed;
            _operationFinisher!.resolve(Sync.value(Err(e)));
          },
        );
      } catch (e) {
        _state = _ServiceState.disposed;
        _operationFinisher!.resolve(Sync.value(Err(e)));
        rethrow;
      }
    });
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TServiceListeners<T> = List<FutureOr<void> Function(T data)>;

// //.title
// // ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// //
// // Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// // source code is governed by an MIT-style license described in the LICENSE
// // file located in this project's root directory.
// //
// // See: https://opensource.org/license/mit
// //
// // ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// //.title~

// import 'package:df_debouncer/df_debouncer.dart';

// import '/src/_common.dart';

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// /// A base class for services that require initialization and disposal
// /// management.
// ///
// /// This class is intended to be used within a Dependency Injection [DI] system.
// ///
// /// It provides a standardized structure for managing the lifecycle of services,
// /// ensuring they are properly initialized when needed and disposed of when no
// /// longer in use.
// abstract class Service<TParams extends Option> {
//   //
//   //
//   //

//   static Resolvable<None> unregister(Result<Service> e) {
//     return Resolvable(() async {
//       await e.unwrap().dispose();
//       return const None();
//     });
//   }

//   //
//   //
//   //

//   Service();

//   // Used to avoid concurrent initialization, resetting, and disposal.
//   final _sequential = Sequential();

//   // --- INITIALIZATION OF SERVICE ---------------------------------------------

//   bool _initialized = false;
//   bool get initialized => _initialized;

//   /// Initializes and re-initializes this service, making it ready for use.
//   @nonVirtual
//   FutureOr<void> init(TParams params) {
//     if (_disposed) {
//       throw Err('Service has already been initialized.');
//     }
//     _sequential.addAll([
//       // Call init listeners.
//       ...provideInitListeners().map(
//         (e) => (_) => e(params),
//       ),
//       (_) {
//         // Mark the service as initialized.
//         _initialized = true;
//       },
//     ]);
//     return _sequential.last;
//   }

//   @mustCallSuper
//   TServiceListeners<TParams> provideInitListeners() => [];

//   // --- RESTARTING OF SERVICE -------------------------------------------------

//   late TParams _params;

//   @nonVirtual
//   @pragma('vm:prefer-inline')
//   FutureOr<void> restartService(TParams params) async {
//     _params = params;
//     return _restartDebouncer.call();
//   }

//   // Used to avoid restarting the service multiple times in quick succession.
//   late final _restartDebouncer = Debouncer(
//     delay: Duration.zero,
//     onWaited: () => init(_params),
//   );

//   // --- DISPOSAL OF SERVICE ---------------------------------------------------

//   /// Whether the service has been disposed.
//   @pragma('vm:prefer-inline')
//   bool get disposed => _disposed;

//   bool _disposed = false;

//   @mustCallSuper
//   TServiceListeners<void> provideDisposeListeners() => [];

//   /// Disposes of this service, making it unusable and ready for garbage
//   /// collection.
//   ///
//   /// Do not call this method directly.
//   @protected
//   @nonVirtual
//   FutureOr<void> dispose() {
//     // Throw an exception if the service has already been disposed.
//     if (_disposed) {
//       throw Err('Service has already been disposed.');
//     }
//     _sequential.addAll([
//       // Call dispose listeners.
//       ...provideDisposeListeners().map(
//         (e) => (_) => e(null),
//       ),
//       (_) {
//         // Mark the service as disposed.
//         _disposed = true;
//       },
//     ]);
//     return _sequential.last;
//   }
// }

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// typedef TServiceListeners<T> = List<FutureOr<void> Function(T data)>;
