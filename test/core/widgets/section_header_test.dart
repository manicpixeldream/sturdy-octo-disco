import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/widgets/section_header.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('hides the action when it has no handler', (tester) async {
    await pumpGavelWidget(
      tester,
      const SectionHeader(title: 'Your assignments', actionLabel: 'See all'),
    );

    expect(find.text('Your assignments'), findsOneWidget);
    expect(find.text('See all'), findsNothing);
  });

  testWidgets('shows the action and reports taps', (tester) async {
    var taps = 0;
    await pumpGavelWidget(
      tester,
      SectionHeader(
        title: 'Your assignments',
        actionLabel: 'See all',
        onAction: () => taps++,
      ),
    );

    await tester.tap(find.text('See all'));
    expect(taps, 1);
  });
}
