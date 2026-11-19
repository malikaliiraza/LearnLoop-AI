import 'package:flutter_test/flutter_test.dart';
import 'package:learnloop_ai/features/notes/data/models/study_note.dart';
import 'package:learnloop_ai/features/quiz/data/models/quiz_question.dart';
import 'package:learnloop_ai/features/quiz/domain/quiz_generator.dart';

void main() {
  const noteText =
      'Photosynthesis is the process by which green plants make their own food. '
      'Chlorophyll is the green pigment in leaves that captures sunlight. '
      'Photosynthesis takes place mainly in the leaves of the plant. '
      'The plant uses carbon dioxide from the air and water from the soil. '
      'Oxygen is released as a by-product of photosynthesis. '
      'Sunlight provides the energy that drives photosynthesis.';

  StudyNote note() => StudyNote(
        id: 'test-note',
        title: 'Test note',
        content: noteText,
        createdAt: DateTime(2026, 11, 17),
      );

  group('QuizGenerator', () {
    test('returns empty quiz for a note too short to quiz on', () {
      final short = StudyNote(
        id: 'short',
        title: 'Short',
        content: 'One sentence only.',
        createdAt: DateTime(2026, 11, 17),
      );
      expect(QuizGenerator(randomSeed: 1).generateQuiz(short), isEmpty);
    });

    test('extracts repeated key terms, most frequent first', () {
      final terms = QuizGenerator(randomSeed: 1).extractKeyTerms(noteText);
      expect(terms.first, 'photosynthesis');
      expect(terms, contains('leaves'));
      expect(terms, contains('sunlight'));
    });

    test('builds questions with 4 options and a valid correct index', () {
      final questions =
          QuizGenerator(randomSeed: 42).generateQuiz(note(), questionCount: 3);
      expect(questions.length, 3);
      for (final q in questions) {
        expect(q.options.length, 4);
        expect(q.correctIndex, inInclusiveRange(0, 3));
        expect(q.options[q.correctIndex].toLowerCase(), contains(q.topic));
        expect(q.options.toSet().length, 4,
            reason: 'options must be unique');
      }
    });

    test('same seed builds the same quiz', () {
      final a = QuizGenerator(randomSeed: 7).generateQuiz(note());
      final b = QuizGenerator(randomSeed: 7).generateQuiz(note());
      expect(
        a.map((q) => q.question).toList(),
        b.map((q) => q.question).toList(),
      );
    });

    test('mixes fill-in-the-blank questions into the quiz', () {
      final questions =
          QuizGenerator(randomSeed: 42).generateQuiz(note(), questionCount: 5);
      final blanks = questions.where(
          (q) => q.kind == QuizQuestionKind.fillInBlank);
      expect(blanks, isNotEmpty);
      for (final q in blanks) {
        expect(q.question, contains('Fill in the blank'));
        expect(q.question, contains('_____'));
        expect(q.options, contains(q.topic));
        expect(q.options.toSet().length, 4);
      }
    });

    test('generateQuizForTopic builds questions about that topic only', () {
      final questions = QuizGenerator(randomSeed: 3)
          .generateQuizForTopic(note(), 'photosynthesis');
      expect(questions, isNotEmpty);
      expect(questions.every((q) => q.topic == 'photosynthesis'), isTrue);
    });

    test('generateQuizForTopic returns empty for an unknown topic', () {
      expect(
        QuizGenerator(randomSeed: 3)
            .generateQuizForTopic(note(), 'mitochondria'),
        isEmpty,
      );
    });
  });
}
