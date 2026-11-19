import 'dart:math';

import '../../notes/data/models/study_note.dart';
import '../data/models/quiz_question.dart';
import '../../../core/app_constants.dart';

/// Builds a multiple-choice quiz from the student's own note.
///
/// v0.2.0 asks two kinds of question: "what does your note say about
/// this term?" (pick the sentence) and fill-in-the-blank (pick the missing
/// term). Both come from the note's own sentences, so a quiz built from an
/// imported PDF or text file works exactly like one built from a typed
/// note. The generator is still a transparent local heuristic, not an AI
/// model: it finds the note's key terms (words that repeat), then asks
/// about each term. A real AI question generator (from a PDF or pasted
/// notes via an LLM) is on the roadmap — the quiz format it produces is
/// the same, so the screens and the tutor do not change when it arrives.
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

  /// Builds up to [questionCount] questions from [note], mixing
  /// "what does the note say" and fill-in-the-blank questions.
  ///
  /// Returns an empty list when the note is too short to quiz on
  /// (fewer than 4 sentences, or no repeated key term).
  List<QuizQuestion> generateQuiz(
    StudyNote note, {
    int questionCount = AppConstants.defaultQuestionCount,
  }) {
    final terms = extractKeyTerms(note.content);
    return _buildQuestions(note, terms, questionCount);
  }

  /// Builds up to 3 questions about one [topic] only — used by the review
  /// screen so a due topic can be practised on its own. Returns an empty
  /// list when the note has no quiz-worthy sentence about the topic.
  List<QuizQuestion> generateQuizForTopic(StudyNote note, String topic) {
    final terms = extractKeyTerms(note.content);
    if (!terms.contains(topic)) return [];
    return _buildQuestions(note, [topic], 3);
  }

  List<QuizQuestion> _buildQuestions(
    StudyNote note,
    List<String> terms,
    int questionCount,
  ) {
    final sentences = note.sentences;
    if (sentences.length < AppConstants.minSentencesForQuiz) return [];
    if (terms.isEmpty) return [];

    final random = Random(randomSeed ?? note.id.hashCode);
    final questions = <QuizQuestion>[];

    for (var i = 0; i < terms.length && questions.length < questionCount; i++) {
      final term = terms[i];
      // Alternate the two question kinds so a quiz feels varied.
      final fillBlank = i.isOdd;
      final question = fillBlank
          ? _fillInBlankQuestion(note, term, terms, random)
          : _aboutTermQuestion(note, term, random);
      if (question != null) questions.add(question);
    }
    return questions;
  }

  /// "What does your note say about 'term'?" — the correct option is the
  /// note's own sentence about the term; the others are sentences about
  /// other things.
  QuizQuestion? _aboutTermQuestion(
    StudyNote note,
    String term,
    Random random,
  ) {
    final sentences = note.sentences;
    final termSentences =
        sentences.where((s) => s.toLowerCase().contains(term)).toList();
    if (termSentences.isEmpty) return null;

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
    if (options.length < 4) return null;

    options.shuffle(random);
    return QuizQuestion(
      question: "What does your note say about '$term'?",
      options: options,
      correctIndex: options.indexOf(correct),
      explanation: 'Your note says: $correct',
      topic: term,
    );
  }

  /// "Fill in the blank: '___ is the green pigment…'" — the correct
  /// option is the missing term; the others are other key terms from
  /// the same note.
  QuizQuestion? _fillInBlankQuestion(
    StudyNote note,
    String term,
    List<String> terms,
    Random random,
  ) {
    final sentences = note.sentences;
    final termSentences =
        sentences.where((s) => s.toLowerCase().contains(term)).toList();
    if (termSentences.isEmpty) return null;
    if (terms.length < 4) return null;

    final sentence = termSentences.first;
    final blanked = sentence.replaceFirst(
      RegExp('\\b$term\\b', caseSensitive: false),
      '_____',
    );
    if (blanked == sentence) return null;

    final others = terms.where((t) => t != term).toList()..shuffle(random);
    final options = <String>[term];
    for (final other in others) {
      if (options.length >= 4) break;
      if (!options.contains(other)) options.add(other);
    }
    if (options.length < 4) return null;

    options.shuffle(random);
    return QuizQuestion(
      question: 'Fill in the blank: "$blanked"',
      options: options,
      correctIndex: options.indexOf(term),
      explanation: 'Your note says: $sentence',
      topic: term,
      kind: QuizQuestionKind.fillInBlank,
    );
  }
}
