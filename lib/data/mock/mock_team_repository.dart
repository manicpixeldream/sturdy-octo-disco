import '../models/teammate.dart';
import '../repositories/team_repository.dart';

class MockTeamRepository implements TeamRepository {
  MockTeamRepository(List<Teammate> teammates)
    : _teammates = List.unmodifiable(teammates);

  final List<Teammate> _teammates;

  @override
  Future<List<Teammate>> fetchTeammates() async => _teammates;
}
