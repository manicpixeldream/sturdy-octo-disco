import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app.dart';
import 'core/storage/workspace_storage_platform.dart'
    if (dart.library.js_interop) 'core/storage/workspace_storage_web.dart';
import 'features/onboarding/onboarding.dart';

void main() {
  // The work screens pushed onto the shell also have standalone routes.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  runApp(GavelApp(onboarding: Onboarding(), storage: openWorkspaceStorage()));
}
