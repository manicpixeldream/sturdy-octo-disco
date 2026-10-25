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
    await loadWith(
      () async => (
        await _repository.fetchRoles(),
        await _repository.fetchAssignments(),
      ),
      (result) {
        _roles = List.unmodifiable(result.$1);
        _assignments = List.unmodifiable(result.$2);
        _isLoaded = true;
        _syncTasks();
      },
    );
  }

  Future<bool> assign(String roleId, String teammateId) async {
    if (isDisposed ||
        !_isLoaded ||
        isLoading ||
        _isSaving ||
        assignmentFor(roleId) != null) {
      return false;
    }
    _isSaving = true;
    _saveFailed = false;
    notifyListeners();
    try {
      final assignment = await _repository.assign(roleId, teammateId);
      if (isDisposed) return false;
      _assignments = List.unmodifiable([..._assignments, assignment]);
      _syncTasks();
      return true;
    } catch (_) {
      if (!isDisposed) _saveFailed = true;
      return false;
    } finally {
      if (!isDisposed) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }
}
