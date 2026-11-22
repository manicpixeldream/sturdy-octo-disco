import 'dart:async';

import 'package:flutter/foundation.dart';

/// Consistent retryable repository loads, with stale/disposed result protection.
abstract class LoadController extends ChangeNotifier {
  bool _disposed = false;
  StreamSubscription<Object?>? _subscription;
  Completer<bool>? _firstRead;
  int _generation = 0;
  bool _isLoading = false;
  bool _loadFailed = false;
  bool get isDisposed => _disposed;
  bool get isLoading => _isLoading;
  bool get loadFailed => _loadFailed;

  @protected
  Future<bool> loadWith<T>(
    Future<T> Function() fetch,
    void Function(T) apply,
  ) async {
    if (_disposed) return false;
    final generation = ++_generation;
    _isLoading = true;
    _loadFailed = false;
    notifyListeners();
    try {
      final result = await fetch();
      if (_disposed || generation != _generation) return false;
      apply(result);
      return true;
    } catch (_) {
      if (!_disposed && generation == _generation) _loadFailed = true;
      return false;
    } finally {
      if (!_disposed && generation == _generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Observes a live repository through the same loading and retry state.
  @protected
  Future<bool> watchWith<T>(Stream<T> stream, void Function(T) apply) {
    if (_disposed) return Future.value(false);
    final generation = ++_generation;
    _stopWatching();
    final firstRead = _firstRead = Completer<bool>();
    _isLoading = true;
    _loadFailed = false;
    notifyListeners();

    void finish(bool success) {
      _isLoading = false;
      _loadFailed = !success;
      if (!firstRead.isCompleted) firstRead.complete(success);
      notifyListeners();
    }

    _subscription = stream.listen(
      (value) {
        if (_disposed || generation != _generation) return;
        try {
          apply(value);
          finish(true);
        } catch (_) {
          finish(false);
        }
      },
      onError: (Object error, StackTrace stack) {
        if (!_disposed && generation == _generation) finish(false);
      },
      onDone: () {
        if (!_disposed && generation == _generation && !firstRead.isCompleted) {
          finish(false);
        }
      },
    );
    return firstRead.future;
  }

  void _stopWatching() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    final firstRead = _firstRead;
    if (firstRead != null && !firstRead.isCompleted) firstRead.complete(false);
    _firstRead = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _stopWatching();
    super.dispose();
  }
}
