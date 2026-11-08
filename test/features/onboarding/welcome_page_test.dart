import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/app.dart';
import 'package:gavel/core/router/routes.dart';
import 'package:gavel/features/home/home_page.dart';
import 'package:gavel/features/onboarding/onboarding.dart';
import 'package:gavel/features/onboarding/welcome_page.dart';
import 'package:gavel/features/onboarding/widgets/feature_card.dart';
import 'package:gavel/features/research/research_page.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('first launch shows Welcome and returning visits skip it', (
    tester,
  ) async {
    await tester.pumpWidget(
      GavelApp(initialLocation: Routes.research, onboarding: Onboarding()),
    );
    await tester.pumpAndSettle();

    final welcome = find.byType(WelcomePage);
    expect(GoRouter.of(tester.element(welcome)).state.uri.path, Routes.welcome);
    expect(find.text('Win the room. Master the case.'), findsOneWidget);
    expect(find.byType(FeatureCard), findsNWidgets(3));
    expect(find.byType(HomePage), findsNothing);
    expect(find.byType(ResearchPage), findsNothing);

    final enter = find.byKey(const ValueKey('welcome_enter'));
    await tester.ensureVisible(enter);
    await tester.pumpAndSettle();
    await tester.tap(enter);
    await tester.pumpAndSettle();

    final home = find.byType(HomePage);
    expect(GoRouter.of(tester.element(home)).state.uri.path, Routes.home);
    expect(welcome, findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      GavelApp(initialLocation: Routes.research, onboarding: Onboarding()),
    );
    await tester.pumpAndSettle();

    final research = find.byType(ResearchPage);
    final router = GoRouter.of(tester.element(research));
    expect(router.state.uri.path, Routes.research);
    expect(welcome, findsNothing);

    router.go(Routes.welcome);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, Routes.home);
    expect(welcome, findsNothing);
  });
}
