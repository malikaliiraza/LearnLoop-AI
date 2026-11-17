/// App-wide constants for LearnLoop AI (v0.1.0 scaffold).
class AppConstants {
  AppConstants._();

  static const String appName = 'LearnLoop AI';

  /// Default number of questions per quiz.
  static const int defaultQuestionCount = 5;

  /// Minimum number of sentences a note needs before a quiz can be built.
  static const int minSentencesForQuiz = 4;

  /// Shortest length (in letters) for a word to count as a key term.
  static const int minKeyTermLength = 4;

  /// How many times a word must appear to count as a key term.
  static const int minKeyTermOccurrences = 2;

  static const String notesStorageKey = 'learnloop_notes_v1';
  static const String reviewCardsStorageKey = 'learnloop_review_cards_v1';
}
