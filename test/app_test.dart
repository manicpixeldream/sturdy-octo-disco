import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/app.dart';
import 'package:gavel/core/theme/gavel_colors.dart';
import 'package:gavel/features/home/home_page.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('starts on Home at /home with the light Gavel theme', (
    tester,
  ) async {
    await tester.pumpWidget(const GavelApp());
    await tester.pumpAndSettle();

    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).title, 'Gavel');
    expect(find.byType(HomePage), findsOneWidget);

    final home = tester.element(find.byType(HomePage));
    expect(GoRouter.of(home).state.uri.path, '/home');

    final theme = Theme.of(home);
    expect(theme.colorScheme.primary, GavelColors.maroon);
    expect(theme.scaffoldBackgroundColor, GavelColors.cream);
  });
}
