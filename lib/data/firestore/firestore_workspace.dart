import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/affidavit.dart';
import '../models/case_brief.dart';
import '../models/case_file.dart';
import '../models/chat_message.dart';
import '../models/exhibit.dart';
import '../models/practice_session.dart';
import '../models/role_assignment.dart';
import '../models/stipulation.dart';
import '../models/task_item.dart';
import '../models/teammate.dart';
import '../models/timing_rule.dart';
import '../models/trial_role.dart';
import '../models/witness.dart';
import '../repositories/case_repository.dart';
import '../repositories/chat_repository.dart';
import '../repositories/role_repository.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/team_repository.dart';
import '../services/case_brief_service.dart';

typedef _Document = DocumentReference<Map<String, dynamic>>;

Map<String, Object?> _data(DocumentSnapshot<Map<String, dynamic>> snapshot) {
  final data = snapshot.data();
  if (data == null) throw StateError('Missing document: ${snapshot.id}');
  return {...data, 'id': snapshot.id};
}

Stream<List<T>> _records<T>(
  _Document parent,
  String name,
  T Function(Map<String, Object?>) decode,
) => parent
    .collection(name)
    .snapshots()
    .map(
      (snapshot) => [
        for (final document in snapshot.docs) decode(_data(document)),
      ],
    );

Future<List<T>> _fetchRecords<T>(
  _Document parent,
  String name,
  T Function(Map<String, Object?>) decode,
) async {
  final snapshot = await parent.collection(name).get();
  return [for (final document in snapshot.docs) decode(_data(document))];
}

String _activeCaseId(DocumentSnapshot<Map<String, dynamic>> snapshot) {
  final id = _data(snapshot)['activeCaseId'];
  if (id is! String || id.isEmpty || id.contains('/')) {
    throw StateError('No active case has been configured.');
  }
  return id;
}

Stream<T> _watchActiveCase<T>(
  _Document teamDocument,
  Stream<T> Function(String) read,
) => Stream.multi((output) {
  StreamSubscription<T>? packet;
  var generation = 0;
  String? activeId;
  void stopPacket() {
    generation++;
    activeId = null;
    unawaited(packet?.cancel());
    packet = null;
  }

  final team = teamDocument
      .snapshots()
      .map(_activeCaseId)
      .listen(
        (id) {
          if (activeId == id) return;
          stopPacket();
          activeId = id;
          final current = generation;
          packet = read(id).listen(
            (value) {
              if (current == generation) output.add(value);
            },
            onError: (Object error, StackTrace stack) {
              if (current == generation) output.addError(error, stack);
            },
          );
        },
        onError: (Object error, StackTrace stack) {
          stopPacket();
          output.addError(error, stack);
        },
      );
  output.onCancel = () async {
    stopPacket();
    await team.cancel();
  };
});

class FirestoreWorkspace {
  FirestoreWorkspace(FirebaseFirestore database, String teamId)
    : _team = database.collection('teams').doc(teamId);

  final _Document _team;
  late final cases = FirestoreCaseRepository(_team);
  late final team = FirestoreTeamRepository(_team);
  late final tasks = FirestoreTaskRepository(_team);
  late final schedule = FirestoreScheduleRepository(_team);
  late final chat = FirestoreChatRepository(_team);
  late final roles = FirestoreRoleRepository(_team);
}

