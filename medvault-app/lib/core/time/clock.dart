/// Provides the current local date and time.
abstract interface class Clock {
  DateTime now();
}

/// Production clock backed by the system clock.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
