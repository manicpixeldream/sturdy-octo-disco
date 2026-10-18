/// Source of "now". Inject a fixed clock in tests so dates are deterministic.
class Clock {
  const Clock([this._now = DateTime.now]);

  Clock.fixed(DateTime time) : _now = (() => time);

  final DateTime Function() _now;

  DateTime now() => _now();
}
