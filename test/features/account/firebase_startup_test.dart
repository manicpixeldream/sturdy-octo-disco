import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/features/account/firebase_startup.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'Firebase startup failure offers retry before opening the workspace',
    (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        FirebaseStartup(
          initialize: () async {
            if (++attempts == 1) throw StateError('Unavailable');
          },
          workspace: (_) => const MaterialApp(home: Text('Workspace')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Could not start Gavel.'), findsOneWidget);
      expect(find.text('Workspace'), findsNothing);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.text('Workspace'), findsOneWidget);
    },
  );
}
