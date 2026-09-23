import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/features/counter/views/counter_timer.dart';

void main() {
  test('formats timer at minute and hour boundaries', () {
    expect(formatSessionDuration(Duration.zero), '00:00');
    expect(formatSessionDuration(const Duration(seconds: 5)), '00:05');
    expect(formatSessionDuration(const Duration(minutes: 1)), '01:00');
    expect(formatSessionDuration(const Duration(minutes: 59, seconds: 59)), '59:59');
    expect(formatSessionDuration(const Duration(hours: 1)), '1:00:00');
  });

  test('elapsed time can be calculated deterministically and clamps future starts', () {
    final now = DateTime(2026, 9, 23, 12);
    expect(
      elapsedSince(now.subtract(const Duration(seconds: 5)), now: now),
      const Duration(seconds: 5),
    );
    expect(elapsedSince(now.add(const Duration(seconds: 5)), now: now), Duration.zero);
  });
}
