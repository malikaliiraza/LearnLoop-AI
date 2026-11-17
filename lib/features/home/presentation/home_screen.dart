import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notes/data/models/study_note.dart';
import '../../notes/data/repositories/note_repository.dart';
import '../../quiz/presentation/quiz_screen.dart';

/// Home: the student's notes, each with a "Start quiz" button, plus the
/// count of topics due for spaced review.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      _notes = NoteRepository(prefs).loadNotes();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('LearnLoop AI')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quizzes from your own notes',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Pick a note, take a quiz built from it, and the '
                            'AI tutor re-explains anything you get wrong — '
                            'in simple English or Urdu. Missed topics come '
                            'back for spaced review.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Your notes', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  for (final note in _notes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          title: Text(note.title),
                          subtitle: Text(
                            '${note.sentences.length} sentences · '
                            'quiz ready',
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => QuizScreen(note: note),
                                ),
                              );
                            },
                            child: const Text('Start quiz'),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Sample notes are included so you can try the quiz and '
                    'tutor right away. PDF import is on the roadmap.',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}
