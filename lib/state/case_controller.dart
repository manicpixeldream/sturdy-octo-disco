import 'dart:async';

import 'package:flutter/foundation.dart';

import 'load_controller.dart';

import '../core/clock.dart';
import '../core/storage/workspace_storage.dart';
import '../core/dates.dart';
import '../data/models/case_file.dart';
import '../data/models/affidavit.dart';
import '../data/models/case_brief.dart';
import '../data/models/stipulation.dart';
import '../data/models/timing_rule.dart';
import '../data/models/exhibit.dart';
import '../data/models/witness.dart';
import '../data/repositories/case_repository.dart';
import '../data/services/case_brief_service.dart';

class CaseController extends LoadController {
  CaseController(
    this._repository,
    this._clock, {
    this.briefService,
    this.storage,
  });

  final WorkspaceStorage? storage;

  final CaseRepository _repository;
  final Clock _clock;
  final CaseBriefService? briefService;
  int _loadGeneration = 0;
  int _briefRequest = 0;
  StreamSubscription<CaseBrief?>? _briefSubscription;
  Completer<void>? _briefInitial;
  int _sourceRevision = 0;

  bool get isLive => _repository is LiveCaseRepository;
  int get sourceRevision => _sourceRevision;

  final _argumentSources = <(String, TrialPhase), Set<String>>{};
  final _argumentDrafts = <(String, TrialPhase), String>{};
  CaseFile? _activeCase;
  List<Exhibit> _exhibits = const [];
  List<Witness> _witnesses = const [];
  List<Affidavit> _affidavits = const [];
  List<Stipulation> _stipulations = const [];
  List<TimingRule> _timingRules = const [];
  CaseBrief? _brief;
  bool _isBriefLoading = false;
  bool _briefFailed = false;

  bool get isLoaded => _activeCase != null;
  CaseFile? get activeCase => _activeCase;
  List<Exhibit> get exhibits => _exhibits;
  List<Witness> get witnesses => _witnesses;
  List<Affidavit> get affidavits => _affidavits;
  List<Stipulation> get stipulations => _stipulations;
  List<TimingRule> get timingRules => _timingRules;
  CaseBrief? get brief => _brief;
  bool get isBriefLoading => _isBriefLoading;
  bool get briefFailed => _briefFailed;

  String argumentDraft(String caseId, TrialPhase phase) =>
      _argumentDrafts[(caseId, phase)] ?? '';

  void updateArgumentDraft(String caseId, TrialPhase phase, String text) {
    final key = (caseId, phase);
    if (text.isEmpty) {
      _argumentDrafts.remove(key);
    } else {
      _argumentDrafts[key] = text;
    }
    storage?.write('argument.$caseId.${phase.name}', text);
  }

  Set<String> argumentSources(String caseId, TrialPhase phase) =>
      Set.unmodifiable(_argumentSources[(caseId, phase)] ?? const {});

  bool attachArgumentSource(String caseId, TrialPhase phase, String sourceId) {
    if (isDisposed || _activeCase?.id != caseId) return false;
    final sources = _argumentSources.putIfAbsent((caseId, phase), () => {});
    if (sources.add(sourceId)) {
      storage?.write('argumentSources.$caseId.${phase.name}', sources.toList());
      notifyListeners();
    }
    return true;
  }

  void detachArgumentSource(String caseId, TrialPhase phase, String sourceId) {
    if (isDisposed || _activeCase?.id != caseId) return;
    final sources = _argumentSources[(caseId, phase)];
    if (sources != null && sources.remove(sourceId)) {
      storage?.write('argumentSources.$caseId.${phase.name}', sources.toList());
      notifyListeners();
    }
  }

  Exhibit? exhibitById(String id) =>
      _exhibits.where((e) => e.id == id).firstOrNull;

  Affidavit? affidavitById(String id) =>
      _affidavits.where((a) => a.id == id).firstOrNull;

  Witness? witnessById(String id) =>
      _witnesses.where((w) => w.id == id).firstOrNull;

  /// Negative once the trial date has passed.
  int get daysUntilTrial {
    final activeCase = _activeCase;
    if (activeCase == null) return 0;
    return daysBetween(_clock.now(), activeCase.trialDate);
  }

