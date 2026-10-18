abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double hero = 64;
}

abstract final class Radii {
  static const double card = 10;
  static const double sheet = 16;
  static const double pill = 999;
}

/// Shared layout boundaries keep prose readable and workspace columns useful.
abstract final class LayoutTokens {
  static const double tablet = 760;
  static const double desktop = 1100;
  static const double content = 1120;
  static const double reading = 680;
  static const double columns = 880;

  static double gutter(double width) => width < 600 ? 24 : 40;
}
