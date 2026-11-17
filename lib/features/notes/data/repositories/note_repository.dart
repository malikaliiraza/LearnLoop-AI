import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/app_constants.dart';
import '../models/study_note.dart';

/// Local storage for study notes (SharedPreferences, offline-first).
///
/// v0.1.0 ships with two sample notes so the quiz and tutor can be tried
/// immediately; the student replaces them with their own notes. PDF import
/// is on the roadmap — it will feed the same repository.
class NoteRepository {
  NoteRepository(this._prefs);

  final SharedPreferences _prefs;

  List<StudyNote> loadNotes() {
    final raw = _prefs.getString(AppConstants.notesStorageKey);
    if (raw == null) return _sampleNotes();
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => StudyNote.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _sampleNotes();
    }
  }

  Future<void> saveNotes(List<StudyNote> notes) async {
    final raw = jsonEncode(notes.map((n) => n.toJson()).toList());
    await _prefs.setString(AppConstants.notesStorageKey, raw);
  }

  Future<void> addNote(StudyNote note) async {
    final notes = loadNotes()..add(note);
    await saveNotes(notes);
  }

  /// Two short sample notes, clearly labelled as samples.
  static List<StudyNote> _sampleNotes() {
    final now = DateTime.now();
    return [
      StudyNote(
        id: 'sample-photosynthesis',
        title: 'Sample: Photosynthesis',
        content:
            'Photosynthesis is the process by which green plants make their own food. '
            'Chlorophyll is the green pigment in leaves that captures sunlight. '
            'Photosynthesis takes place mainly in the leaves of the plant. '
            'The plant uses carbon dioxide from the air and water from the soil. '
            'Oxygen is released as a by-product of photosynthesis. '
            'Sunlight provides the energy that drives photosynthesis.',
        createdAt: now,
      ),
      StudyNote(
        id: 'sample-flutter-widgets',
        title: 'Sample: Flutter Widgets',
        content:
            'A widget is the basic building block of a Flutter user interface. '
            'StatelessWidget is a widget that never changes after it is built. '
            'StatefulWidget is a widget that can change over time when its state changes. '
            'The build method describes what the widget looks like on screen. '
            'Widgets are arranged in a tree, with parent widgets holding child widgets. '
            'Flutter rebuilds only the widgets whose state has changed.',
        createdAt: now,
      ),
    ];
  }
}
