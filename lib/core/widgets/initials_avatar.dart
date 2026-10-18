import 'package:material_ui/material_ui.dart';

import '../theme/gavel_colors.dart';
import '../theme/gavel_typography.dart';

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.color,
  });

  final String name;
  final double size;

  /// Overrides the color picked from [name].
  final Color? color;

  /// Plum is excluded so avatars stay visible on the dark plum pages.
  static const List<Color> palette = [
    GavelColors.maroon,
    GavelColors.inkMuted,
    Color(0xFF876D75),
    Color(0xFF6D716C),
  ];

  /// First letter of the first and last words, e.g. "Mara Okafor" -> "MO".
  static String initialsFor(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    final first = words.first[0];
    final last = words.length > 1 ? words.last[0] : '';
    return (first + last).toUpperCase();
  }

  /// Stable across runs and platforms (unlike [String.hashCode]).
  static Color colorFor(String name) {
    final sum = name.trim().toLowerCase().codeUnits.fold<int>(
      0,
      (a, b) => a + b,
    );
    return palette[sum % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? colorFor(name),
        shape: BoxShape.circle,
      ),
      child: Text(
        initialsFor(name),
        semanticsLabel: name,
        style: TextStyle(
          fontFamily: GavelTypography.bodyFamily,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: GavelColors.white,
        ),
      ),
    );
  }
}
