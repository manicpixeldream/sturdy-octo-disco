import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'gavel_bottom_nav.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: GavelBottomNav(
        currentIndex: navigationShell.currentIndex,
        // Re-tapping the current tab returns it to its root page.
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
