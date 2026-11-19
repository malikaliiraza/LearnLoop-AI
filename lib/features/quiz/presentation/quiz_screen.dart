import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notes/data/models/study_note.dart';
import '../data/models/quiz_question.dart';
import '../domain/quiz_generator.dart';
import '../../tutor/domain/ai_tutor.dart';
import '../../review/data/repositories/review_repository.dart';
import '../../review/domain/spaced_repetition.dart';

/// One question at a time. Tapping an option reveals whether it was right
/// and the tutor's re-explanation — which names the answer actually picked
/// when it was wrong; "Next" moves on. At the end, the score is shown and
/// every answered topic is saved to the spaced-review schedule on the
/// device (right answers move further out, wrong ones come back tomorrow).
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.note, this.topic});

  final StudyNote note;

  /// When set, the quiz covers this topic only (a due-review quiz).
  final String? topic;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<QuizQuestion> _questions;
  int _index = 0;
  int? _selected;
  int _score = 0;
  bool _finished = false;
  final List<String> _missedTopics = [];
  final Map<String, bool> _results = {};
  bool _reviewsSaved = false;
  TutorLanguage _language = TutorLanguage.english;

  @override
  void initState() {
    super.initState();
    final generator = QuizGenerator();
    _questions = widget.topic == null
        ? generator.generateQuiz(widget.note)
        : generator.generateQuizForTopic(widget.note, widget.topic!);
  }

  QuizQuestion get _current => _questions[_index];

  void _answer(int selected) {
    if (_selected != null) return;
    final correct = _current.isCorrect(selected);
    setState(() {
      _selected = selected;
      _results[_current.topic] = correct;
      if (correct) {
        _score += 1;
      } else {
        _missedTopics.add(_current.topic);
      }
    });
  }

  void _next() {
    setState(() {
      if (_index + 1 >= _questions.length) {
        _finished = true;
      } else {
        _index += 1;
        _selected = null;
      }
    });
    if (_finished) _saveReviews();
  }

  /// Persists the SM-2 schedule for every answered topic: right answers
  /// reschedule further out, wrong ones come back tomorrow.
  Future<void> _saveReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final repository = ReviewRepository(prefs);
    for (final entry in _results.entries) {
      await repository.recordAnswer(entry.key, entry.value ? 4 : 2);
    }
    if (mounted) setState(() => _reviewsSaved = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note.title),
        actions: [
          PopupMenuButton<TutorLanguage>(
            icon: const Icon(Icons.translate),
            tooltip: 'Tutor language',
            onSelected: (value) => setState(() => _language = value),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: TutorLanguage.english,
                child: Text('Tutor: English'),
              ),
              PopupMenuItem(
                value: TutorLanguage.urdu,
                child: Text('Tutor: Urdu (Roman)'),
              ),
            ],
          ),
        ],
      ),
      body: _questions.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This note is too short to quiz on yet — '
                  'add at least 4 sentences with a repeated key term.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _finished
              ? _buildResult(theme)
              : _buildQuestion(theme),
    );
  }

  Widget _buildQuestion(ThemeData theme) {
    final tutor = AiTutor(language: _language);
    final answered = _selected != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Question ${_index + 1} of ${_questions.length}',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_index + (_selected != null ? 1 : 0)) / _questions.length,
          ),
          const SizedBox(height: 20),
          Text(_current.question, style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),
          for (var i = 0; i < _current.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _optionButton(i, answered, theme),
            ),
          if (answered) ...[
            const SizedBox(height: 8),
            Card(
              color: _current.isCorrect(_selected!)
                  ? Colors.green.shade50
                  : Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  tutor.explain(
                    _current,
                    wasCorrect: _current.isCorrect(_selected!),
                    chosenAnswer: _current.isCorrect(_selected!)
                        ? null
                        : _current.options[_selected!],
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _next,
              child: Text(
                _index + 1 >= _questions.length ? 'See result' : 'Next question',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _optionButton(int i, bool answered, ThemeData theme) {
    Color? color;
    if (answered) {
      if (i == _current.correctIndex) {
        color = Colors.green.shade100;
      } else if (i == _selected) {
        color = Colors.red.shade100;
      }
    }
    return Material(
      color: color ?? theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _answer(i),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_current.options[i]),
        ),
      ),
    );
  }

  Widget _buildResult(ThemeData theme) {
    final scheduler = SpacedRepetition();
    final reviewLine = _missedTopics.isEmpty
        ? 'Nothing to review — every topic is on schedule.'
        : 'These topics are scheduled for review tomorrow: '
            '${_missedTopics.toSet().join(', ')}.';
    // Show the next review date for the first missed topic (SM-2, quality 2).
    final nextReview = _missedTopics.isEmpty
        ? null
        : scheduler
            .scheduleNext(ReviewCard(topic: _missedTopics.first), 2)
            .dueDate;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            'You scored $_score out of ${_questions.length}',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(reviewLine, textAlign: TextAlign.center),
          if (nextReview != null) ...[
            const SizedBox(height: 8),
            Text(
              'Next review: ${nextReview.day}/${nextReview.month}/${nextReview.year}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (_reviewsSaved) ...[
            const SizedBox(height: 8),
            Text(
              'Review schedule saved on this device — missed topics will '
              'appear under “Due for review” on the home screen.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to notes'),
          ),
        ],
      ),
    );
  }
}
