import 'package:material_ui/material_ui.dart';

import '../theme/spacing.dart';

class WorkspaceColumns extends StatelessWidget {
  const WorkspaceColumns({
    super.key,
    required this.primary,
    required this.secondary,
  });

  final Widget primary;
  final Widget secondary;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < LayoutTokens.columns) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            primary,
            const SizedBox(height: Spacing.xxl),
            secondary,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: primary),
          const SizedBox(width: Spacing.hero),
          Expanded(flex: 4, child: secondary),
        ],
      );
    },
  );
}
