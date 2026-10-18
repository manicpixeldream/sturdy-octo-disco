import 'package:flutter/foundation.dart';

/// Consistent retryable repository loads, with stale/disposed result protection.
abstract class LoadController extends ChangeNotifier {
  bool _disposed = false;
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

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
