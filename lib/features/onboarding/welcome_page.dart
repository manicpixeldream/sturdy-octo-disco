import 'package:material_ui/material_ui.dart';

import '../../core/theme/gavel_theme.dart';
import '../../core/theme/spacing.dart';
import 'widgets/feature_card.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.onEnter});

  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) => Theme(
    data: GavelTheme.dark(),
    child: Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final text = theme.textTheme;
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.xl,
                vertical: Spacing.xxxl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: LayoutTokens.reading,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'GAVEL',
                        style: text.labelLarge?.copyWith(
                          color: colors.secondary,
                        ),
                      ),
                      const SizedBox(height: Spacing.xl),
                      Semantics(
                        header: true,
                        child: Text(
                          'Win the room. Master the case.',
                          style: text.displayMedium,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      Text(
                        'A mock trial workspace for your case materials, arguments, and team preparation.',
                        style: text.bodyLarge,
                      ),
                      const SizedBox(height: Spacing.xxl),
                      const FeatureCard(
                        icon: Icons.folder_open_outlined,
                        title: 'Know the case',
                        description: 'Read affidavits, trace evidence, and build direct and cross examinations.',
                      ),
                      const SizedBox(height: Spacing.md),
                      const FeatureCard(
                        icon: Icons.manage_search,
                        title: 'Research with sources',
                        description: 'Explore prepared answers and save references in your library.',
                      ),
                      const SizedBox(height: Spacing.md),
                      const FeatureCard(
                        icon: Icons.groups_outlined,
                        title: 'Prepare as a team',
                        description: 'Assign roles, track prep tasks, and plan practice.',
                      ),
                      const SizedBox(height: Spacing.lg),
                      Text(
                        'This demo saves your work in this browser. Teammates on other devices have separate copies.',
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: Spacing.xl),
                      FilledButton(
                        key: const ValueKey('welcome_enter'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.secondary,
                          foregroundColor: colors.onSecondary,
                        ),
                        onPressed: onEnter,
                        child: const Text('Enter the war room'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
