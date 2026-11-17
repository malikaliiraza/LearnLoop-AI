import 'dart:math';

import '../../notes/data/models/study_note.dart';
import '../data/models/quiz_question.dart';
import '../../../core/app_constants.dart';

/// Builds a multiple-choice quiz from the student's own note.
///
/// v0.1.0 is a transparent local heuristic, not an AI model: it finds the
/// note's key terms (words that repeat), then asks what the note says about
/// each term, using the note's own sentences as the correct answer and as
/// distractors. A real AI question generator (from a PDF or pasted notes via
/// an LLM) is on the roadmap — the quiz format it produces is the same, so
/// the screens and the tutor do not change when it arrives.
class QuizGenerator {
  QuizGenerator({this.randomSeed});

  /// Fixed seed makes a quiz reproducible (used by tests). When null, the
  /// seed comes from the note id, so the same note always builds the same
  /// quiz on a device, but different notes differ.
  final int? randomSeed;

  static const Set<String> _stopwords = {
    'that', 'this', 'with', 'from', 'have', 'been', 'were', 'when', 'which',
    'their', 'there', 'they', 'them', 'then', 'than', 'also', 'into', 'about',
    'after', 'before', 'because', 'through', 'during', 'under', 'over',
    'between', 'while', 'where', 'would', 'could', 'should', 'these',
    'those', 'such', 'more', 'most', 'other', 'some', 'many', 'much', 'very',
    'just', 'only', 'even', 'each', 'both', 'using', 'called',
    'first', 'second', 'makes', 'make', 'made', 'take', 'takes', 'part',
    'used', 'uses', 'like', 'well', 'note', 'notes',
  };

  /// The note's key terms: words (4+ letters) that appear at least twice,
  /// most frequent first, ties broken alphabetically so results are stable.
  List<String> extractKeyTerms(String content) {
    final counts = <String, int>{};
    final wordPattern = RegExp(r"[a-zA-Z][a-zA-Z\-']+");
    for (final match in wordPattern.allMatches(content.toLowerCase())) {
      final word = match.group(0)!;
      if (word.length < AppConstants.minKeyTermLength) continue;
      if (_stopwords.contains(word)) continue;
      counts[word] = (counts[word] ?? 0) + 1;
    }
    final terms = counts.entries
        .where((e) => e.value >= AppConstants.minKeyTermOccurrences)
        .toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return terms.map((e) => e.key).toList();
  }

  /// Builds up to [questionCount] questions from [note].
  ///
  /// Returns an empty list when the note is too short to quiz on
  /// (fewer than 4 sentences, or no repeated key term).
  List<QuizQuestion> generateQuiz(
    StudyNote note, {
    int questionCount = AppConstants.defaultQuestionCount,
  }) {
    final sentences = note.sentences;
    if (sentences.length < AppConstants.minSentencesForQuiz) return [];

    final terms = extractKeyTerms(note.content);
    if (terms.isEmpty) return [];

    final random = Random(randomSeed ?? note.id.hashCode);
    final questions = <QuizQuestion>[];

    for (var i = 0; i < terms.length && questions.length < questionCount; i++) {
      final term = terms[i];
      final termSentences =
          sentences.where((s) => s.toLowerCase().contains(term)).toList();
      if (termSentences.isEmpty) continue;

      final correct = termSentences.first;
      final distractors = sentences
          .where((s) => s != correct && !s.toLowerCase().contains(term))
          .toList()
        ..shuffle(random);

      final options = <String>[correct];
      for (final d in distractors) {
        if (options.length >= 4) break;
        if (!options.contains(d)) options.add(d);
      }
      const fallbacks = [
        'It is not mentioned in your note.',
        'Your note says the opposite.',
        'None of the above.',
      ];
      for (final fallback in fallbacks) {
        if (options.length >= 4) break;
        if (!options.contains(fallback)) options.add(fallback);
      }
      if (options.length < 4) continue;

      options.shuffle(random);
      questions.add(
        QuizQuestion(
          question: "What does your note say about '$term'?",
          options: options,
          correctIndex: options.indexOf(correct),
          explanation: 'Your note says: $correct',
          topic: term,
        ),
      );
    }
    return questions;
  }
}
