import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gavel/core/theme/gavel_colors.dart';
import 'package:gavel/core/theme/gavel_theme.dart';
import 'package:gavel/core/theme/gavel_typography.dart';

void main() {
  final light = GavelTheme.light();
  final dark = GavelTheme.dark();
  final midnight = GavelTheme.midnight();
  final all = [light, dark, midnight];

  test('light theme uses maroon on cream with white cards', () {
    expect(light.brightness, Brightness.light);
    expect(light.colorScheme.primary, GavelColors.maroon);
    expect(light.colorScheme.secondary, GavelColors.gold);
    expect(light.scaffoldBackgroundColor, GavelColors.cream);
    expect(light.colorScheme.surface, GavelColors.white);
    expect(light.textTheme.bodyMedium!.color, GavelColors.ink);
  });

  test(
    'editorial palette uses the requested colors and readable text contrast',
    () {
      expect(GavelColors.cream, const Color(0xFFF8F6F1));
      expect(GavelColors.ink, const Color(0xFF292421));
      expect(GavelColors.maroon, const Color(0xFF641F32));
      double contrast(Color foreground, Color background) {
        final a = foreground.computeLuminance();
        final b = background.computeLuminance();
        return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
      }

      for (final color in [
        GavelColors.ink,
        GavelColors.inkMuted,
        GavelColors.maroon,
        GavelColors.ready,
        GavelColors.inProgress,
        GavelColors.flagged,
        GavelColors.info,
      ]) {
        expect(contrast(color, GavelColors.cream), greaterThanOrEqualTo(4.5));
      }
    },
  );

  test('dark theme uses deep plum with cream text', () {
    expect(dark.brightness, Brightness.dark);
    expect(dark.colorScheme.primary, GavelColors.maroon);
    expect(dark.scaffoldBackgroundColor, GavelColors.plum);
    expect(dark.textTheme.bodyMedium!.color, GavelColors.cream);
  });

  test('midnight theme uses rose and bright gold on navy', () {
    expect(midnight.brightness, Brightness.dark);
    expect(midnight.colorScheme.primary, GavelColors.rose);
    expect(midnight.colorScheme.secondary, GavelColors.brightGold);
    expect(midnight.scaffoldBackgroundColor, GavelColors.midnight);
    expect(midnight.textTheme.bodyMedium!.color, GavelColors.cream);
  });

  test('accent is primary in light and secondary in dark themes', () {
    expect(GavelTheme.accent(light), GavelColors.maroon);
    expect(GavelTheme.accent(dark), GavelColors.gold);
    expect(GavelTheme.accent(midnight), GavelColors.brightGold);
  });

  test('display text is Fraunces and body text is Inter in every theme', () {
    for (final theme in all) {
      final t = theme.textTheme;
      for (final style in [t.displayLarge, t.headlineMedium, t.titleLarge]) {
        expect(style!.fontFamily, GavelTypography.displayFamily);
      }
      for (final style in [t.titleMedium, t.bodyMedium, t.labelLarge]) {
        expect(style!.fontFamily, GavelTypography.bodyFamily);
      }
    }
  });

  test('every platform uses the same slide-in page transition', () {
    for (final theme in all) {
      for (final platform in TargetPlatform.values) {
        expect(
          theme.pageTransitionsTheme.builders[platform],
          isA<CupertinoPageTransitionsBuilder>(),
          reason: '$platform',
        );
      }
    }
  });
}
