import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/mock/mock_schedule_repository.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/data/models/chat_message.dart';

void main() {
  test('export the Harmon packet for a Firestore team', () async {
    const output = String.fromEnvironment('HARMON_OUTPUT');
    const memberUid = String.fromEnvironment('HARMON_MEMBER_UID');
    if (output.isEmpty || memberUid.isEmpty || memberUid.contains('/')) {
      fail('Pass HARMON_OUTPUT and HARMON_MEMBER_UID using --dart-define.');
    }
    final today = DateTime.now();
    final seed = SeedData.harmon(today: today);
    String remap(String id) => id == seed.currentTeammateId ? memberUid : id;
    final members = [
      for (final member in seed.teammates)
        member.copyWith(id: remap(member.id)),
    ];
    final sessions = await MockScheduleRepository.demo(
      today,
      members.map((member) => member.id).toList(),
    ).fetchSessions();
    final casePath = 'cases/${seed.caseFile.id}';
    final documents = <String, Map<String, Object?>>{
      casePath: seed.caseFile.toMap(),
      for (final item in seed.exhibits)
        '$casePath/exhibits/${item.id}': item.toMap(),
      for (final item in seed.witnesses)
        '$casePath/witnesses/${item.id}': item.toMap(),
      for (final item in seed.affidavits)
        '$casePath/affidavits/${item.id}': item.toMap(),
      for (final item in seed.stipulations)
        '$casePath/stipulations/${item.id}': item.toMap(),
      for (final item in seed.timingRules)
        '$casePath/timingRules/${item.id}': item.toMap(),
      '$casePath/brief/current': seed.caseBrief.toMap(),
      for (final item in members) 'members/${item.id}': item.toMap(),
      for (final item in seed.tasks)
        'tasks/${item.id}': item
            .copyWith(assigneeId: remap(item.assigneeId))
            .toMap(),
      for (final item in sessions)
        'sessions/${item.id}': item
            .copyWith(startsAt: item.startsAt.toUtc())
            .toMap(),
      'chat/harmon_welcome': ChatMessage(
        id: 'harmon_welcome',
        caseId: seed.caseFile.id,
        senderId: members.last.id,
        text: 'Welcome to the State v. Harmon practice workspace.',
        createdAt: today.toUtc(),
        mentions: const [],
      ).toMap(),
    };
    await File(output).writeAsString(
      const JsonEncoder.withIndent('  ')
          .convert({'activeCaseId': seed.caseFile.id, 'documents': documents}),
    );
  });
}
