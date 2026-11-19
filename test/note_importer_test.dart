import 'package:flutter_test/flutter_test.dart';
import 'package:learnloop_ai/features/notes/data/models/study_note.dart';
import 'package:learnloop_ai/features/notes/domain/note_importer.dart';

void main() {
  const longText =
      'Photosynthesis is the process by which green plants make their own food. '
      'Chlorophyll is the green pigment in leaves that captures sunlight. '
      'Photosynthesis takes place mainly in the leaves of the plant. '
      'The plant uses carbon dioxide from the air and water from the soil. '
      'Oxygen is released as a by-product of photosynthesis. '
      'Sunlight provides the energy that drives photosynthesis.';

  group('NoteImporter.fromPastedText', () {
    test('builds a pasted note from title and text', () {
      final result =
          NoteImporter().fromPastedText('Biology notes', longText);
      expect(result.ok, isTrue);
      expect(result.note, isNotNull);
      expect(result.note!.title, 'Biology notes');
      expect(result.note!.content, longText);
      expect(result.note!.source, StudyNoteSource.pasted);
      expect(result.note!.isQuizReady, isTrue);
    });

    test('rejects an empty title', () {
      final result = NoteImporter().fromPastedText('   ', longText);
      expect(result.ok, isFalse);
      expect(result.error, contains('title'));
    });

    test('rejects text too short to quiz on', () {
      final result =
          NoteImporter().fromPastedText('Short', 'One sentence.');
      expect(result.ok, isFalse);
      expect(result.error, contains('too short'));
    });
  });
}
