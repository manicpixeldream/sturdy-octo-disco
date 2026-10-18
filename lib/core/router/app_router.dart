import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/case_file/case_page.dart';
import '../../features/case_file/affidavit_page.dart';
import '../../features/gallery/gallery_page.dart';
import '../../features/home/home_page.dart';
import '../../features/me/me_page.dart';
import '../../features/research/research_page.dart';
import '../../features/research/source_detail_page.dart';
import '../../features/team/team_page.dart';
import '../widgets/app_shell.dart';
import 'routes.dart';

GoRouter createAppRouter({String initialLocation = Routes.home}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          _branch(Routes.home, const HomePage()),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.caseFile,
                builder: (context, state) => CasePage(
                  section: state.uri.queryParameters['section'],
                  factId: state.uri.queryParameters['fact'],
                ),
                routes: [
                  GoRoute(
                    path: 'affidavit/:id',
                    builder: (context, state) =>
                        AffidavitPage(affidavitId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.research,
                builder: (context, state) => ResearchPage(
                  messageId: state.uri.queryParameters['message'],
                ),
                routes: [
                  GoRoute(
                    path: 'source/:id',
                    builder: (context, state) =>
                        SourceDetailPage(sourceId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          _branch(Routes.team, const TeamPage()),
          _branch(Routes.me, const MePage()),
        ],
      ),
      GoRoute(
        path: Routes.gallery,
        builder: (context, state) => const GalleryPage(),
      ),
    ],
  );
}

StatefulShellBranch _branch(String path, Widget page) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (context, state) => page)],
  );
}
