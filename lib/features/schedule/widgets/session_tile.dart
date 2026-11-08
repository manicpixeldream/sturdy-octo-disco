import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/widgets/gavel_card.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/models/practice_session.dart';

class SessionTile extends StatelessWidget {
  const SessionTile({
    super.key,
    required this.session,
    required this.now,
    required this.onOpen,
  });
  final VoidCallback onOpen;
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
          TextButton(
            key: ValueKey('practice_agenda_${session.id}'),
            onPressed: onOpen,
            child: const Text('Open agenda'),
          ),
          if (!session.endsAt.isAfter(now))
            const StatusPill(status: GavelStatus.ready, label: 'Ended')
          else if (!session.startsAt.isAfter(now))
            const StatusPill(
              status: GavelStatus.inProgress,
              label: 'In progress',
            ),
        ],
      ),
    ),
  );
}
