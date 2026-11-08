import 'onboarding_storage.dart'
    if (dart.library.js_interop) 'onboarding_storage_web.dart'
    as storage;

class Onboarding {
  Onboarding() : _isComplete = storage.readCompletion();

  bool _isComplete;
  bool get isComplete => _isComplete;

  void complete() {
    _isComplete = true;
    storage.writeCompletion();
  }
}
