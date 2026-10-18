import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/clock.dart';

class SessionController extends ChangeNotifier with WidgetsBindingObserver {
  SessionController({required this.currentTeammateId, required this.clock}) {
    _lastMinute = _minute(clock.now());
    WidgetsBinding.instance.addObserver(this);
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _startClock();
    }
  }

  final String currentTeammateId;
  final Clock clock;
  Timer? _timer;
  late DateTime _lastMinute;

  static DateTime _minute(DateTime time) =>
      DateTime(time.year, time.month, time.day, time.hour, time.minute);

  /// Also available to hosts/tests with a manually advanced clock.
  void refreshTime() {
    final minute = _minute(clock.now());
    if (minute == _lastMinute) return;
    _lastMinute = minute;
    notifyListeners();
  }

  void _startClock() {
    _timer?.cancel();
    refreshTime();
    if (!clock.isLive) return;
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => refreshTime());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startClock();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
