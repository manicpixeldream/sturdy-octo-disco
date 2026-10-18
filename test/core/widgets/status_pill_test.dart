import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/theme/gavel_colors.dart';
import 'package:gavel/core/widgets/status_pill.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  const expected = {
    GavelStatus.ready: ('Ready', GavelColors.ready),
    GavelStatus.inProgress: ('In progress', GavelColors.inProgress),
    GavelStatus.flagged: ('Flagged', GavelColors.flagged),
    GavelStatus.info: ('Info', GavelColors.info),
  };

  for (final MapEntry(key: status, value: (label, color)) in expected.entries) {
    testWidgets('$status shows "$label" in its status color', (tester) async {
      await pumpGavelWidget(tester, StatusPill(status: status));

      expect(tester.widget<Text>(find.text(label)).style!.color, color);
    });
  }

  testWidgets('a custom label replaces the default', (tester) async {
    await pumpGavelWidget(
      tester,
      const StatusPill(status: GavelStatus.flagged, label: 'Needs review'),
    );

    expect(find.text('Needs review'), findsOneWidget);
    expect(find.text('Flagged'), findsNothing);
  });
}
