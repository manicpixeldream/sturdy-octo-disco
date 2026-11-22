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
import 'features/account/firebase_startup.dart';
import 'features/onboarding/onboarding.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final supportsFirebase =
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  // The work screens pushed onto the shell also have standalone routes.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  const demo = bool.fromEnvironment('GAVEL_DEMO');
  if (demo || !supportsFirebase) {
    final storage = openWorkspaceStorage();
    runApp(
      GavelApp(
        onboarding: Onboarding(),
        storage: storage,
        persistsLocalWork: storage != null,
      ),
    );
    return;
  }
  runApp(
    FirebaseStartup(
      initialize: () async {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      },
      workspace: (_) => _sharedWorkspace(),
    ),
  );
}

Widget _sharedWorkspace() {
  final session = FirebaseAccountSession(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
  return AccountGate(
    session: session,
    workspace: (account, teamId) {
      final cloud = FirestoreWorkspace(FirebaseFirestore.instance, teamId);
      final storage = openWorkspaceStorage(namespace: '${account.uid}.$teamId');
      return GavelApp(
        storage: storage,
        persistsLocalWork: storage != null,
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
  );
}
