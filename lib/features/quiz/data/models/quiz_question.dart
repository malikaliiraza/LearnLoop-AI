/// One multiple-choice question generated from a study note.
class QuizQuestion {
  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.topic,
  });

  /// The question text, e.g. "What does your note say about 'chlorophyll'?"
  final String question;

  /// Four answer options, shuffled. [correctIndex] points at the right one.
  final List<String> options;

  final int correctIndex;

  /// A one-line re-explanation shown after answering — the tutor's material.
  final String explanation;

  /// The key term this question is about; used for weak-topic analytics.
  final String topic;

  String get correctAnswer => options[correctIndex];

  bool isCorrect(int selectedIndex) => selectedIndex == correctIndex;
}
