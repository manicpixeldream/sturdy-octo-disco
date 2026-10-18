import '../models/case_file.dart';
import '../models/affidavit.dart';
import '../models/stipulation.dart';
import '../models/timing_rule.dart';
import '../models/exhibit.dart';
import '../models/witness.dart';

abstract interface class CaseRepository {
  Future<CaseFile> fetchActiveCase();

  Future<List<Exhibit>> fetchExhibits(String caseId);

  Future<List<Witness>> fetchWitnesses(String caseId);

  Future<List<Affidavit>> fetchAffidavits(String caseId);

  Future<List<Stipulation>> fetchStipulations(String caseId);

  Future<List<TimingRule>> fetchTimingRules(String caseId);
}
