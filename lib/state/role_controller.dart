import '../data/models/trial_role.dart';
import '../data/models/role_assignment.dart';
import '../data/repositories/role_repository.dart';
import 'load_controller.dart';
import 'task_controller.dart';

class RoleController extends LoadController {
  RoleController(this._repository, this._tasks);
  final RoleRepository _repository;
  final TaskController _tasks;
  List<TrialRole> _roles = const [];
  List<RoleAssignment> _assignments = const [];
  bool _isLoaded = false;
  String? _caseId;
  String? get caseId => _caseId;
  bool _isSaving = false;
  bool _saveFailed = false;
  List<TrialRole> get roles => _roles;
  List<RoleAssignment> get assignments => _assignments;
  bool get isLoaded => _isLoaded;
  bool get isSaving => _isSaving;
  bool get saveFailed => _saveFailed;
  RoleAssignment? assignmentFor(String id) {
    for (final a in _assignments) {
      if (a.roleId == id) return a;
    }
    return null;
  }

  TrialRole? byId(String id) {
    for (final r in _roles) {
      if (r.id == id) return r;
    }
    return null;
  }

  void _syncTasks() =>
      _tasks.setRoleTasks(_assignments.expand((a) => a.tasks).toList());
  Future<void> load() async {
    if (_isSaving) return;
    final repository = _repository;
    if (repository is LiveRoleRepository) {
      await watchWith(repository.watchRoleRoster(), (result) {
        _caseId = result.$1;
        _roles = List.unmodifiable(result.$2);
        _assignments = List.unmodifiable(result.$3);
        _isLoaded = true;
      });
      return;
    }
    await loadWith(
      () async =>
          (await repository.fetchRoles(), await repository.fetchAssignments()),
      (result) {
        _roles = List.unmodifiable(result.$1);
        _assignments = List.unmodifiable(result.$2);
        _isLoaded = true;
        _syncTasks();
      },
    );
  }

  Future<bool> assign(
    String roleId,
    String teammateId, {
    String? expectedCaseId,
  }) async {
    final caseId = _caseId;
    final repository = _repository;
    if (isDisposed ||
        !_isLoaded ||
        isLoading ||
        loadFailed ||
        _isSaving ||
        (repository is LiveRoleRepository &&
            (caseId == null || expectedCaseId != caseId)) ||
        assignmentFor(roleId) != null) {
      return false;
    }
    _isSaving = true;
    _saveFailed = false;
    notifyListeners();
    try {
      if (repository is LiveRoleRepository) {
        await repository.assignForCase(caseId!, roleId, teammateId);
      } else {
        final assignment = await repository.assign(roleId, teammateId);
        if (isDisposed) return false;
        _assignments = List.unmodifiable([..._assignments, assignment]);
        _syncTasks();
      }
      if (isDisposed || _caseId != caseId) return false;
      return true;
    } catch (_) {
      if (!isDisposed && _caseId == caseId) _saveFailed = true;
      return false;
    } finally {
      if (!isDisposed) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }
}
