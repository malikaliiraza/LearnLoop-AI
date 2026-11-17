import 'package:flutter_test/flutter_test.dart';
import 'package:learnloop_ai/features/review/domain/spaced_repetition.dart';

void main() {
  group('SpacedRepetition (SM-2)', () {
    final now = DateTime(2026, 11, 17, 10, 0);
    final scheduler = SpacedRepetition(now: now);

    test('first good recall schedules 1 day ahead', () {
      final next = scheduler.scheduleNext(ReviewCard(topic: 'x'), 5);
      expect(next.repetitions, 1);
      expect(next.intervalDays, 1);
      expect(next.dueDate, now.add(const Duration(days: 1)));
    });

    test('second good recall schedules 6 days ahead', () {
      final afterFirst = scheduler.scheduleNext(ReviewCard(topic: 'x'), 5);
      final afterSecond = scheduler.scheduleNext(afterFirst, 5);
      expect(afterSecond.repetitions, 2);
      expect(afterSecond.intervalDays, 6);
    });

    test('third good recall multiplies the interval by the ease factor', () {
      var card = ReviewCard(topic: 'x');
      card = scheduler.scheduleNext(card, 5); // interval 1
      card = scheduler.scheduleNext(card, 5); // interval 6, ease 2.7
      card = scheduler.scheduleNext(card, 5); // interval round(6 * 2.7) = 16
      expect(card.repetitions, 3);
      expect(card.intervalDays, 16);
    });

    test('a poor recall resets the card to review tomorrow', () {
      var card = ReviewCard(topic: 'x');
      card = scheduler.scheduleNext(card, 5);
      card = scheduler.scheduleNext(card, 5);
      final reset = scheduler.scheduleNext(card, 2);
      expect(reset.repetitions, 0);
      expect(reset.intervalDays, 1);
    });

    test('ease factor never drops below 1.3', () {
      var card = ReviewCard(topic: 'x');
      for (var i = 0; i < 6; i++) {
        card = scheduler.scheduleNext(card, 0);
      }
      expect(card.easeFactor, greaterThanOrEqualTo(1.3));
    });

    test('dueCards returns only cards whose due date has passed', () {
      final due = ReviewCard(
        topic: 'due',
        dueDate: now.subtract(const Duration(days: 1)),
      );
      final future = ReviewCard(
        topic: 'future',
        dueDate: now.add(const Duration(days: 3)),
      );
      final result = scheduler.dueCards([due, future]);
      expect(result.map((c) => c.topic).toList(), ['due']);
    });
  });
}
