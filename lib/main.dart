import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app.dart';
import 'core/storage/workspace_storage_platform.dart'
    if (dart.library.js_interop) 'core/storage/workspace_storage_web.dart';
import 'features/onboarding/onboarding.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  // The work screens pushed onto the shell also have standalone routes.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  runApp(GavelApp(onboarding: Onboarding(), storage: openWorkspaceStorage()));
}
