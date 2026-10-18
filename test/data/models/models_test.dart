import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/models/case_file.dart';
import 'package:gavel/data/models/exhibit.dart';
import 'package:gavel/data/models/task_item.dart';
import 'package:gavel/data/models/teammate.dart';
import 'package:gavel/data/models/trial_side.dart';
import 'package:gavel/data/models/witness.dart';

void main() {
  final trial = DateTime.utc(2026, 11, 2);
  final due = DateTime.utc(2026, 10, 12);

  final caseFile = CaseFile(
    id: 'case_harmon',
    title: 'State v. Harmon',
    summary: 'Arson at the print shop.',
    trialDate: trial,
  );
  final exhibit = Exhibit(
    id: 'ex_1',
    caseId: 'case_harmon',
    number: 1,
    title: 'Fire scene diagram',
    description: 'Layout after the fire.',
  );
  final witness = Witness(
    id: 'wit_reyes',
    caseId: 'case_harmon',
    name: 'Officer Dana Reyes',
    side: TrialSide.prosecution,
    description: 'Responding officer.',
  );
  const teammate = Teammate(id: 'tm_sofia', name: 'Sofia Reyes');
  final task = TaskItem(
    id: 'task_1',
    title: 'Draft direct exam',
    assigneeId: 'tm_sofia',
    dueDate: due,
  );

  test('each model survives a toMap / fromMap round-trip', () {
    expect(CaseFile.fromMap(caseFile.toMap()), caseFile);
    expect(Exhibit.fromMap(exhibit.toMap()), exhibit);
    expect(Witness.fromMap(witness.toMap()), witness);
    expect(Teammate.fromMap(teammate.toMap()), teammate);
    expect(TaskItem.fromMap(task.toMap()), task);
  });

  test('copyWith replaces only the fields that are passed', () {
    expect(caseFile.copyWith(title: 'State v. Lee').title, 'State v. Lee');
    expect(caseFile.copyWith(title: 'State v. Lee').id, caseFile.id);
    expect(exhibit.copyWith(number: 4).label, 'Ex. 4');
    expect(witness.copyWith(side: TrialSide.defense).side, TrialSide.defense);
    expect(teammate.copyWith(name: 'Sofia Bell').firstName, 'Sofia');
    expect(task.copyWith(isDone: true).isDone, isTrue);
    expect(task.copyWith(isDone: true).title, task.title);
  });
}
