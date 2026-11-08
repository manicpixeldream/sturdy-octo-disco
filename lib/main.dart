import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app.dart';
import 'features/onboarding/onboarding.dart';

void main() {
  // The work screens pushed onto the shell also have standalone routes.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  runApp(GavelApp(onboarding: Onboarding()));
}
