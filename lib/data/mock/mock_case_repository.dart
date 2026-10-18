import '../models/case_file.dart';
import '../models/affidavit.dart';
import '../models/stipulation.dart';
import '../models/timing_rule.dart';
import '../models/exhibit.dart';
import '../models/witness.dart';
import '../repositories/case_repository.dart';

class MockCaseRepository implements CaseRepository {
  MockCaseRepository({
    required this.activeCase,
    required List<Exhibit> exhibits,
    required List<Witness> witnesses,
    List<Affidavit> affidavits = const [],
    List<Stipulation> stipulations = const [],
    List<TimingRule> timingRules = const [],
  }) : _exhibits = List.unmodifiable(exhibits),
       _witnesses = List.unmodifiable(witnesses),
       _affidavits = List.unmodifiable(affidavits),
       _stipulations = List.unmodifiable(stipulations),
       _timingRules = List.unmodifiable(timingRules);

  final CaseFile activeCase;
  final List<Exhibit> _exhibits;
  final List<Witness> _witnesses;
  final List<Affidavit> _affidavits;
  final List<Stipulation> _stipulations;
  final List<TimingRule> _timingRules;

  @override
  Future<CaseFile> fetchActiveCase() async => activeCase;

  @override
  Future<List<Exhibit>> fetchExhibits(String caseId) async =>
      _exhibits.where((e) => e.caseId == caseId).toList(growable: false);

  @override
  Future<List<Witness>> fetchWitnesses(String caseId) async =>
      _witnesses.where((w) => w.caseId == caseId).toList(growable: false);

  @override
  Future<List<Affidavit>> fetchAffidavits(String caseId) async =>
      _affidavits.where((a) => a.caseId == caseId).toList(growable: false);

  @override
  Future<List<Stipulation>> fetchStipulations(String caseId) async =>
      _stipulations.where((s) => s.caseId == caseId).toList(growable: false);

  @override
  Future<List<TimingRule>> fetchTimingRules(String caseId) async =>
      _timingRules.where((r) => r.caseId == caseId).toList(growable: false);
}
