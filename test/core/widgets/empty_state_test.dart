import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/widgets/empty_state.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('hides the action button when it has no handler', (tester) async {
    await pumpGavelWidget(
      tester,
      const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No exhibits yet',
        message: 'Exhibits will show up here.',
        actionLabel: 'Add exhibit',
      ),
    );

    expect(find.text('No exhibits yet'), findsOneWidget);
    expect(find.text('Exhibits will show up here.'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('shows the action button and reports taps', (tester) async {
    var taps = 0;
    await pumpGavelWidget(
      tester,
      EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No exhibits yet',
        actionLabel: 'Add exhibit',
        onAction: () => taps++,
      ),
    );

    await tester.tap(find.text('Add exhibit'));
    expect(taps, 1);
  });
}
