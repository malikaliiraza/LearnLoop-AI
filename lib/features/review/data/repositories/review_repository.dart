import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/app_constants.dart';
import '../../domain/spaced_repetition.dart';

/// Persists the SM-2 review schedule on the device (SharedPreferences,
/// offline-first).
///
/// v0.1.0 computed the next review date but never saved it — the schedule
/// was forgotten as soon as the quiz screen closed. v0.2.0 records every
/// answered topic: a right answer reschedules it further out, a wrong one
/// brings it back tomorrow, and the home screen shows what is due.
class ReviewRepository {
  ReviewRepository(this._prefs);

  final SharedPreferences _prefs;

  List<ReviewCard> loadCards() {
    final raw = _prefs.getString(AppConstants.reviewCardsStorageKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ReviewCard.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCards(List<ReviewCard> cards) async {
    final raw = jsonEncode(cards.map((c) => c.toJson()).toList());
    await _prefs.setString(AppConstants.reviewCardsStorageKey, raw);
  }

  /// Records one answer for [topic]: [quality] 0–5 (SM-2), 4–5 for a
  /// correct answer, 2 for a wrong one. Creates the card on first sight.
  Future<void> recordAnswer(
    String topic,
    int quality, {
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final cards = loadCards();
    final index = cards.indexWhere((c) => c.topic == topic);
    final scheduler = SpacedRepetition(now: current);
    final existing = index >= 0
        ? cards[index]
        : ReviewCard(topic: topic, dueDate: current);
    final updated = scheduler.scheduleNext(existing, quality);
    if (index >= 0) {
      cards[index] = updated;
    } else {
      cards.add(updated);
    }
    await saveCards(cards);
  }

  /// The cards that are due for review right now.
  List<ReviewCard> dueCards({DateTime? now}) {
    return SpacedRepetition(now: now).dueCards(loadCards());
  }
}
