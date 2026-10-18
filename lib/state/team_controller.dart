import 'load_controller.dart';

import '../data/models/teammate.dart';
import '../data/repositories/team_repository.dart';

class TeamController extends LoadController {
  TeamController(this._repository);

  final TeamRepository _repository;

  List<Teammate>? _teammates;

  bool get isLoaded => _teammates != null;
  List<Teammate> get teammates => _teammates ?? const [];

  Teammate? byId(String id) {
    for (final teammate in teammates) {
      if (teammate.id == id) return teammate;
    }
    return null;
  }

  Future<void> load() async {
    await loadWith(
      _repository.fetchTeammates,
      (records) => _teammates = List.unmodifiable(records),
    );
  }
}
