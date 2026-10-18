import '../models/case_file.dart';
import '../models/exhibit.dart';
import '../models/witness.dart';

abstract interface class CaseRepository {
  Future<CaseFile> fetchActiveCase();

  Future<List<Exhibit>> fetchExhibits(String caseId);

  Future<List<Witness>> fetchWitnesses(String caseId);
}