class FirestoreCaseRepository
    implements LiveCaseRepository, LiveCaseBriefService {
  FirestoreCaseRepository(this._team);
  final _Document _team;

  _Document _case(String id) => _team.collection('cases').doc(id);

  Stream<CaseFile> _watchCaseFile(String id) =>
      _case(id)
          .snapshots()
          .map((snapshot) => CaseFile.fromMap(_data(snapshot)));

  Stream<List<Exhibit>> _exhibits(String id) => _records(
    _case(id),
    'exhibits',
    Exhibit.fromMap,
  ).map((items) => items..sort((a, b) => a.number.compareTo(b.number)));
  Stream<List<Witness>> _witnesses(String id) =>
      _records(_case(id), 'witnesses', Witness.fromMap);
  Stream<List<Affidavit>> _affidavits(String id) =>
      _records(_case(id), 'affidavits', Affidavit.fromMap);
  Stream<List<Stipulation>> _stipulations(String id) => _records(
    _case(id),
    'stipulations',
    Stipulation.fromMap,
  ).map((items) => items..sort((a, b) => a.number.compareTo(b.number)));
  Stream<List<TimingRule>> _timingRules(String id) =>
      _records(_case(id), 'timingRules', TimingRule.fromMap).map(
        (items) =>
            items..sort((a, b) => a.phase.index.compareTo(b.phase.index)),
      );

  @override
  Stream<CasePacket> watchCase() => _watchActiveCase(_team, _watchPacket);

  Stream<CasePacket> _watchPacket(String id) => Stream.multi((output) {
    CaseFile? file;
    List<Exhibit>? exhibits;
    List<Witness>? witnesses;
    List<Affidavit>? affidavits;
    List<Stipulation>? stipulations;
    List<TimingRule>? rules;
    StreamSubscription<T> watch<T>(Stream<T> stream, void Function(T?) apply) =>
        stream.listen(
          (value) {
            apply(value);
            if ((file, exhibits, witnesses, affidavits, stipulations, rules)
                case (
                  final f?,
                  final e?,
                  final w?,
                  final a?,
                  final s?,
                  final r?,
                )) {
              output.add((f, (e, w, a, s, r)));
            }
          },
          onError: (Object error, StackTrace stack) {
            apply(null);
            output.addError(error, stack);
          },
        );

    final subscriptions = [
      watch(_watchCaseFile(id), (value) => file = value),
      watch(_exhibits(id), (value) => exhibits = value),
      watch(_witnesses(id), (value) => witnesses = value),
      watch(_affidavits(id), (value) => affidavits = value),
      watch(_stipulations(id), (value) => stipulations = value),
      watch(_timingRules(id), (value) => rules = value),
    ];
    output.onCancel = () => Future.wait(subscriptions.map((s) => s.cancel()));
  });

  @override
  Future<CaseFile> fetchActiveCase() async {
    final snapshot = await _team.get();
    return _watchCaseFile(_activeCaseId(snapshot)).first;
  }

  @override
  Future<List<Exhibit>> fetchExhibits(String caseId) async =>
      (await _fetchRecords(_case(caseId), 'exhibits', Exhibit.fromMap))
        ..sort((a, b) => a.number.compareTo(b.number));
  @override
  Future<List<Witness>> fetchWitnesses(String caseId) =>
      _witnesses(caseId).first;
  @override
  Future<List<Affidavit>> fetchAffidavits(String caseId) =>
      _fetchRecords(_case(caseId), 'affidavits', Affidavit.fromMap);
  @override
  Future<List<Stipulation>> fetchStipulations(String caseId) =>
      _stipulations(caseId).first;
  @override
  Future<List<TimingRule>> fetchTimingRules(String caseId) =>
      _timingRules(caseId).first;
  _Document _brief(String caseId) =>
      _case(caseId).collection('brief').doc('current');

  @override
  Stream<CaseBrief?> watchBrief(String caseId) => _brief(caseId)
      .snapshots(includeMetadataChanges: true)
      .where((snapshot) => snapshot.exists || !snapshot.metadata.isFromCache)
      .map(
        (snapshot) =>
            snapshot.exists ? CaseBrief.fromMap(_data(snapshot)) : null,
      )
      .distinct();

  @override
  Future<CaseBrief> fetchBrief(String caseId) async =>
      CaseBrief.fromMap(_data(await _brief(caseId).get()));
}

class FirestoreTeamRepository implements LiveTeamRepository {
  FirestoreTeamRepository(this._team);
  final _Document _team;
  @override
  Stream<List<Teammate>> watchTeammates() =>
      _records(_team, 'members', Teammate.fromMap);
  @override
  Future<List<Teammate>> fetchTeammates() => watchTeammates().first;
}

class FirestoreTaskRepository
    implements LiveTaskRepository, FollowUpTaskRepository {
  FirestoreTaskRepository(this._team);
  final _Document _team;

  @override
  Stream<List<TaskItem>> watchTasks() => _team
      .collection('tasks')
      .snapshots(includeMetadataChanges: true)
      .where((snapshot) => !snapshot.metadata.hasPendingWrites)
      .map(
        (snapshot) => [
          for (final document in snapshot.docs)
            TaskItem.fromMap(_data(document)),
        ],
      );

  @override
  Future<List<TaskItem>> fetchTasks() => watchTasks().first;

  @override
  Future<TaskItem> setCompleted(TaskItem task, bool completed) {
    final document = _team.collection('tasks').doc(task.id);
    return _team.firestore.runTransaction((transaction) async {
      final latest = TaskItem.fromMap(_data(await transaction.get(document)));
      transaction.update(document, {'isDone': completed});
      return latest.copyWith(isDone: completed);
    });
  }

  @override
  Future<void> createFollowUp(String sessionId, TaskItem task) {
    final document = _team.collection('tasks').doc(task.id);
    final payload = task.toMap()..['sessionId'] = sessionId;
    return _team.firestore.runTransaction((transaction) async {
      final previous = await transaction.get(document);
      if (!previous.exists) {
        transaction.set(document, payload);
        return;
      }
      final data = _data(previous);
      if (data['sessionId'] != sessionId ||
          TaskItem.fromMap(data).copyWith(isDone: false) != task) {
        throw StateError('Conflicting follow-up task.');
      }
    });
  }
}

