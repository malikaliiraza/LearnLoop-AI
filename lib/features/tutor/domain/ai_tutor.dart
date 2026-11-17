import '../../quiz/data/models/quiz_question.dart';

/// The language the tutor re-explains in.
enum TutorLanguage { english, urdu }

/// The AI tutor: when an answer is wrong, it does not just say "wrong" —
/// it re-explains the concept in simple words.
///
/// v0.1.0 is a local template tutor that re-explains from the question's own
/// explanation, in English or simple Roman Urdu. A real LLM tutor that
/// generates fresh explanations is on the roadmap — the interface (a
/// question in, an explanation out) stays the same.
class AiTutor {
  AiTutor({this.language = TutorLanguage.english});

  final TutorLanguage language;

  /// Builds the tutor's message after the student answers [question].
  String explain(QuizQuestion question, {required bool wasCorrect}) {
    if (wasCorrect) {
      return switch (language) {
        TutorLanguage.english =>
          'Correct — well done. ${question.explanation}',
        TutorLanguage.urdu =>
          'Sahi jawab — shabash! ${question.explanation}',
      };
    }
    return switch (language) {
      TutorLanguage.english => 'Not quite — let me explain it simply.\n\n'
          '${question.explanation}\n\n'
          'In short: the right answer is "${question.correctAnswer}". '
          'Try saying it back in your own words, then answer again later — '
          'it will come back for review.',
      TutorLanguage.urdu => 'Ghalat jawab — koi baat nahi, main asaan '
          'alfaaz mein samjhata hoon.\n\n'
          '${question.explanation}\n\n'
          'Mukhtasar mein: sahi jawab hai "${question.correctAnswer}". '
          'Isko apne alfaaz mein dohrayein, phir baad mein dobara koshish '
          'karein — yeh review ke liye wapas aayega.',
    };
  }
}
