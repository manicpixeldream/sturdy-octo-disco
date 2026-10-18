import 'package:material_ui/material_ui.dart';

import '../theme/spacing.dart';

class LoadFailure extends StatelessWidget {
  const LoadFailure({super.key, required this.title, required this.onRetry});
  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Spacing.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_outlined, size: 28),
        const SizedBox(height: Spacing.lg),
        Text(
          title,
          key: const ValueKey('load_error'),
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.sm),
        const Text(
          'Your materials could not be loaded. Try again.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.lg),
        OutlinedButton(
          key: const ValueKey('load_retry'),
          onPressed: onRetry,
          child: const Text('Try again'),
        ),
      ],
    ),
  );
}
