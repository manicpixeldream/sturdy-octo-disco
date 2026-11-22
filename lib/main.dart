import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app.dart';
import 'core/storage/workspace_storage_platform.dart'
    if (dart.library.js_interop) 'core/storage/workspace_storage_web.dart';
import 'data/firestore/firestore_workspace.dart';
import 'features/account/account_gate.dart';
import 'features/account/account_session.dart';
import 'features/onboarding/onboarding.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supportsFirebase =
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (supportsFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  // The work screens pushed onto the shell also have standalone routes.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  const demo = bool.fromEnvironment('GAVEL_DEMO');
  if (demo || !supportsFirebase) {
    runApp(GavelApp(onboarding: Onboarding(), storage: openWorkspaceStorage()));
    return;
  }
  final session = FirebaseAccountSession(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
  runApp(
    AccountGate(
      session: session,
      workspace: (account, teamId) {
        final cloud = FirestoreWorkspace(FirebaseFirestore.instance, teamId);
        return GavelApp(
          storage: openWorkspaceStorage(namespace: '${account.uid}.$teamId'),
          onSignOut: session.signOut,
          accountEmail: account.email,
          sharedMemberId: account.uid,
          caseRepository: cloud.cases,
          caseBriefService: cloud.cases,
          teamRepository: cloud.team,
          taskRepository: cloud.tasks,
          scheduleRepository: cloud.schedule,
          chatRepository: cloud.chat,
          roleRepository: cloud.roles,
        );
      },
    ),
  );
}
