import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'gavel_colors.dart';
import 'gavel_typography.dart';
import 'spacing.dart';

abstract final class GavelTheme {
  /// The same slide-in transition (with iOS swipe-back) on every platform.
  static final PageTransitionsTheme pageTransitions = PageTransitionsTheme(
    builders: {
      for (final platform in TargetPlatform.values)
        platform: const CupertinoPageTransitionsBuilder(),
    },
  );

  static ThemeData light() => _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: GavelColors.maroon,
      onPrimary: GavelColors.white,
      secondary: GavelColors.gold,
      onSecondary: GavelColors.plum,
      tertiary: GavelColors.info,
      onTertiary: GavelColors.white,
      error: GavelColors.flagged,
      onError: GavelColors.white,
      surface: GavelColors.white,
      onSurface: GavelColors.ink,
      onSurfaceVariant: GavelColors.inkMuted,
      outline: GavelColors.inkMuted,
      outlineVariant: GavelColors.border,
    ),
    background: GavelColors.cream,
  );

  static ThemeData dark() => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: GavelColors.maroon,
      onPrimary: GavelColors.white,
      secondary: GavelColors.gold,
      onSecondary: GavelColors.plum,
      tertiary: GavelColors.info,
      onTertiary: GavelColors.white,
      error: GavelColors.flagged,
      onError: GavelColors.white,
      surface: GavelColors.plumSurface,
      onSurface: GavelColors.cream,
      onSurfaceVariant: GavelColors.onDarkMuted,
      outline: GavelColors.onDarkMuted,
      outlineVariant: GavelColors.plumBorder,
    ),
    background: GavelColors.plum,
  );

  static ThemeData midnight() => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: GavelColors.rose,
      onPrimary: GavelColors.white,
      secondary: GavelColors.brightGold,
      onSecondary: GavelColors.midnight,
      tertiary: GavelColors.info,
      onTertiary: GavelColors.white,
      error: GavelColors.flagged,
      onError: GavelColors.white,
      surface: GavelColors.midnightSurface,
      onSurface: GavelColors.cream,
      onSurfaceVariant: GavelColors.onMidnightMuted,
      outline: GavelColors.onMidnightMuted,
      outlineVariant: GavelColors.midnightBorder,
    ),
    background: GavelColors.midnight,
  );

  /// Color for small icons and selected states. Primary is too dim for these
  /// on dark backgrounds, so dark themes use secondary.
  static Color accent(ThemeData theme) => theme.brightness == Brightness.dark
      ? theme.colorScheme.secondary
      : theme.colorScheme.primary;

  static ThemeData _build(ColorScheme scheme, {required Color background}) {
    final textTheme = GavelTypography.textTheme(
      color: scheme.onSurface,
      muted: scheme.onSurfaceVariant,
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.card),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      fontFamily: GavelTypography.bodyFamily,
      textTheme: textTheme,
      pageTransitionsTheme: pageTransitions,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          borderSide: BorderSide(
            color: scheme.brightness == Brightness.dark
                ? scheme.secondary
                : scheme.primary,
            width: 2,
          ),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.brightness == Brightness.dark
            ? scheme.secondary
            : scheme.primary,
        selectionColor:
            (scheme.brightness == Brightness.dark
                    ? scheme.secondary
                    : scheme.primary)
                .withValues(alpha: 0.16),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.labelLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: cardShape,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.card),
          ),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.card),
          ),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.brightness == Brightness.dark
              ? scheme.secondary
              : scheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
    );
  }
}

enum GavelThemeVariant {
  light('Light'),
  dark('Dark'),
  midnight('Midnight');

  const GavelThemeVariant(this.label);

  final String label;

  ThemeData get data => switch (this) {
    GavelThemeVariant.light => GavelTheme.light(),
    GavelThemeVariant.dark => GavelTheme.dark(),
    GavelThemeVariant.midnight => GavelTheme.midnight(),
  };
}
