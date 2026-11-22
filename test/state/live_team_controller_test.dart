import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/models/teammate.dart';
import 'package:gavel/data/repositories/team_repository.dart';
import 'package:gavel/state/team_controller.dart';

class _LiveTeam implements LiveTeamRepository {
  final reads = <StreamController<List<Teammate>>>[];

  @override
  Future<List<Teammate>> fetchTeammates() => throw UnimplementedError();

  @override
  Stream<List<Teammate>> watchTeammates() {
    final read = StreamController<List<Teammate>>();
    reads.add(read);
    return read.stream;
  }
}

void main() {
  test('live roster updates, retries, and releases its listener', () async {
    final repo = _LiveTeam();
    final team = TeamController(repo);
    const first = Teammate(id: 'first', name: 'First');
    const second = Teammate(id: 'second', name: 'Second');
    final initialLoad = team.load();
    expect(team.isLoading, isTrue);
    repo.reads.first.add([first]);
    await initialLoad;
    expect(team.teammates, [first]);

    repo.reads.first.add([second]);
    await Future<void>.delayed(Duration.zero);
    expect(team.teammates, [second]);
    repo.reads.first.addError(StateError('Permission denied'));
    await Future<void>.delayed(Duration.zero);
    expect(team.loadFailed, isTrue);

    final retry = team.load();
    expect(repo.reads.first.hasListener, isFalse);
    repo.reads.last.add([first, second]);
    await retry;
    expect(team.loadFailed, isFalse);
    expect(team.teammates, [first, second]);

    team.dispose();
    expect(repo.reads.last.hasListener, isFalse);
    for (final read in repo.reads) {
      await read.close();
    }
  });
}
