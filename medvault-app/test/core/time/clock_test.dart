import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/core/time/clock.dart';

void main() {
  test('system clock returns the current local date and time', () {
    const clock = SystemClock();

    final before = DateTime.now();
    final actual = clock.now();
    final after = DateTime.now();

    expect(actual.isAfter(before) || actual.isAtSameMomentAs(before), isTrue);
    expect(actual.isBefore(after) || actual.isAtSameMomentAs(after), isTrue);
    expect(actual.isUtc, isFalse);
  });
}
