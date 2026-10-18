import 'package:flutter/foundation.dart';

import '../core/theme/gavel_theme.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({GavelThemeVariant initial = GavelThemeVariant.light})
    : _variant = initial;

  GavelThemeVariant _variant;

  GavelThemeVariant get variant => _variant;

  void select(GavelThemeVariant variant) {
    if (variant == _variant) return;
    _variant = variant;
    notifyListeners();
  }
}
