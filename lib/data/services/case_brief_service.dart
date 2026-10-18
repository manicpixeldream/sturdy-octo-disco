import '../models/case_brief.dart';

abstract interface class CaseBriefService {
  Future<CaseBrief> fetchBrief(String caseId);
}
