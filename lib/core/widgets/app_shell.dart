import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/spacing.dart';
import 'gavel_bottom_nav.dart';
import 'gavel_sidebar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _navigate(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final sidebar = constraints.maxWidth >= LayoutTokens.tablet;
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sidebar)
              GavelSidebar(
                currentIndex: navigationShell.currentIndex,
                onTap: _navigate,
                expanded: constraints.maxWidth >= LayoutTokens.desktop,
              ),
            Expanded(child: navigationShell),
          ],
        ),
        bottomNavigationBar: sidebar
            ? null
            : GavelBottomNav(
                currentIndex: navigationShell.currentIndex,
                onTap: _navigate,
              ),
      );
    },
  );
}
