import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notes/data/models/study_note.dart';
import '../../notes/data/repositories/note_repository.dart';
import '../../quiz/presentation/quiz_screen.dart';
import '../data/repositories/review_repository.dart';
import '../domain/spaced_repetition.dart';

/// The topics due for spaced review, with the note each one came from.
///
/// Tapping a topic opens a short quiz on that topic alone, built from the
/// note it belongs to. Answering it reschedules the topic (SM-2), so the
/// list shrinks as the student gets topics right.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  List<ReviewCard> _due = [];
  List<StudyNote> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _due = ReviewRepository(prefs).dueCards();
      _notes = NoteRepository(prefs).loadNotes();
      _loading = false;
    });
  }

  StudyNote? _noteForTopic(String topic) {
    for (final note in _notes) {
      if (note.content.toLowerCase().contains(topic.toLowerCase())) {
        return note;
      }
    }
    return null;
  }

  String _dateLabel(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Due for review')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _due.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nothing due right now. Finish a quiz and the '
                      'topics you miss will appear here tomorrow.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _due.length,
                  itemBuilder: (context, index) {
                    final card = _due[index];
                    final note = _noteForTopic(card.topic);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          title: Text(card.topic),
                          subtitle: Text(
                            note == null
                                ? 'Due since ${_dateLabel(card.dueDate)}'
                                : 'From “${note.title}” · '
                                    'due since ${_dateLabel(card.dueDate)}',
                          ),
                          trailing: ElevatedButton(
                            onPressed: note == null
                                ? null
                                : () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => QuizScreen(
                                          note: note,
                                          topic: card.topic,
                                        ),
                                      ),
                                    );
                                    _load();
                                  },
                            child: const Text('Review'),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
