import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/dates.dart';

class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.weekStart,
    required this.selectedDay,
    required this.onSelected,
  });
  final DateTime weekStart;
  final DateTime? selectedDay;
  final ValueChanged<DateTime?> onSelected;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          key: const ValueKey('schedule_all_week'),
          onPressed: () => onSelected(null),
          child: Text(
            selectedDay == null ? 'All week · selected' : 'Show all week',
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Builder(
                  builder: (context) {
                    final date = DateTime(
                      weekStart.year,
                      weekStart.month,
                      weekStart.day + i,
                    );
                    final active =
                        selectedDay != null &&
                        daysBetween(selectedDay!, date) == 0;
                    return Padding(
                      padding: const EdgeInsets.only(right: Spacing.sm),
                      child: Semantics(
                        selected: active,
                        child: OutlinedButton(
                          key: ValueKey('schedule_day_$i'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: active
                                ? scheme.primary
                                : scheme.surface,
                            foregroundColor: active
                                ? scheme.onPrimary
                                : scheme.onSurface,
                          ),
                          onPressed: () => onSelected(date),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: Spacing.md,
                            ),
                            child: Column(
                              children: [
                                Text(DateFormat.E().format(date)),
                                Text(DateFormat.MMMd().format(date)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
