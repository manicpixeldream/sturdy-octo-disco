import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/keys.dart';
import '../../../core/theme/spacing.dart';

class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth >= 520
          ? (constraints.maxWidth - Spacing.md) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: Spacing.md,
        runSpacing: Spacing.md,
        children: [
          for (final (id, title, icon, path) in [
            (
              'schedule',
              'Practice schedule',
              Icons.calendar_today_outlined,
              Routes.schedule,
            ),
            ('case', 'Case workspace', Icons.folder_outlined, Routes.caseFile),
            (
              'research',
              'Research library & Ask',
              Icons.search,
              Routes.research,
            ),
            ('team', 'Team & assignments', Icons.groups_outlined, Routes.team),
            (
              'themes',
              'Design system and themes',
              Icons.palette_outlined,
              Routes.gallery,
            ),
          ])
            SizedBox(
              width: width,
              child: OutlinedButton(
                key: id == 'themes'
                    ? GavelKeys.meOpenGallery
                    : ValueKey('me_quick_$id'),
                onPressed: () =>
                    path == Routes.schedule || path == Routes.gallery
                    ? context.push(path)
                    : context.go(path),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                  child: Row(
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: Spacing.md),
                      Expanded(child: Text(title)),
                      const Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