  Future<void> load() async {
    if (isDisposed) return;
    ++_loadGeneration;
    ++_briefRequest;
    _cancelBrief();
    _isBriefLoading = false;
    final repository = _repository;
    if (repository is LiveCaseRepository) {
      var firstPacket = true;
      await watchWith(repository.watchCase(), (packet) {
        final changedCase = _activeCase?.id != packet.$1.id;
        _apply(packet);
        if (firstPacket || changedCase) {
          firstPacket = false;
          unawaited(loadBrief());
        }
      });
      return;
    }
    _brief = null;
    _briefFailed = false;
    final loaded = await loadWith(() async {
      final activeCase = await _repository.fetchActiveCase();
      final materials = await (
        _repository.fetchExhibits(activeCase.id),
        _repository.fetchWitnesses(activeCase.id),
        _repository.fetchAffidavits(activeCase.id),
        _repository.fetchStipulations(activeCase.id),
        _repository.fetchTimingRules(activeCase.id),
      ).wait;
      return (activeCase, materials);
    }, _apply);
    if (loaded) await loadBrief();
  }

  void _apply(CasePacket result) {
    final (
      activeCase,
      (exhibits, witnesses, affidavits, stipulations, timingRules),
    ) = result;
    if (_activeCase?.id != activeCase.id) {
      _brief = null;
      _briefFailed = false;
      final caseId = activeCase.id;
      for (final phase in const [TrialPhase.opening, TrialPhase.closing]) {
        final draft = storage?.read(
          'argument.$caseId.${phase.name}',
          (value) => value as String,
        );
        if (draft != null) _argumentDrafts[(caseId, phase)] = draft;
        final sources = storage?.read(
          'argumentSources.$caseId.${phase.name}',
          (value) => Set<String>.from(value as List),
        );
        if (sources != null) _argumentSources[(caseId, phase)] = sources;
      }
    }
    if (_activeCase?.id != activeCase.id ||
        !listEquals(_exhibits, exhibits) ||
        !listEquals(_affidavits, affidavits)) {
      _sourceRevision++;
    }
    _activeCase = activeCase;
    _exhibits = List.unmodifiable(exhibits);
    _witnesses = List.unmodifiable(witnesses);
    _affidavits = List.unmodifiable(affidavits);
    _stipulations = List.unmodifiable(stipulations);
    _timingRules = List.unmodifiable(timingRules);
  }

  Future<void> loadBrief() async {
    final caseId = _activeCase?.id;
    final service = briefService;
    if (isDisposed || caseId == null || service == null) return;

    final generation = _loadGeneration;
    final request = ++_briefRequest;
    _cancelBrief();
    _isBriefLoading = true;
    _briefFailed = false;
    notifyListeners();

    bool isCurrent() =>
        !isDisposed &&
        generation == _loadGeneration &&
        request == _briefRequest;

    void apply(CaseBrief? value, {bool failed = false}) {
      if (!isCurrent()) return;
      _briefFailed = failed || (value != null && value.caseId != caseId);
      _brief = _briefFailed ? null : value;
      _isBriefLoading = false;
      final initial = _briefInitial;
      if (initial != null && !initial.isCompleted) initial.complete();
      notifyListeners();
    }

    if (service is LiveCaseBriefService) {
      final initial = _briefInitial = Completer<void>();
      _briefSubscription = service
          .watchBrief(caseId)
          .listen(
            apply,
            onError: (Object error, StackTrace stack) =>
                apply(null, failed: true),
            onDone: () {
              if (!initial.isCompleted) apply(null, failed: true);
            },
          );
      return initial.future;
    }

    try {
      apply(await service.fetchBrief(caseId));
    } catch (_) {
      apply(null, failed: true);
    }
  }

  void _cancelBrief() {
    unawaited(_briefSubscription?.cancel());
    _briefSubscription = null;
    final initial = _briefInitial;
    if (initial != null && !initial.isCompleted) initial.complete();
    _briefInitial = null;
  }

  @override
  void dispose() {
    _cancelBrief();
    super.dispose();
  }
}
