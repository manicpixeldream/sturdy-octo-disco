import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/widgets/stat_tile.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows the value and an uppercased label', (tester) async {
    await pumpGavelWidget(
      tester,
      const StatTile(value: '14', label: 'Exhibits'),
    );

    expect(find.text('14'), findsOneWidget);
    expect(find.text('EXHIBITS'), findsOneWidget);
  });
}
