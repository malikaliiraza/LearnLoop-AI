import 'package:flutter_test/flutter_test.dart';
import 'package:learnloop_ai/features/review/data/repositories/review_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ReviewRepository', () {
    test('records an answer and persists the card', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = ReviewRepository(prefs);
      final now = DateTime(2026, 11, 19);

      await repository.recordAnswer('chlorophyll', 2, now: now);

      final cards = repository.loadCards();
      expect(cards.length, 1);
      expect(cards.first.topic, 'chlorophyll');
      expect(cards.first.repetitions, 0);
      expect(cards.first.intervalDays, 1);
      expect(cards.first.dueDate, now.add(const Duration(days: 1)));

      // A fresh repository over the same prefs sees the saved card.
      final reloaded = ReviewRepository(prefs).loadCards();
      expect(reloaded.length, 1);
      expect(reloaded.first.topic, 'chlorophyll');
    });

    test('a correct answer pushes the next review further out', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = ReviewRepository(prefs);
      final now = DateTime(2026, 11, 19);

      await repository.recordAnswer('chlorophyll', 4, now: now);
      await repository.recordAnswer('chlorophyll', 4,
          now: now.add(const Duration(days: 1)));

      final card = repository.loadCards().single;
      expect(card.repetitions, 2);
      expect(card.intervalDays, 6);
    });

    test('dueCards returns only cards whose date has arrived', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = ReviewRepository(prefs);
      final now = DateTime(2026, 11, 19);

      await repository.recordAnswer('due-topic', 2, now: now);
      // Two good recalls in a row push this one a week out.
      await repository.recordAnswer('later-topic', 4, now: now);
      await repository.recordAnswer('later-topic', 4,
          now: now.add(const Duration(days: 1)));

      final due = repository.dueCards(now: now.add(const Duration(days: 1)));
      expect(due.map((c) => c.topic), contains('due-topic'));
      expect(due.map((c) => c.topic), isNot(contains('later-topic')));
      expect(repository.dueCards(now: now), isEmpty);
    });
  });
}
