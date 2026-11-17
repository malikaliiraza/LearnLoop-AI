/// One topic scheduled for spaced repetition.
class ReviewCard {
  ReviewCard({
    required this.topic,
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    this.repetitions = 0,
    DateTime? dueDate,
  }) : dueDate = dueDate ?? DateTime.now();

  factory ReviewCard.fromJson(Map<String, dynamic> json) {
    return ReviewCard(
      topic: json['topic'] as String,
      easeFactor: (json['easeFactor'] as num).toDouble(),
      intervalDays: json['intervalDays'] as int,
      repetitions: json['repetitions'] as int,
      dueDate: DateTime.parse(json['dueDate'] as String),
    );
  }

  final String topic;

  /// SM-2 ease factor; starts at 2.5, never drops below 1.3.
  final double easeFactor;

  /// Days until the next review.
  final int intervalDays;

  /// Consecutive successful reviews.
  final int repetitions;

  final DateTime dueDate;

  bool get isDue => !DateTime.now().isBefore(dueDate);

  Map<String, dynamic> toJson() {
    return {
      'topic': topic,
      'easeFactor': easeFactor,
      'intervalDays': intervalDays,
      'repetitions': repetitions,
      'dueDate': dueDate.toIso8601String(),
    };
  }
}

/// Spaced-repetition scheduler (SM-2, the algorithm behind SuperMemo).
///
/// After each quiz answer, the topic is rescheduled: a good recall pushes
/// the next review further away (1 day, then 6, then interval × ease),
/// a poor recall resets the topic to "review tomorrow". Topics the student
/// keeps missing come back often; topics they know stay out of the way.
class SpacedRepetition {
  SpacedRepetition({DateTime? now}) : _now = now ?? DateTime.now();

  final DateTime _now;

  /// Reschedules [card] after a review scored [quality] from 0 (forgot
  /// completely) to 5 (recalled instantly).
  ReviewCard scheduleNext(ReviewCard card, int quality) {
    assert(quality >= 0 && quality <= 5, 'quality must be 0-5');

    var ease = card.easeFactor;
    var interval = card.intervalDays;
    var repetitions = card.repetitions;

    if (quality < 3) {
      repetitions = 0;
      interval = 1;
    } else {
      repetitions += 1;
      if (repetitions == 1) {
        interval = 1;
      } else if (repetitions == 2) {
        interval = 6;
      } else {
        interval = (interval * ease).round();
      }
    }

    ease = ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (ease < 1.3) ease = 1.3;

    return ReviewCard(
      topic: card.topic,
      easeFactor: ease,
      intervalDays: interval,
      repetitions: repetitions,
      dueDate: _now.add(Duration(days: interval)),
    );
  }

  /// The cards that are due for review right now.
  List<ReviewCard> dueCards(List<ReviewCard> cards) {
    return cards.where((c) => !c.dueDate.isAfter(_now)).toList();
  }
}
