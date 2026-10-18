import 'package:material_ui/material_ui.dart';

import '../theme/spacing.dart';

class WorkspaceScrollView extends StatelessWidget {
  const WorkspaceScrollView({
    super.key,
    required this.children,
    this.maxWidth = LayoutTokens.content,
    this.storageKey,
  });

  final List<Widget> children;
  final double maxWidth;
  final PageStorageKey<String>? storageKey;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final gutter = LayoutTokens.gutter(constraints.maxWidth);
      return ListView(
        key: storageKey,
        padding: EdgeInsets.fromLTRB(gutter, Spacing.lg, gutter, Spacing.hero),
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
