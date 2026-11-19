import '../../quiz/data/models/quiz_question.dart';

/// The language the tutor re-explains in.
enum TutorLanguage { english, urdu }

/// The AI tutor: when an answer is wrong, it does not just say "wrong" —
/// it re-explains the concept in simple words, naming the answer the
/// student actually picked and showing what the note says instead.
///
/// v0.2.0 explains from the question's own explanation — the note's
/// sentence about the topic — and quotes the student's chosen answer, so
/// the re-explanation addresses the actual mistake. It is still a local
/// template tutor, not an LLM: a real LLM tutor that generates fresh
/// explanations is on the roadmap — the interface (a question in, an
/// explanation out) stays the same.
class AiTutor {
  AiTutor({this.language = TutorLanguage.english});

  final TutorLanguage language;

  /// Builds the tutor's message after the student answers [question].
  ///
  /// Pass [chosenAnswer] (the option the student tapped) so a wrong
  /// answer is explained against what they actually picked.
  String explain(
    QuizQuestion question, {
    required bool wasCorrect,
    String? chosenAnswer,
  }) {
    if (wasCorrect) {
      return switch (language) {
        TutorLanguage.english =>
          'Correct — well done. ${question.explanation}',
        TutorLanguage.urdu =>
          'Sahi jawab — shabash! ${question.explanation}',
      };
    }
    final picked = chosenAnswer == null
        ? ''
        : switch (language) {
            TutorLanguage.english =>
              'You chose "$chosenAnswer" — that is not what your note says.\n\n',
            TutorLanguage.urdu =>
              'Aap ne "$chosenAnswer" chuna — aap ki note mein aisa nahi likha.\n\n',
          };
    return switch (language) {
      TutorLanguage.english => 'Not quite — let me explain it simply.\n\n'
          '$picked'
          '${question.explanation}\n\n'
          'In short: the right answer is "${question.correctAnswer}". '
          'Try saying it back in your own words, then answer again later — '
          'it will come back for review.',
      TutorLanguage.urdu => 'Ghalat jawab — koi baat nahi, main asaan '
          'alfaaz mein samjhata hoon.\n\n'
          '$picked'
          '${question.explanation}\n\n'
          'Mukhtasar mein: sahi jawab hai "${question.correctAnswer}". '
          'Isko apne alfaaz mein dohrayein, phir baad mein dobara koshish '
          'karein — yeh review ke liye wapas aayega.',
    };
  }
}