class FirestoreScheduleRepository implements LiveScheduleRepository {
  FirestoreScheduleRepository(this._team);
  final _Document _team;
  @override
  Stream<List<PracticeSession>> watchSessions() =>
      _records(_team, 'sessions', PracticeSession.fromMap);
  @override
  Future<List<PracticeSession>> fetchSessions() => watchSessions().first;
}

class FirestoreChatRepository implements LiveChatRepository {
  FirestoreChatRepository(this._team);
  final _Document _team;

  ChatMessage _decode(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = _data(document);
    if (data['createdAt'] case final Timestamp time) {
      data['createdAt'] = time.toDate().toUtc().toIso8601String();
    }
    return ChatMessage.fromMap(data);
  }

  ChatMessage? _decodeHistory(DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.metadata.hasPendingWrites) return null;
    try {
      return _decode(document);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String caseId) => _team
      .collection('chat')
      .where('caseId', isEqualTo: caseId)
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) =>
            [for (final document in snapshot.docs) ?_decodeHistory(document)]
              ..sort((a, b) {
                final order = a.createdAt.compareTo(b.createdAt);
                return order == 0 ? a.id.compareTo(b.id) : order;
              }),
      );

  @override
  Future<List<ChatMessage>> fetchMessages(String caseId) =>
      watchMessages(caseId).first;

  @override
  Future<ChatMessage> sendMessage(ChatMessage message) {
    final document = _team.collection('chat').doc(message.id);
    return _team.firestore.runTransaction((transaction) async {
      final previous = await transaction.get(document);
      if (previous.exists) {
        final saved = _decode(previous);
        if (!saved.samePayloadAs(message)) {
          throw StateError('Conflicting message ID.');
        }
        return saved;
      }
      transaction.set(
        document,
        message.toMap()
          ..remove('id')
          ..['createdAt'] = FieldValue.serverTimestamp(),
      );
      return message;
    });
  }
}

class FirestoreRoleRepository implements LiveRoleRepository {
  FirestoreRoleRepository(this._team);
  final _Document _team;

  _Document _case(String caseId) => _team.collection('cases').doc(caseId);

  @override
  Stream<RoleRoster> watchRoleRoster() => _watchActiveCase(
    _team,
    (caseId) =>
        _case(caseId)
            .collection('roles')
            .snapshots(includeMetadataChanges: true)
            .where((snapshot) => !snapshot.metadata.hasPendingWrites)
            .map((snapshot) {
              final roles = <TrialRole>[];
              final assignments = <RoleAssignment>[];
              for (final document in snapshot.docs) {
                final data = _data(document);
                final role = TrialRole.fromMap(data);
                roles.add(role);
                if (data['assigneeId'] case final String assigneeId) {
                  assignments.add(
                    RoleAssignment(
                      roleId: role.id,
                      teammateId: assigneeId,
                      tasks: const [],
                    ),
                  );
                }
              }
              return (caseId, roles, assignments);
            }),
  );

  @override
  Future<List<TrialRole>> fetchRoles() async =>
      (await watchRoleRoster().first).$2;

  @override
  Future<List<RoleAssignment>> fetchAssignments() async =>
      (await watchRoleRoster().first).$3;

  @override
  Future<RoleAssignment> assign(String roleId, String teammateId) async =>
      assignForCase(_activeCaseId(await _team.get()), roleId, teammateId);

  @override
  Future<RoleAssignment> assignForCase(
    String caseId,
    String roleId,
    String teammateId,
  ) {
    final caseFile = _case(caseId);
    final roleDocument = caseFile.collection('roles').doc(roleId);
    return _team.firestore.runTransaction((transaction) async {
      if (_activeCaseId(await transaction.get(_team)) != caseId) {
        throw StateError('The active case changed.');
      }
      final packet = _data(await transaction.get(caseFile));
      final data = _data(await transaction.get(roleDocument));
      final role = TrialRole.fromMap(data);
      final dueDate = packet['trialDate']! as String;
      final assignee = data['assigneeId'];
      if (assignee != null && assignee != teammateId) {
        throw StateError('Role already assigned.');
      }
      if (role.responsibilities.isEmpty || role.responsibilities.length > 3) {
        throw StateError('Shared roles require one to three responsibilities.');
      }
      final tasks = [
        for (final (index, item) in role.responsibilities.indexed)
          TaskItem(
            id: 'role.$caseId.$roleId.$index',
            title: '${role.title}: $item',
            assigneeId: teammateId,
            dueDate: DateTime.parse(dueDate),
          ),
      ];
      if (assignee == null) {
        transaction.update(roleDocument, {'assigneeId': teammateId});
        for (final (index, task) in tasks.indexed) {
          transaction.set(_team.collection('tasks').doc(task.id), {
            ...task.toMap(),
            'dueDate': dueDate,
            'caseId': caseId,
            'roleId': roleId,
            'responsibilityIndex': index,
          });
        }
      }
      return RoleAssignment(
        roleId: roleId,
        teammateId: teammateId,
        tasks: tasks,
      );
    });
  }
}
