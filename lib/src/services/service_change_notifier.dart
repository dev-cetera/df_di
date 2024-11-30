import 'dart:async';
import 'package:df_type/df_type.dart';
import 'package:meta/meta.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class ServiceChangeNotifier<T> {
  static final _emptyListeners = List<Function?>.filled(0, null);
  List<Function?> _listeners = _emptyListeners;
  int _count = 0;
  bool _isDisposed = false;

  final _sequantial = Sequential();

  FutureOr<void> get last => _sequantial.last;
  bool get isEmpty => _sequantial.isEmpty;

  @protected
  bool get hasListeners => _count > 0;

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError(
        'Cannot use a ShallowSequentialChangeNotifier after it has been disposed.',
      );
    }
  }

  void addListener(ServiceCallback<T> listener) {
    _ensureNotDisposed();

    if (_count == _listeners.length) {
      _resizeListeners(_listeners.length * 2);
    }
    _listeners[_count++] = listener;
  }

  void addAllListeners(List<ServiceCallback<T>> listeners) {
    _ensureNotDisposed();

    if (_count + listeners.length > _listeners.length) {
      _resizeListeners(_count + listeners.length);
    }

    for (var listener in listeners) {
      _listeners[_count++] = listener;
    }
  }

  void _resizeListeners(int newSize) {
    _listeners = List<Function?>.filled(newSize, null)
      ..setRange(0, _count, _listeners);
  }

  void removeListener(ServiceCallback<T> listener) {
    _ensureNotDisposed();

    for (var i = 0; i < _count; i++) {
      if (_listeners[i] == listener) {
        _listeners[i] = null; // Mark the listener as null
        _count--;
        return;
      }
    }
  }

  FutureOr<void> notifyListeners(T value) {
    _ensureNotDisposed();
    if (_count == 0) return null;

    // Add each listener sequentially to the queue for processing.
    for (var i = 0; i < _count; i++) {
      final listener = _listeners[i];
      if (listener != null) {
        _sequantial.add((_) => listener(value));
      }
    }
    return last;
  }

  void removeAllListeners() {
    _ensureNotDisposed();
    _listeners = _emptyListeners;
    _count = 0;
  }

  @mustCallSuper
  void dispose() {
    _ensureNotDisposed();
    _listeners = _emptyListeners;
    _isDisposed = true;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef ServiceCallback<T> = FutureOr<void> Function(T value);
