import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/keys.dart';
import 'package:gavel/core/router/routes.dart';
import 'package:gavel/core/theme/gavel_colors.dart';
import 'package:gavel/features/gallery/gallery_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('theme toggle offers Light, Dark, and Midnight', (tester) async {
    await pumpGavelApp(tester, initialLocation: Routes.gallery);

    final toggle = find.byKey(GavelKeys.galleryThemeToggle);
    for (final label in ['Light', 'Dark', 'Midnight']) {
      expect(
        find.descendant(of: toggle, matching: find.text(label)),
        findsOneWidget,
      );
    }
  });

  testWidgets('each selection applies its theme app-wide', (tester) async {
    await pumpGavelApp(tester, initialLocation: Routes.gallery);
    final toggle = find.byKey(GavelKeys.galleryThemeToggle);

    Color background() =>
        Theme.of(tester.element(find.byType(GalleryPage)))
            .scaffoldBackgroundColor;

    for (final (label, color) in [
      ('Midnight', GavelColors.midnight),
      ('Dark', GavelColors.plum),
      ('Light', GavelColors.cream),
    ]) {
      await tester.tap(find.descendant(of: toggle, matching: find.text(label)));
      await tester.pumpAndSettle();
      expect(background(), color, reason: label);
    }
  });
}
