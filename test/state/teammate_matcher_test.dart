import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/data/models/teammate.dart';
import 'package:gavel/data/models/task_item.dart';
import 'package:gavel/state/teammate_matcher.dart';

void main() {
  test(
    'ranks unfinished workload then name and ID without mutating inputs',
    () {
      const members = [
        Teammate(id: 'b', name: 'Bea'),
        Teammate(id: 'a', name: 'Amy'),
        Teammate(id: 'c', name: 'Amy'),
      ];
      final tasks = [
        TaskItem(
          id: '1',
          title: 'Pending',
          assigneeId: 'a',
          dueDate: DateTime(2026),
        ),
        TaskItem(
          id: '2',
          title: 'Done',
          assigneeId: 'b',
          dueDate: DateTime(2026),
          isDone: true,
        ),
      ];
      expect(TeammateMatcher.rank(members, tasks).map((m) => m.id), [
        'c',
        'b',
        'a',
      ]);
      expect(members.first.id, 'b');
    },
  );
}
