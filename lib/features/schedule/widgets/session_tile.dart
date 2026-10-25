import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/widgets/gavel_card.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/models/practice_session.dart';

class SessionTile extends StatelessWidget {
  const SessionTile({super.key, required this.session, required this.now});
  final PracticeSession session;
  final DateTime now;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Spacing.md),
    child: GavelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(session.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.sm),
          Text(
            '${DateFormat.MMMEd().format(session.startsAt.toLocal())} · ${DateFormat.jm().format(session.startsAt.toLocal())} – ${DateFormat.jm().format(session.endsAt.toLocal())}',
          ),
          Text('${session.durationMinutes} minutes · ${session.location}'),
          if (!session.startsAt.isAfter(now))
            const StatusPill(
              status: GavelStatus.inProgress,
              label: 'In progress',
            ),
        ],
      ),
    ),
  );
}
