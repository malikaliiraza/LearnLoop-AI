import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../../../../core/app_constants.dart';
import '../data/models/study_note.dart';
import 'pdf_text_extractor.dart';

/// The result of an import: either a note, or an honest error message.
class NoteImportResult {
  const NoteImportResult({this.note, this.error});

  final StudyNote? note;
  final String? error;

  bool get ok => note != null;
}

/// Turns the student's own material — pasted text, a .txt file, or a PDF —
/// into a [StudyNote] the quiz generator can work on.
///
/// File picking uses `file_picker`, which works on web and mobile. PDF text
/// comes from [PdfTextExtractor]; a PDF with no text layer (scanned pages)
/// is reported as an error, not silently turned into an empty note.
class NoteImporter {
  NoteImporter({PdfTextExtractor? extractor})
      : _extractor = extractor ?? PdfTextExtractor();

  final PdfTextExtractor _extractor;

  /// Builds a note from pasted text. Pure logic — unit-tested.
  NoteImportResult fromPastedText(String title, String content) {
    final cleanTitle = title.trim();
    final cleanContent = content.trim();
    if (cleanTitle.isEmpty) {
      return const NoteImportResult(
          error: 'Give the note a title first.');
    }
    if (cleanContent.length < AppConstants.minImportChars) {
      return const NoteImportResult(
          error: 'That text is too short to quiz on — paste at least a '
              'paragraph (about ${AppConstants.minImportChars} characters).');
    }
    return NoteImportResult(
      note: StudyNote(
        id: 'import-${DateTime.now().millisecondsSinceEpoch}',
        title: cleanTitle,
        content: cleanContent,
        createdAt: DateTime.now(),
        source: StudyNoteSource.pasted,
      ),
    );
  }

  /// Lets the student pick a .txt file and turns it into a note.
  Future<NoteImportResult> pickTextFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['txt'],
    );
    if (files.isEmpty) {
      return const NoteImportResult(error: 'No file chosen.');
    }
    final file = files.single;
    final bytes = await file.readAsBytes();
    final text = utf8.decode(bytes, allowMalformed: true).trim();
    if (text.length < AppConstants.minImportChars) {
      return NoteImportResult(
          error: '“${file.name}” has too little text to quiz on — it needs '
              'at least a paragraph.');
    }
    return NoteImportResult(
      note: StudyNote(
        id: 'import-${DateTime.now().millisecondsSinceEpoch}',
        title: _titleFromFileName(file.name),
        content: text,
        createdAt: DateTime.now(),
        source: StudyNoteSource.file,
      ),
    );
  }

  /// Lets the student pick a PDF and turns its text layer into a note.
  Future<NoteImportResult> pickPdfFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (files.isEmpty) {
      return const NoteImportResult(error: 'No file chosen.');
    }
    final file = files.single;
    final text = _extractor.extractText(await file.readAsBytes());
    if (text.length < AppConstants.minImportChars) {
      return NoteImportResult(
          error: 'No readable text found in “${file.name}” — it may be '
              'scanned pages, which have no text layer. Paste the text '
              'instead.');
    }
    return NoteImportResult(
      note: StudyNote(
        id: 'import-${DateTime.now().millisecondsSinceEpoch}',
        title: _titleFromFileName(file.name),
        content: text,
        createdAt: DateTime.now(),
        source: StudyNoteSource.pdf,
      ),
    );
  }

  String _titleFromFileName(String name) {
    final withoutExtension = name.contains('.')
        ? name.substring(0, name.lastIndexOf('.'))
        : name;
    return withoutExtension.replaceAll(RegExp(r'[-_]'), ' ').trim();
  }
}
