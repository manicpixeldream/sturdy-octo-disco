import '../models/teammate.dart';

abstract interface class TeamRepository {
  Future<List<Teammate>> fetchTeammates();
}

abstract interface class LiveTeamRepository implements TeamRepository {
  Stream<List<Teammate>> watchTeammates();
}
