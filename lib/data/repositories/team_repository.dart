import '../models/teammate.dart';

abstract interface class TeamRepository {
  Future<List<Teammate>> fetchTeammates();
}
