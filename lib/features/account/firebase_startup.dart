import 'package:material_ui/material_ui.dart';

import '../../core/theme/gavel_theme.dart';

class FirebaseStartup extends StatefulWidget {
  const FirebaseStartup({
    super.key,
    required this.initialize,
    required this.workspace,
  });

  final Future<void> Function() initialize;
  final WidgetBuilder workspace;

  @override
  State<FirebaseStartup> createState() => _FirebaseStartupState();
}

class _FirebaseStartupState extends State<FirebaseStartup> {
  late Future<void> _initialization = Future.sync(widget.initialize);

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _initialization,
    builder: (context, snapshot) {
      final finished = snapshot.connectionState == ConnectionState.done;
      if (finished && !snapshot.hasError) return widget.workspace(context);
      return MaterialApp(
        title: 'Gavel',
        debugShowCheckedModeBanner: false,
        theme: GavelThemeVariant.light.data,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: finished
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 16,
                        children: [
                          const Text('Could not start Gavel.'),
                          FilledButton(
                            onPressed: () => setState(() {
                              _initialization = Future.sync(widget.initialize);
                            }),
                            child: const Text('Try again'),
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(
                        semanticsLabel: 'Starting Gavel',
                      ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
