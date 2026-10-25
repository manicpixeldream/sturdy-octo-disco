import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gavel/data/mock/mock_role_repository.dart';
import 'package:gavel/data/models/role_assignment.dart';

import '../../helpers/pump_app.dart';

class OfflineRoles extends MockRoleRepository {
  OfflineRoles() : super(memberIds: {'tm_sofia'}, dueDate: DateTime(2026));
  bool offline = true;
  bool failSave = true;
  @override
  Future<List<RoleAssignment>> fetchAssignments() async {
    if (offline) throw StateError('offline');
    return super.fetchAssignments();
  }

  @override
  Future<RoleAssignment> assign(String roleId, String teammateId) async {
    if (failSave) throw StateError('offline');
    return super.assign(roleId, teammateId);
  }
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  for (var i = 0; i < 50 && target.hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView).last, const Offset(0, -180));
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
}

void main() {
  testWidgets(
    'deep link recovers load and assignment failures without losing selection',
    (tester) async {
      final repo = OfflineRoles();
      await pumpGavelApp(
        tester,
        initialLocation: '/team/assign/defense_closing',
        roleRepository: repo,
      );
      expect(find.text('Assignment unavailable'), findsOneWidget);
      repo.offline = false;
      await tester.tap(find.byKey(const ValueKey('load_retry')));
      await tester.pumpAndSettle();
      final member = find.byKey(const ValueKey('select_tm_sofia'));
      await reveal(tester, member);
      await tester.tap(member);
      await tester.pumpAndSettle();
      final submit = find.byKey(const ValueKey('assign_role_submit'));
      await reveal(tester, submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('assign_error')), findsOneWidget);
      expect(await repo.fetchAssignments(), isEmpty);
      repo.failSave = false;
      await reveal(tester, submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Role assigned'), findsOneWidget);
      expect((await repo.fetchAssignments()).length, 1);
      expect(find.byKey(const ValueKey('assign_role_submit')), findsNothing);
    },
  );
}
