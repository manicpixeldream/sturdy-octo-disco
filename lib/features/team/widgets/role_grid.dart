import 'package:material_ui/material_ui.dart';

import '../../../core/theme/spacing.dart';

/// Content-sized rows keep cards and their actions aligned without clipping text.
class RoleGrid extends StatelessWidget {
  const RoleGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 560 ? 2 : 1;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var start = 0; start < children.length; start += columns) ...[
            if (start > 0) const SizedBox(height: Spacing.lg),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var offset = 0; offset < columns; offset++) ...[
                    if (offset > 0) const SizedBox(width: Spacing.lg),
                    Expanded(
                      child: start + offset < children.length
                          ? children[start + offset]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}
