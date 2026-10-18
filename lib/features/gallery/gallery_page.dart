import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/keys.dart';
import '../../core/router/routes.dart';
import '../../core/theme/gavel_colors.dart';
import '../../core/theme/gavel_theme.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/gavel_card.dart';
import '../../core/widgets/initials_avatar.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_tile.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/tag_chip.dart';
import '../../state/theme_controller.dart';
import 'widgets/color_swatch_tile.dart';

/// Developer preview of the theme and core widgets. Not part of the product.
class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final themeController = context.watch<ThemeController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Design system')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          0,
          Spacing.lg,
          Spacing.xxl,
        ),
        children: [
          Text('DEVELOPER PREVIEW', style: text.labelSmall),
          Text('Gavel', style: text.displayMedium),
          const SizedBox(height: Spacing.xs),
          Text(
            'Theme tokens and core widgets. The theme applies to the whole app.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: Spacing.md),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<GavelThemeVariant>(
              key: GavelKeys.galleryThemeToggle,
              showSelectedIcon: false,
              segments: [
                for (final variant in GavelThemeVariant.values)
                  ButtonSegment(value: variant, label: Text(variant.label)),
              ],
              selected: {themeController.variant},
              onSelectionChanged: (selection) =>
                  themeController.select(selection.single),
            ),
          ),

          const SizedBox(height: Spacing.lg),
          const SectionHeader(title: 'Typography'),
          Text('Win the room.', style: text.displayLarge),
          Text('State v. Harmon', style: text.headlineMedium),
          Text('Opening statement', style: text.titleLarge),
          Text('Witness: Officer Reyes', style: text.titleMedium),
          Text(
            'Body text is Inter. Display and headline text is Fraunces.',
            style: text.bodyLarge,
          ),
          Text('Caption in muted ink', style: text.bodySmall),

          const SizedBox(height: Spacing.lg),
          const SectionHeader(title: 'Colors'),
          const Wrap(
            spacing: Spacing.md,
            runSpacing: Spacing.md,
            children: [
              ColorSwatchTile(name: 'Maroon', color: GavelColors.maroon),
              ColorSwatchTile(name: 'Plum', color: GavelColors.plum),
              ColorSwatchTile(name: 'Cream', color: GavelColors.cream),
              ColorSwatchTile(name: 'Gold', color: GavelColors.gold),
              ColorSwatchTile(name: 'Midnight', color: GavelColors.midnight),
              ColorSwatchTile(name: 'Rose', color: GavelColors.rose),
              ColorSwatchTile(
                name: 'Bright gold',
                color: GavelColors.brightGold,
              ),
              ColorSwatchTile(name: 'Ready', color: GavelColors.ready),
              ColorSwatchTile(
                name: 'In progress',
                color: GavelColors.inProgress,
              ),
              ColorSwatchTile(name: 'Flagged', color: GavelColors.flagged),
              ColorSwatchTile(name: 'Info', color: GavelColors.info),
            ],
          ),

          const SizedBox(height: Spacing.lg),
          const SectionHeader(title: 'Stats'),
          const Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '14',
                  label: 'Exhibits',
                  icon: Icons.folder_outlined,
                ),
              ),
              SizedBox(width: Spacing.sm),
              Expanded(
                child: StatTile(
                  value: '6',
                  label: 'Witnesses',
                  icon: Icons.record_voice_over_outlined,
                ),
              ),
              SizedBox(width: Spacing.sm),
              Expanded(
                child: StatTile(
                  value: '9',
                  label: 'Team tasks',
                  icon: Icons.checklist,
                ),
              ),
            ],
          ),

          const SizedBox(height: Spacing.lg),
          SectionHeader(
            title: 'Card and progress',
            actionLabel: 'See all',
            onAction: () => _toast(context, 'Section action tapped'),
          ),
          GavelCard(
            onTap: () => _toast(context, 'Card tapped'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('State v. Harmon', style: text.headlineSmall),
                    ),
                    const StatusPill(status: GavelStatus.inProgress),
                  ],
                ),
                const SizedBox(height: Spacing.xs),
                Text('Trial in 23 days', style: text.bodySmall),
                const SizedBox(height: Spacing.md),
                const ProgressBar(value: 0.72),
                const SizedBox(height: Spacing.xs),
                Text('72% team readiness', style: text.labelMedium),
              ],
            ),
          ),

          const SizedBox(height: Spacing.lg),
          const SectionHeader(title: 'Status pills'),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (final status in GavelStatus.values)
                StatusPill(status: status),
            ],
          ),

          const SizedBox(height: Spacing.lg),
          const SectionHeader(title: 'Tags'),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              TagChip(
                label: 'Ex. 4',
                icon: Icons.description_outlined,
                onTap: () => _toast(context, 'Tag tapped'),
              ),
              const TagChip(label: 'Affidavit: Reyes'),
              const TagChip(label: 'Precedent'),
            ],
          ),

          const SizedBox(height: Spacing.lg),
          const SectionHeader(title: 'Avatars'),
          const Wrap(
            spacing: Spacing.sm,
            children: [
              InitialsAvatar(name: 'Mara Okafor'),
              InitialsAvatar(name: 'Sofia Reyes'),
              InitialsAvatar(name: 'Marcus Bell'),
              InitialsAvatar(name: 'Officer Reyes'),
              InitialsAvatar(name: 'Dana'),
            ],
          ),

          const SizedBox(height: Spacing.lg),
          const SectionHeader(title: 'Empty state'),
          GavelCard(
            child: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No exhibits yet',
              message: 'Exhibits from the case packet will show up here.',
              actionLabel: 'Add exhibit',
              onAction: () => _toast(context, 'Empty state action'),
            ),
          ),

          const SizedBox(height: Spacing.lg),
          const SectionHeader(title: 'Buttons and transitions'),
          FilledButton(
            key: GavelKeys.galleryPushPage,
            onPressed: () => context.push(Routes.gallery),
            child: const Text('Push another page'),
          ),
          const SizedBox(height: Spacing.sm),
          OutlinedButton(
            onPressed: () => _toast(context, 'Outlined button tapped'),
            child: const Text('Outlined button'),
          ),
        ],
      ),
    );
  }
}
