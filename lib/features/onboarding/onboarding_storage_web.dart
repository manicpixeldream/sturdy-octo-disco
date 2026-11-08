import 'package:web/web.dart' as web;

const _completionKey = 'gavel.onboarding.complete';

bool readCompletion() {
  try {
    return web.window.localStorage.getItem(_completionKey) == 'true';
  } catch (_) {
    return false;
  }
}

void writeCompletion() {
  try {
    web.window.localStorage.setItem(_completionKey, 'true');
  } catch (_) {
    // Onboarding still completes for this session if browser storage is blocked.
  }
}
