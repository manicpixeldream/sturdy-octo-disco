import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/models/trial_role.dart';
import 'package:gavel/data/models/role_assignment.dart';
import 'package:gavel/data/models/task_item.dart';

void main() {
  test('roles and assignments roundtrip and own immutable collections', () {
    final responsibilities = ['Prepare'];
    final role = TrialRole(
      id: 'r',
      title: 'Attorney',
      side: 'Defense',
      responsibilities: responsibilities,
    );
    responsibilities.clear();
    expect(role.responsibilities, ['Prepare']);
    expect(TrialRole.fromMap(role.toMap()), role);
    expect(role.copyWith(title: 'Witness').title, 'Witness');
    final assignment = RoleAssignment(
      roleId: 'r',
      teammateId: 'a',
      tasks: [
        TaskItem(
          id: 't',
          title: 'Prepare',
          assigneeId: 'a',
          dueDate: DateTime(2026),
        ),
      ],
    );
    expect(RoleAssignment.fromMap(assignment.toMap()), assignment);
    expect(() => assignment.tasks.clear(), throwsUnsupportedError);
    expect(() => role.responsibilities.clear(), throwsUnsupportedError);
  });
}
