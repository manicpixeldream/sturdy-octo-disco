import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/mock/mock_role_repository.dart';

void main() {
  test('catalogue covers both sides and all witnesses; assignment is atomic and immutable', () async {
    final repo = MockRoleRepository(
      memberIds: {'a'},
      dueDate: DateTime(2026, 11, 1),
    );
    final roles = await repo.fetchRoles();
    expect(roles.length, 14);
    expect(roles.where((r) => r.isWitness).length, 6);
    expect(roles.map((r) => r.id).toSet().length, roles.length);
    await expectLater(repo.assign('unknown', 'a'), throwsStateError);
    expect(await repo.fetchAssignments(), isEmpty);
    final result = await repo.assign('defense_closing', 'a');
    expect(
      result.tasks.every(
        (t) =>
            !t.isDone &&
            t.assigneeId == 'a' &&
            t.dueDate == DateTime(2026, 11, 1),
      ),
      isTrue,
    );
    await expectLater(repo.assign('defense_closing', 'a'), throwsStateError);
    expect((await repo.fetchAssignments()).single, result);
    expect(() => roles.clear(), throwsUnsupportedError);
  });
}
