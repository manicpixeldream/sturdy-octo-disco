import '../data/models/teammate.dart';
import '../data/models/task_item.dart';

/// Transparent demo ranking: fewest unfinished tasks, then name, then ID.
abstract final class TeammateMatcher {
  static List<Teammate> rank(List<Teammate> members, List<TaskItem> tasks) {
    int open(String id) =>
        tasks.where((t) => t.assigneeId == id && !t.isDone).length;
    return [...members]..sort((a, b) {
      final workload = open(a.id).compareTo(open(b.id));
      if (workload != 0) return workload;
      final name = a.name.compareTo(b.name);
      return name != 0 ? name : a.id.compareTo(b.id);
    });
  }
}
