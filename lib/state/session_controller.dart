import 'package:flutter/foundation.dart';

import '../core/clock.dart';

class SessionController extends ChangeNotifier {
  SessionController({required this.currentTeammateId, required this.clock});

  final String currentTeammateId;
  final Clock clock;
}
