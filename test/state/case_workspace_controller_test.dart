import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/clock.dart';
import 'package:gavel/data/mock/mock_case_brief_service.dart';
import 'package:gavel/data/mock/mock_case_repository.dart';
import 'package:gavel/data/mock/seed_data.dart';
import 'package:gavel/data/models/case_brief.dart';
import 'package:gavel/data/services/case_brief_service.dart';
import 'package:gavel/state/case_controller.dart';

class _Service implements CaseBriefService {
  _Service(this.fetch);
  final Future<CaseBrief> Function(String) fetch;
  @override
  Future<CaseBrief> fetchBrief(String caseId) => fetch(caseId);
}

void main() {
  final seed = SeedData.harmon(today: DateTime(2026, 10, 17));
  MockCaseRepository repository() => MockCaseRepository(
    activeCase: seed.caseFile,
    exhibits: seed.exhibits,
    witnesses: seed.witnesses,
    affidavits: seed.affidavits,
    stipulations: seed.stipulations,
    timingRules: seed.timingRules,
  );

  test('loads workspace data and resolves typed source IDs', () async {
    final controller = CaseController(
      repository(),
      const Clock(),
      briefService: MockCaseBriefService(seed.caseBrief),
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.affidavits, seed.affidavits);
    expect(controller.stipulations, seed.stipulations);
    expect(controller.timingRules, seed.timingRules);
    expect(controller.brief, seed.caseBrief);
    expect(controller.exhibitById('ex_4'), seed.exhibits[3]);
    expect(controller.affidavitById('aff_okafor'), seed.affidavits[1]);
    expect(controller.witnessById('wit_okafor'), seed.witnesses[1]);
    expect(controller.exhibitById('missing'), isNull);
    expect(controller.affidavitById('missing'), isNull);
    expect(() => controller.affidavits.clear(), throwsUnsupportedError);
    expect(() => controller.timingRules.clear(), throwsUnsupportedError);
  });

  test('brief failure preserves records and can be retried', () async {
    var calls = 0;
    final controller = CaseController(
      repository(),
      const Clock(),
      briefService: _Service((_) async {
        if (++calls == 1) throw StateError('offline');
        return seed.caseBrief;
      }),
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.isLoaded, isTrue);
    expect(controller.exhibits, hasLength(14));
    expect(controller.briefFailed, isTrue);
    expect(controller.isBriefLoading, isFalse);
    await controller.loadBrief();
    expect(controller.brief, seed.caseBrief);
    expect(controller.briefFailed, isFalse);
  });

  test('rejects a brief that belongs to a different case', () async {
    final controller = CaseController(
      repository(),
      const Clock(),
      briefService: _Service(
        (_) async => seed.caseBrief.copyWith(caseId: 'wrong_case'),
      ),
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.brief, isNull);
    expect(controller.briefFailed, isTrue);
  });

  test('late service completion after disposal does not notify', () async {
    final pending = Completer<CaseBrief>();
    final started = Completer<void>();
    final controller = CaseController(
      repository(),
      const Clock(),
      briefService: _Service((_) {
        if (!started.isCompleted) started.complete();
        return pending.future;
      }),
    );
    final load = controller.load();
    await started.future;
    expect(controller.isLoaded, isTrue);
    expect(controller.isBriefLoading, isTrue);
    controller.dispose();
    pending.complete(seed.caseBrief);
    await load;
  });

  test(
    'a refreshed case cannot be overwritten by its older brief request',
    () async {
      final first = Completer<CaseBrief>();
      final started = Completer<void>();
      var calls = 0;
      final controller = CaseController(
        repository(),
        const Clock(),
        briefService: _Service((_) {
          if (++calls == 1) {
            started.complete();
            return first.future;
          }
          return Future.value(seed.caseBrief.copyWith(arguments: []));
        }),
      );
      addTearDown(controller.dispose);
      final initialLoad = controller.load();
      await started.future;
      await controller.load();
      expect(controller.brief!.arguments, isEmpty);
      first.complete(seed.caseBrief);
      await initialLoad;
      expect(controller.brief!.arguments, isEmpty);
      expect(controller.isBriefLoading, isFalse);
    },
  );
}
