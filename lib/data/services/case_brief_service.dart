import '../models/case_brief.dart';

abstract interface class CaseBriefService {
  Future<CaseBrief> fetchBrief(String caseId);
}

abstract interface class LiveCaseBriefService implements CaseBriefService {
  Stream<CaseBrief?> watchBrief(String caseId);
}
