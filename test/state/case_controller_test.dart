import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/clock.dart';
import 'package:gavel/data/mock/mock_case_repository.dart';
import 'package:gavel/data/models/case_file.dart';
import 'package:gavel/state/case_controller.dart';

void main() {
  test('daysUntilTrial uses the injected clock, not the wall clock', () async {
    final clock = Clock.fixed(DateTime(2026, 10, 10, 15));
    final controller = CaseController(
      MockCaseRepository(
        activeCase: CaseFile(
          id: 'case_harmon',
          title: 'State v. Harmon',
          summary: 'Arson.',
          trialDate: DateTime(2026, 11, 2),
        ),
        exhibits: const [],
        witnesses: const [],
      ),
      clock,
    );

    await controller.load();
    expect(controller.daysUntilTrial, 23);
  });
}
