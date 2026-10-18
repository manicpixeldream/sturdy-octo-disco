import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/widgets/gavel_bottom_nav.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('does not overflow when squeezed into a tiny space', (
    tester,
  ) async {
    await pumpGavelWidget(
      tester,
      SizedBox(
        width: 120,
        height: 20,
        child: GavelBottomNav(currentIndex: 0, onTap: (_) {}),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
