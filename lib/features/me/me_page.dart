import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/keys.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/empty_state.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Me')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyState(
              icon: Icons.person_outline,
              title: 'Me',
              message: 'Your tasks and practice schedule. Coming in v0.8.',
            ),
            OutlinedButton(
              key: GavelKeys.meOpenGallery,
              onPressed: () => context.push(Routes.gallery),
              child: const Text('Design system and themes'),
            ),
          ],
        ),
      ),
    );
  }
}
