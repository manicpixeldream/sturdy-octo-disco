import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart' show StringCharacters;

import '../data/models/exam_script.dart';
import '../data/models/exam_question.dart';
import '../data/models/timing_rule.dart';
import '../data/models/trial_side.dart';
import '../data/models/citation.dart';
import '../data/repositories/exam_repository.dart';
import '../data/services/exam_suggestion_service.dart';
import 'case_controller.dart';
import 'research_controller.dart';
import 'load_controller.dart';

class ExamController extends LoadController {
  ExamController(
    this._repository,
    this._suggestions,
    this.cases,
    this._research,
  ) {
    cases.addListener(_caseChanged);
    _research.addListener(_syncCitations);
    _caseChanged();
  }
  final ExamRepository _repository;
  final ExamSuggestionService _suggestions;
  final CaseController cases;
  final ResearchController _research;
  String? _caseId;
  List<ExamScript> _scripts = const [];
  List<ExamScript> get scripts => _scripts;
  bool _loaded = false,
      _saving = false,
      _saveFailed = false,
      _suggesting = false,
      _suggestFailed = false;
  bool get isLoaded => _loaded;
  bool get isSaving => _saving;
  bool get saveFailed => _saveFailed;
  bool get isSuggesting => _suggesting;
  bool get suggestFailed => _suggestFailed;
  bool suggestFailedFor(String witnessId, TrialPhase phase) =>
      _suggestKey == '$witnessId:${phase.name}' && _suggestFailed;
  int _suggestVersion = 0, _caseVersion = 0;
  String? _failedScriptId;
  bool saveFailedFor(String witnessId, TrialPhase phase) =>
      _saveFailed && _failedScriptId == '$witnessId:${phase.name}';
  String? _suggestKey;
  List<String> _proposals = const [];
  List<String> suggestionsFor(String witnessId, TrialPhase phase) =>
      _suggestKey == '$witnessId:${phase.name}' ? _proposals : const [];
  void _caseChanged() {
    if (isDisposed) return;
    final id = cases.activeCase?.id;
    if (id != null && id != _caseId) {
      unawaited(load());
    } else {
      _syncCitations();
    }
  }

  Future<void> load() async {
    final id = cases.activeCase?.id;
    if (isDisposed || id == null || (_saving && id == _caseId)) return;
    if (id != _caseId) {
      _caseVersion++;
      _caseId = id;
      _loaded = false;
      _scripts = const [];
      _saving = false;
      _saveFailed = false;
      _suggestVersion++;
      _suggesting = false;
      _suggestFailed = false;
      _proposals = const [];
      _suggestKey = null;
    }
    await loadWith(() => _repository.fetchScripts(id), (scripts) {
      final ids = <String>{};
      for (final script in scripts) {
        if (!ids.add(script.id) || !_valid(script)) {
          throw StateError('Invalid script catalogue');
        }
      }
      _scripts = List.unmodifiable(scripts);
      _loaded = true;
      _syncCitations();
    });
  }

  bool _valid(ExamScript script) =>
      script.caseId == _caseId &&
      cases.witnessById(script.witnessId) != null &&
      script.questions.every(
        (q) => q.exhibitIds.every((id) => cases.exhibitById(id) != null),
      );
  ExamScript scriptFor(String witnessId, TrialPhase phase) =>
      _scripts
          .where((s) => s.witnessId == witnessId && s.phase == phase)
          .firstOrNull ??
      ExamScript(
        caseId: _caseId ?? 'unloaded',
        witnessId: witnessId,
        phase: phase,
      );
  final _questionRandom = Random.secure();

  String newQuestionId() =>
      'question_${List.generate(8, (_) => _questionRandom.nextInt(0x10000).toRadixString(16).padLeft(4, '0')).join()}';

  Future<bool> attachSource(
    String witnessId,
    TrialPhase phase,
    String questionId,
    String sourceId,
  ) async {
    final source = _research.sourceById(sourceId);
    final question = scriptFor(
      witnessId,
      phase,
    ).questions.where((question) => question.id == questionId).firstOrNull;
    if (source == null || question == null) return false;
    if (cases.exhibitById(sourceId) != null) {
      return question.exhibitIds.contains(sourceId) ||
          await upsertQuestion(
            witnessId,
            phase,
            question.copyWith(exhibitIds: [...question.exhibitIds, sourceId]),
          );
    }
    return question.sourceIds.contains(sourceId) ||
        await upsertQuestion(
          witnessId,
          phase,
          question.copyWith(sourceIds: [...question.sourceIds, sourceId]),
        );
  }

  TrialSide sideFor(String witnessId, TrialPhase phase) {
    final side = cases.witnessById(witnessId)!.side;
    return phase == TrialPhase.direct
        ? side
        : side == TrialSide.prosecution
        ? TrialSide.defense
        : TrialSide.prosecution;
  }

