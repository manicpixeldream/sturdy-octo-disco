import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/widgets/progress_bar.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  const cases = [(0.4, 0.4), (1.7, 1.0), (-0.2, 0.0), (double.nan, 0.0)];

  for (final (value, fill) in cases) {
    testWidgets('value $value fills $fill of the track', (tester) async {
      await pumpGavelWidget(
        tester,
        SizedBox(width: 200, child: ProgressBar(value: value)),
      );

      final bar = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(bar.widthFactor, fill);
    });
  }
}
