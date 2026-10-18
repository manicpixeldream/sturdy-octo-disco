import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/widgets/gavel_card.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('renders its child and reports taps', (tester) async {
    var taps = 0;
    await pumpGavelWidget(
      tester,
      GavelCard(onTap: () => taps++, child: const Text('State v. Harmon')),
    );

    await tester.tap(find.text('State v. Harmon'));
    expect(taps, 1);
  });
}