  TimingRule? ruleFor(TrialPhase phase) =>
      cases.timingRules.where((r) => r.phase == phase).firstOrNull;
  int budgetSeconds(String witnessId, TrialPhase phase) {
    final side = sideFor(witnessId, phase);
    if (ruleFor(phase)?.sharedAcrossWitnesses != true) {
      return scriptFor(witnessId, phase).estimatedSeconds;
    }
    return _scripts
        .where(
          (s) =>
              s.phase == phase &&
              cases.witnessById(s.witnessId) != null &&
              sideFor(s.witnessId, phase) == side,
        )
        .fold(0, (total, s) => total + s.estimatedSeconds);
  }

  bool overBudget(String witnessId, TrialPhase phase) {
    final rule = ruleFor(phase);
    return rule != null && budgetSeconds(witnessId, phase) > rule.minutes * 60;
  }

  Future<bool> save(ExamScript script) async {
    if (isDisposed || !_loaded || isLoading || _saving || !_valid(script)) {
      return false;
    }
    final caseId = _caseId;
    final version = _caseVersion;
    _saving = true;
    _saveFailed = false;
    notifyListeners();
    try {
      await _repository.saveScript(script);
      if (isDisposed || caseId != _caseId || version != _caseVersion) {
        return false;
      }
      _scripts = List.unmodifiable([
        ..._scripts.where((s) => s.id != script.id),
        script,
      ]);
      _syncCitations();
      return true;
    } catch (_) {
      if (!isDisposed && caseId == _caseId && version == _caseVersion) {
        _saveFailed = true;
        _failedScriptId = script.id;
      }
      return false;
    } finally {
      if (!isDisposed && caseId == _caseId && version == _caseVersion) {
        _saving = false;
        notifyListeners();
      }
    }
  }

  Future<bool> upsertQuestion(
    String witnessId,
    TrialPhase phase,
    ExamQuestion question,
  ) {
    final script = scriptFor(witnessId, phase);
    final questions = [...script.questions];
    final index = questions.indexWhere((q) => q.id == question.id);
    if (index == -1) {
      questions.add(question);
    } else {
      questions[index] = question;
    }
    return save(script.copyWith(questions: questions));
  }

  Future<bool> deleteQuestion(
    String witnessId,
    TrialPhase phase,
    String questionId,
  ) {
    final script = scriptFor(witnessId, phase);
    return save(
      script.copyWith(
        questions: script.questions.where((q) => q.id != questionId).toList(),
      ),
    );
  }

  Future<bool> moveQuestion(
    String witnessId,
    TrialPhase phase,
    int index,
    int delta,
  ) async {
    final script = scriptFor(witnessId, phase);
    if (index < 0 ||
        index >= script.questions.length ||
        index + delta < 0 ||
        index + delta >= script.questions.length) {
      return false;
    }
    final questions = [...script.questions];
    final question = questions.removeAt(index);
    questions.insert(index + delta, question);
    return save(script.copyWith(questions: questions));
  }

  Future<void> suggest(String witnessId, TrialPhase phase) async {
    final witness = cases.witnessById(witnessId);
    if (isDisposed || witness == null || _suggesting || !_loaded) return;
    final version = ++_suggestVersion;
    _suggestKey = '$witnessId:${phase.name}';
    _proposals = const [];
    _suggesting = true;
    _suggestFailed = false;
    notifyListeners();
    try {
      final proposals = await _suggestions
          .suggest(witness, phase)
          .timeout(const Duration(seconds: 20));
      if (isDisposed || version != _suggestVersion) return;
      if (proposals.any(
        (p) => p.trim().isEmpty || p.trim().characters.length > 2000,
      )) {
        throw StateError('Invalid suggestions');
      }
      _proposals = List.unmodifiable(proposals.map((p) => p.trim()));
    } catch (_) {
      if (!isDisposed && version == _suggestVersion) _suggestFailed = true;
    } finally {
      if (!isDisposed && version == _suggestVersion) {
        _suggesting = false;
        notifyListeners();
      }
    }
  }

  void _syncCitations() {
    if (isDisposed || !_loaded || _caseId == null) return;
    _research.replaceExamCitations(_caseId!, [
      for (final script in _scripts.where(_valid))
        for (final q in script.questions)
          for (final sourceId in {...q.exhibitIds, ...q.sourceIds})
            Citation(
              sourceId: sourceId,
              location: CitationLocation.examQuestion,
              referenceId: '${script.witnessId}|${script.phase.name}|${q.id}',
              label:
                  '${cases.witnessById(script.witnessId)?.name} · ${script.phase.label}: ${q.text}',
            ),
    ]);
  }

  @override
  void dispose() {
    cases.removeListener(_caseChanged);
    _research.removeListener(_syncCitations);
    _suggestVersion++;
    super.dispose();
  }
}
