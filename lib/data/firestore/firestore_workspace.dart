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

Never _readOnly() => throw UnsupportedError('Shared workspace is read-only.');

class FirestoreWorkspace {
  FirestoreWorkspace(FirebaseFirestore database, String teamId)
    : _team = database.collection('teams').doc(teamId);

  final _Document _team;
  late final cases = FirestoreCaseRepository(_team);
  late final team = FirestoreTeamRepository(_team);
  late final tasks = FirestoreTaskRepository(_team);
  late final schedule = FirestoreScheduleRepository(_team);
  late final chat = FirestoreChatRepository(_team);
  late final roles = FirestoreReadOnlyRoles();
}

class FirestoreCaseRepository implements LiveCaseRepository, CaseBriefService {
  FirestoreCaseRepository(this._team);
  final _Document _team;

  _Document _case(String id) => _team.collection('cases').doc(id);

  String _activeId(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final id = _data(snapshot)['activeCaseId'];
    if (id is! String || id.isEmpty || id.contains('/')) {
      throw StateError('No active case has been configured.');
    }
    return id;
  }

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
  Stream<CasePacket> watchCase() => Stream.multi((output) {
    StreamSubscription<CasePacket>? packet;
    var generation = 0;
    String? activeId;
    void stopPacket() {
      generation++;
      activeId = null;
      unawaited(packet?.cancel());
      packet = null;
    }

    final team = _team
        .snapshots()
        .map(_activeId)
        .listen(
          (id) {
            if (activeId == id) return;
            stopPacket();
            activeId = id;
            final current = generation;
            packet = _watchPacket(id).listen(
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

  Stream<CasePacket> _watchPacket(String id) => Stream.multi((output) {
    CaseFile? file;
    List<Exhibit>? exhibits;
    List<Witness>? witnesses;
    List<Affidavit>? affidavits;
    List<Stipulation>? stipulations;
    List<TimingRule>? rules;
    StreamSubscription<T> watch<T>(Stream<T> stream, void Function(T) apply) =>
        stream.listen((value) {
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
        }, onError: output.addError);

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
    return _watchCaseFile(_activeId(snapshot)).first;
  }

  @override
  Future<List<Exhibit>> fetchExhibits(String caseId) => _exhibits(caseId).first;
  @override
  Future<List<Witness>> fetchWitnesses(String caseId) =>
      _witnesses(caseId).first;
  @override
  Future<List<Affidavit>> fetchAffidavits(String caseId) =>
      _affidavits(caseId).first;
  @override
  Future<List<Stipulation>> fetchStipulations(String caseId) =>
      _stipulations(caseId).first;
  @override
  Future<List<TimingRule>> fetchTimingRules(String caseId) =>
      _timingRules(caseId).first;
  @override
  Future<CaseBrief> fetchBrief(String caseId) async => CaseBrief.fromMap(
    _data(await _case(caseId).collection('brief').doc('current').get()),
  );
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

class FirestoreTaskRepository implements LiveTaskRepository {
  FirestoreTaskRepository(this._team);
  final _Document _team;
  @override
  Stream<List<TaskItem>> watchTasks() =>
      _records(_team, 'tasks', TaskItem.fromMap);
  @override
  Future<List<TaskItem>> fetchTasks() => watchTasks().first;
  @override
  Future<TaskItem> setCompleted(TaskItem task, bool completed) async =>
      _readOnly();
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
  @override
  Stream<List<ChatMessage>> watchMessages(String caseId) => _team
      .collection('chat')
      .where('caseId', isEqualTo: caseId)
      .snapshots()
      .map(
        (snapshot) =>
            [
              for (final document in snapshot.docs)
                ChatMessage.fromMap(_data(document)),
            ]..sort((a, b) {
              final order = a.createdAt.compareTo(b.createdAt);
              return order == 0 ? a.id.compareTo(b.id) : order;
            }),
      );
  @override
  Future<List<ChatMessage>> fetchMessages(String caseId) =>
      watchMessages(caseId).first;
  @override
  Future<ChatMessage> sendMessage(ChatMessage message) async => _readOnly();
}

class FirestoreReadOnlyRoles implements RoleRepository {
  @override
  Future<List<TrialRole>> fetchRoles() async => const [];
  @override
  Future<List<RoleAssignment>> fetchAssignments() async => const [];
  @override
  Future<RoleAssignment> assign(String roleId, String teammateId) async =>
      _readOnly();
}
