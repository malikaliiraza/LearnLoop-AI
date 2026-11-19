import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notes/data/models/study_note.dart';
import '../../notes/data/repositories/note_repository.dart';
import '../../notes/presentation/import_screen.dart';
import '../../quiz/presentation/quiz_screen.dart';
import '../../review/data/repositories/review_repository.dart';
import '../../review/presentation/review_screen.dart';

/// Home: the student's notes, each with a "Start quiz" button, plus the
/// topics due for spaced review and a way to import new notes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<StudyNote> _notes = [];
  int _dueCount = 0;
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
      _dueCount = ReviewRepository(prefs).dueCards().length;
      _loading = false;
    });
  }

  Future<void> _openImport() async {
    final imported = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const ImportScreen()),
    );
    if (imported == true) _load();
  }

  Future<void> _openReview() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ReviewScreen()),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('LearnLoop AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Import a note',
            onPressed: _openImport,
          ),
        ],
      ),
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
                  if (_dueCount > 0) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: Colors.amber.shade50,
                      child: ListTile(
                        leading: const Icon(Icons.schedule),
                        title: Text(
                          '$_dueCount topic${_dueCount == 1 ? '' : 's'} due for review',
                        ),
                        trailing: ElevatedButton(
                          onPressed: _openReview,
                          child: const Text('Review'),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Your notes', style: theme.textTheme.titleLarge),
                      TextButton.icon(
                        onPressed: _openImport,
                        icon: const Icon(Icons.add),
                        label: const Text('Import'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final note in _notes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          title: Text(note.title),
                          subtitle: Text(
                            '${note.sentences.length} sentences · '
                            '${note.sourceLabel} · '
                            '${note.isQuizReady ? 'quiz ready' : 'too short to quiz'}',
                          ),
                          trailing: note.isQuizReady
                              ? ElevatedButton(
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            QuizScreen(note: note),
                                      ),
                                    );
                                    _load();
                                  },
                                  child: const Text('Start quiz'),
                                )
                              : null,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Sample notes are included so you can try the quiz and '
                    'tutor right away. Import your own notes as pasted text, '
                    'a .txt file, or a PDF.',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}
