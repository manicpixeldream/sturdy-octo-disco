import 'package:material_ui/material_ui.dart';

abstract final class GavelTypography {
  static const String displayFamily = 'Fraunces';
  static const String bodyFamily = 'Inter';

  static TextTheme textTheme({required Color color, required Color muted}) {
    TextStyle display(double size, FontWeight weight, {double height = 1.15}) =>
        TextStyle(
          fontFamily: displayFamily,
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: color,
        );

    TextStyle body(
      double size,
      FontWeight weight, {
      Color? tint,
      double height = 1.4,
      double letterSpacing = 0,
    }) => TextStyle(
      fontFamily: bodyFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: tint ?? color,
    );

    return TextTheme(
      displayLarge: display(40, FontWeight.w700),
      displayMedium: display(34, FontWeight.w700),
      displaySmall: display(28, FontWeight.w600),
      headlineLarge: display(26, FontWeight.w600),
      headlineMedium: display(22, FontWeight.w600),
      headlineSmall: display(20, FontWeight.w600),
      titleLarge: display(18, FontWeight.w600, height: 1.25),
      titleMedium: body(16, FontWeight.w600),
      titleSmall: body(14, FontWeight.w600),
      bodyLarge: body(16, FontWeight.w400),
      bodyMedium: body(14, FontWeight.w400),
      bodySmall: body(12, FontWeight.w400, tint: muted),
      labelLarge: body(14, FontWeight.w600),
      labelMedium: body(12, FontWeight.w600),
      labelSmall: body(11, FontWeight.w600, tint: muted, letterSpacing: 0.8),
    );
  }
}
