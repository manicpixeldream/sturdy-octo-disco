import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gavel/features/team/widgets/role_metadata.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('status position is independent of side-label length', (
    tester,
  ) async {
    for (final width in [220.0, 400.0]) {
      await pumpGavelWidget(
        tester,
        SizedBox(
          width: width,
          child: const Column(
            children: [
              RoleMetadata(
                key: ValueKey('prosecution'),
                side: 'Prosecution',
                assigned: false,
              ),
              SizedBox(height: 20),
              RoleMetadata(
                key: ValueKey('defense'),
                side: 'Defense',
                assigned: false,
              ),
            ],
          ),
        ),
      );
      final first = find.descendant(
        of: find.byKey(const ValueKey('prosecution')),
        matching: find.byKey(const ValueKey('role_status')),
      );
      final second = find.descendant(
        of: find.byKey(const ValueKey('defense')),
        matching: find.byKey(const ValueKey('role_status')),
      );
      final firstBubble = find.descendant(
        of: find.byKey(const ValueKey('prosecution')),
        matching: find.byKey(const ValueKey('role_side_bubble')),
      );
      final secondBubble = find.descendant(
        of: find.byKey(const ValueKey('defense')),
        matching: find.byKey(const ValueKey('role_side_bubble')),
      );
      expect(tester.getSize(firstBubble), tester.getSize(secondBubble));
      expect(
        tester.getTopLeft(first).dx - tester.getTopRight(firstBubble).dx,
        tester.getTopLeft(second).dx - tester.getTopRight(secondBubble).dx,
      );
      expect(tester.getTopLeft(first).dx, tester.getTopLeft(second).dx);
      final firstOffset =
          tester.getTopLeft(first).dy -
          tester.getTopLeft(find.byKey(const ValueKey('prosecution'))).dy;
      final secondOffset =
          tester.getTopLeft(second).dy -
          tester.getTopLeft(find.byKey(const ValueKey('defense'))).dy;
      expect(firstOffset, secondOffset);
      expect(tester.takeException(), isNull);
    }
  });
}
