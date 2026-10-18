import '../models/case_file.dart';
import '../models/exhibit.dart';
import '../models/witness.dart';
import '../repositories/case_repository.dart';

class MockCaseRepository implements CaseRepository {
  MockCaseRepository({
    required this.activeCase,
    required List<Exhibit> exhibits,
    required List<Witness> witnesses,
  }) : _exhibits = List.unmodifiable(exhibits),
       _witnesses = List.unmodifiable(witnesses);

  final CaseFile activeCase;
  final List<Exhibit> _exhibits;
  final List<Witness> _witnesses;

  @override
  Future<CaseFile> fetchActiveCase() async => activeCase;

  @override
  Future<List<Exhibit>> fetchExhibits(String caseId) async =>
      _exhibits.where((e) => e.caseId == caseId).toList(growable: false);

  @override
  Future<List<Witness>> fetchWitnesses(String caseId) async =>
      _witnesses.where((w) => w.caseId == caseId).toList(growable: false);
}
