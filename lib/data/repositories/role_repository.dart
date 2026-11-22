import '../models/trial_role.dart';
import '../models/role_assignment.dart';

abstract interface class RoleRepository {
  Future<List<TrialRole>> fetchRoles();
  Future<List<RoleAssignment>> fetchAssignments();

  /// Atomically fills an open role and creates its responsibility tasks.
  Future<RoleAssignment> assign(String roleId, String teammateId);
}

typedef RoleRoster = (String caseId, List<TrialRole>, List<RoleAssignment>);

abstract interface class LiveRoleRepository implements RoleRepository {
  Stream<RoleRoster> watchRoleRoster();

  Future<RoleAssignment> assignForCase(
    String caseId,
    String roleId,
    String teammateId,
  );
}
