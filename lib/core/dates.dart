/// Whole calendar days from [from] to [to], ignoring time of day.
///
/// Uses UTC so a daylight-saving shift between the dates can't drop a day.
int daysBetween(DateTime from, DateTime to) {
  final start = DateTime.utc(from.year, from.month, from.day);
  final end = DateTime.utc(to.year, to.month, to.day);
  return end.difference(start).inDays;
}

String greetingFor(DateTime now) {
  final hour = now.hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String dueLabel(DateTime due, DateTime today) {
  final days = daysBetween(today, due);
  if (days == 0) return 'Due today';
  if (days == 1) return 'Due tomorrow';
  if (days > 1) return 'Due in $days days';
  if (days == -1) return '1 day overdue';
  return '${-days} days overdue';
}

String trialCountdownLabel(int days) {
  if (days > 1) return 'Trial in $days days';
  if (days == 1) return 'Trial tomorrow';
  if (days == 0) return 'Trial today';
  if (days == -1) return 'Trial was yesterday';
  return 'Trial was ${-days} days ago';
}
