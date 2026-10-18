import '../models/case_file.dart';
import '../models/affidavit.dart';
import '../models/case_brief.dart';
import '../models/stipulation.dart';
import '../models/timing_rule.dart';
import '../models/exhibit.dart';
import '../models/task_item.dart';
import '../models/teammate.dart';
import '../models/trial_side.dart';
import '../models/witness.dart';
import 'harmon_packet.dart';

/// The State v. Harmon demo case. Dates are relative to [today] so the demo
/// never goes stale.
class SeedData {
  SeedData._({
    required this.caseFile,
    required this.exhibits,
    required this.witnesses,
    required this.teammates,
    required this.tasks,
    required this.currentTeammateId,
  });

  factory SeedData.harmon({required DateTime today}) {
    DateTime inDays(int days) =>
        DateTime(today.year, today.month, today.day + days);

    const caseId = 'case_harmon';

    final exhibits = [
      for (final (i, (title, description)) in const [
        ('Fire scene diagram', 'Layout of the print shop after the fire.'),
        ('Rear door photo', 'Pry marks on the rear service door.'),
        ('Gas can receipt', 'Hardware store receipt dated March 2.'),
        ('911 call transcript', 'Call from Mara Okafor at 11:42 p.m.'),
        ('Fire marshal report', 'Origin and cause findings.'),
        ('Security camera still', 'Figure near the alley at 11:31 p.m.'),
        ('Text messages', 'Messages between Harmon and Lindqvist.'),
        ('Insurance policy', 'Policy on the shop, renewed in January.'),
        ('Lease termination letter', 'Landlord notice dated February 10.'),
        ('Burn pattern photos', 'V-patterns on the east wall.'),
        ('Accelerant lab report', 'Debris samples from the stockroom.'),
        ('Timecard', "Lindqvist's timecard for March 3."),
        ('Weather report', 'Wind and temperature on March 3.'),
        ('Shop floor plan', 'Pre-fire floor plan from the city.'),
      ].indexed)
        Exhibit(
          id: 'ex_${i + 1}',
          caseId: caseId,
          number: i + 1,
          title: title,
          description: description,
        ),
    ];

    const witnesses = [
      Witness(
        id: 'wit_reyes',
        caseId: caseId,
        name: 'Officer Dana Reyes',
        side: TrialSide.prosecution,
        description: 'Responding officer.',
      ),
      Witness(
        id: 'wit_okafor',
        caseId: caseId,
        name: 'Mara Okafor',
        side: TrialSide.prosecution,
        description: 'Neighbor who called 911.',
      ),
      Witness(
        id: 'wit_ortiz',
        caseId: caseId,
        name: 'Dr. Lena Ortiz',
        side: TrialSide.prosecution,
        description: 'Fire investigator.',
      ),
      Witness(
        id: 'wit_harmon',
        caseId: caseId,
        name: 'Casey Harmon',
        side: TrialSide.defense,
        description: 'Defendant and shop owner.',
      ),
      Witness(
        id: 'wit_lindqvist',
        caseId: caseId,
        name: 'Theo Lindqvist',
        side: TrialSide.defense,
        description: 'Employee and alibi witness.',
      ),
      Witness(
        id: 'wit_menon',
        caseId: caseId,
        name: 'Dr. Ravi Menon',
        side: TrialSide.defense,
        description: 'Fire science expert.',
      ),
    ];

    const teammates = [
      Teammate(id: 'tm_sofia', name: 'Sofia Reyes'),
      Teammate(id: 'tm_marcus', name: 'Marcus Bell'),
      Teammate(id: 'tm_jordan', name: 'Jordan Ellis'),
      Teammate(id: 'tm_priya', name: 'Priya Shah'),
      Teammate(id: 'tm_leo', name: 'Leo Kim'),
      Teammate(id: 'tm_ava', name: 'Ava Thompson'),
    ];

    final tasks = [
      TaskItem(
        id: 'task_1',
        title: 'Draft direct exam of Officer Reyes',
        assigneeId: 'tm_sofia',
        dueDate: inDays(2),
      ),
      TaskItem(
        id: 'task_2',
        title: 'Review the fire marshal report (Ex. 5)',
        assigneeId: 'tm_sofia',
        dueDate: inDays(-1),
        isDone: true,
      ),
      TaskItem(
        id: 'task_3',
        title: 'Practice opening statement',
        assigneeId: 'tm_sofia',
        dueDate: inDays(5),
      ),
      TaskItem(
        id: 'task_4',
        title: 'Prepare objections list',
        assigneeId: 'tm_sofia',
        dueDate: inDays(9),
      ),
      TaskItem(
        id: 'task_5',
        title: 'Draft cross of Theo Lindqvist',
        assigneeId: 'tm_marcus',
        dueDate: inDays(4),
      ),
      TaskItem(
        id: 'task_6',
        title: 'Memorize Mara Okafor affidavit',
        assigneeId: 'tm_jordan',
        dueDate: inDays(-2),
        isDone: true,
      ),
      TaskItem(
        id: 'task_7',
        title: 'Rehearse Okafor direct with attorney',
        assigneeId: 'tm_jordan',
        dueDate: inDays(6),
      ),
      TaskItem(
        id: 'task_8',
        title: 'Outline closing argument',
        assigneeId: 'tm_priya',
        dueDate: inDays(12),
      ),
      TaskItem(
        id: 'task_9',
        title: 'Build exhibit foundation scripts',
        assigneeId: 'tm_priya',
        dueDate: inDays(-3),
        isDone: true,
      ),
      TaskItem(
        id: 'task_10',
        title: 'Learn Dr. Ortiz expert report',
        assigneeId: 'tm_leo',
        dueDate: inDays(3),
        isDone: true,
      ),
      TaskItem(
        id: 'task_11',
        title: 'Time the full direct line-up',
        assigneeId: 'tm_ava',
        dueDate: inDays(8),
      ),
      TaskItem(
        id: 'task_12',
        title: 'Research hearsay exceptions',
        assigneeId: 'tm_ava',
        dueDate: inDays(1),
        isDone: true,
      ),
    ];

    return SeedData._(
      caseFile: CaseFile(
        id: caseId,
        title: 'State v. Harmon',
        summary:
            'Casey Harmon is charged with second-degree arson after a fire '
            'destroyed the Riverside Print Shop on the night of March 3.',
        trialDate: inDays(23),
      ),
      exhibits: exhibits,
      witnesses: witnesses,
      teammates: teammates,
      tasks: tasks,
      currentTeammateId: 'tm_sofia',
    );
  }

  final CaseFile caseFile;
  final List<Exhibit> exhibits;
  final List<Witness> witnesses;
  final List<Teammate> teammates;
  final List<TaskItem> tasks;

  List<Affidavit> get affidavits => HarmonPacket.affidavits;
  List<Stipulation> get stipulations => HarmonPacket.stipulations;
  List<TimingRule> get timingRules => HarmonPacket.timingRules;
  CaseBrief get caseBrief => HarmonPacket.brief;

  /// The signed-in user's teammate id until real accounts arrive in v2.
  final String currentTeammateId;
}
