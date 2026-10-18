import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/widgets/initials_avatar.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('initials use the first and last words', () {
    expect(InitialsAvatar.initialsFor('Mara Okafor'), 'MO');
    expect(InitialsAvatar.initialsFor('Officer Dan Reyes'), 'OR');
    expect(InitialsAvatar.initialsFor('  sofia   reyes '), 'SR');
    expect(InitialsAvatar.initialsFor('Dana'), 'D');
    expect(InitialsAvatar.initialsFor('   '), '?');
  });

  test('color is picked from the palette and ignores case and spacing', () {
    final color = InitialsAvatar.colorFor('Marcus Bell');
    expect(InitialsAvatar.palette, contains(color));
    expect(InitialsAvatar.colorFor(' marcus bell '), color);
  });

  testWidgets('renders the initials', (tester) async {
    await pumpGavelWidget(tester, const InitialsAvatar(name: 'Sofia Reyes'));

    expect(find.text('SR'), findsOneWidget);
  });
}
