/// Source of "now". Inject a fixed clock in tests so dates are deterministic.
class Clock {
  const Clock([this._now = DateTime.now, this.isLive = true]);

  Clock.fixed(DateTime time) : _now = (() => time), isLive = false;

  final DateTime Function() _now;
  final bool isLive;

  DateTime now() => _now();
}
