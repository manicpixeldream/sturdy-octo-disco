import 'package:material_ui/material_ui.dart';

/// A quiet, consistent toolbar; the page's editorial heading lives in its body.
class WorkspacePage extends StatelessWidget {
  const WorkspacePage({
    super.key,
    required this.title,
    required this.child,
    this.leading,
  });

  final String title;
  final Widget child;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: leading, title: Text(title), toolbarHeight: 60),
    body: SafeArea(top: false, bottom: false, child: child),
  );
}
