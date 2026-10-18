import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/widgets/tag_chip.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows its label and reports taps', (tester) async {
    var taps = 0;
    await pumpGavelWidget(tester, TagChip(label: 'Ex. 4', onTap: () => taps++));

    await tester.tap(find.text('Ex. 4'));
    expect(taps, 1);
  });
}
