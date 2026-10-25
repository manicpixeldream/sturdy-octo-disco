import '../models/trial_role.dart';
import '../models/role_assignment.dart';
import '../models/task_item.dart';
import '../repositories/role_repository.dart';

class MockRoleRepository implements RoleRepository {
  MockRoleRepository({required Set<String> memberIds, required this.dueDate})
    : memberIds = Set.unmodifiable(memberIds);
  final Set<String> memberIds;
  final DateTime dueDate;
  final Map<String, RoleAssignment> _assignments = {};
  static final List<TrialRole> roles = List.unmodifiable([
    TrialRole(
      id: 'prosecution_opening',
      title: 'Opening attorney',
      side: 'Prosecution',
      responsibilities: [
        'Outline the prosecution theory',
        'Rehearse the opening within five minutes',
      ],
    ),
    TrialRole(
      id: 'prosecution_closing',
      title: 'Closing attorney',
      side: 'Prosecution',
      responsibilities: [
        'Connect admitted evidence to the elements',
        'Rehearse the prosecution closing',
      ],
    ),
    TrialRole(
      id: 'defense_opening',
      title: 'Opening attorney',
      side: 'Defense',
      responsibilities: [
        'Outline the defense theory',
        'Rehearse the opening within five minutes',
      ],
    ),
    TrialRole(
      id: 'defense_closing',
      title: 'Closing attorney',
      side: 'Defense',
      responsibilities: [
        'Identify reasonable-doubt arguments',
        'Rehearse the defense closing',
      ],
    ),
    for (final side in ['Prosecution', 'Defense']) ...[
      TrialRole(
        id: '${side.toLowerCase()}_direct',
        title: 'Direct examination attorney',
        side: side,
        responsibilities: [
          'Plan witness foundations and evidence links',
          'Rehearse the shared direct-examination budget',
        ],
      ),
      TrialRole(
        id: '${side.toLowerCase()}_cross',
        title: 'Cross examination attorney',
        side: side,
        responsibilities: [
          'Prepare focused cross-examination questions',
          'Rehearse the shared cross-examination budget',
        ],
      ),
    ],
    TrialRole(
      id: 'witness_okafor',
      title: 'Mara Okafor',
      side: 'Prosecution',
      isWitness: true,
      responsibilities: [
        'Study the Okafor affidavit',
        'Rehearse direct and cross examination',
      ],
    ),
    TrialRole(
      id: 'witness_harmon',
      title: 'Casey Harmon',
      side: 'Defense',
      isWitness: true,
      responsibilities: [
        'Study the Harmon affidavit',
        'Rehearse direct and cross examination',
      ],
    ),
    TrialRole(
      id: 'witness_reyes',
      title: 'Officer Dana Reyes',
      side: 'Prosecution',
      isWitness: true,
      responsibilities: [
        'Study the Reyes affidavit',
        'Rehearse direct and cross examination',
      ],
    ),
    TrialRole(
      id: 'witness_ortiz',
      title: 'Dr. Lena Ortiz',
      side: 'Prosecution',
      isWitness: true,
      responsibilities: [
        'Study the Ortiz affidavit',
        'Rehearse expert testimony',
      ],
    ),
    TrialRole(
      id: 'witness_lindqvist',
      title: 'Theo Lindqvist',
      side: 'Defense',
      isWitness: true,
      responsibilities: [
        'Study the Lindqvist affidavit',
        'Rehearse direct and cross examination',
      ],
    ),
    TrialRole(
      id: 'witness_menon',
      title: 'Dr. Ravi Menon',
      side: 'Defense',
      isWitness: true,
      responsibilities: [
        'Study the Menon affidavit',
        'Rehearse expert testimony',
      ],
    ),
  ]);
  @override
  Future<List<TrialRole>> fetchRoles() async => roles;
  @override
  Future<List<RoleAssignment>> fetchAssignments() async =>
      List.unmodifiable(_assignments.values);
  @override
  Future<RoleAssignment> assign(String roleId, String teammateId) async {
    if (!memberIds.contains(teammateId)) throw StateError('Unknown teammate');
    final role = roles.firstWhere((r) => r.id == roleId);
    if (_assignments.containsKey(roleId)) {
      throw StateError('Role already assigned');
    }
    final assignment = RoleAssignment(
      roleId: roleId,
      teammateId: teammateId,
      tasks: [
        for (var i = 0; i < role.responsibilities.length; i++)
          TaskItem(
            id: 'role_${role.id}_$i',
            title: '${role.title}: ${role.responsibilities[i]}',
            assigneeId: teammateId,
            dueDate: dueDate,
          ),
      ],
    );
    _assignments[roleId] = assignment;
    return assignment;
  }
}
