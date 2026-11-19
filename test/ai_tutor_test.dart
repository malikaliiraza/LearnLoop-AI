import 'package:flutter_test/flutter_test.dart';
import 'package:learnloop_ai/features/quiz/data/models/quiz_question.dart';
import 'package:learnloop_ai/features/tutor/domain/ai_tutor.dart';

void main() {
  final question = QuizQuestion(
    question: "What does your note say about 'chlorophyll'?",
    options: [
      'Chlorophyll is the green pigment in leaves that captures sunlight.',
      'It is not mentioned in your note.',
      'Your note says the opposite.',
      'None of the above.',
    ],
    correctIndex: 0,
    explanation:
        'Your note says: Chlorophyll is the green pigment in leaves that captures sunlight.',
    topic: 'chlorophyll',
  );

  group('AiTutor', () {
    test('names the chosen answer when it was wrong (English)', () {
      final message = AiTutor().explain(
        question,
        wasCorrect: false,
        chosenAnswer: 'It is not mentioned in your note.',
      );
      expect(message, contains('You chose "It is not mentioned in your note."'));
      expect(message, contains('Chlorophyll is the green pigment'));
      expect(message, contains('the right answer is'));
    });

    test('names the chosen answer when it was wrong (Urdu)', () {
      final message = AiTutor(language: TutorLanguage.urdu).explain(
        question,
        wasCorrect: false,
        chosenAnswer: 'It is not mentioned in your note.',
      );
      expect(message, contains('Aap ne "It is not mentioned in your note." chuna'));
      expect(message, contains('sahi jawab hai'));
    });

    test('praises a correct answer without naming a choice', () {
      final message =
          AiTutor().explain(question, wasCorrect: true);
      expect(message, startsWith('Correct'));
      expect(message, contains('Chlorophyll is the green pigment'));
    });
  });
}
