/// Where a note came from: a built-in sample, typed/pasted text, a text
/// file, or a PDF.
enum StudyNoteSource { sample, typed, pasted, file, pdf }

/// A study note: the student's own text that quizzes are built from.
///
/// In v0.1.0 a note is typed or pasted text. v0.2.0 adds real import: paste,
/// a .txt file, or a PDF's text layer — the generator works on the text,
/// so the source does not matter, but the home screen shows it honestly.
class StudyNote {
  StudyNote({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.source = StudyNoteSource.typed,
  });

  factory StudyNote.fromJson(Map<String, dynamic> json) {
    return StudyNote(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      source: StudyNoteSource.values.firstWhere(
        (s) => s.name == (json['source'] as String? ?? 'typed'),
        orElse: () => StudyNoteSource.typed,
      ),
    );
  }

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  /// Where this note came from.
  final StudyNoteSource source;

  /// Short label for the home screen, e.g. "PDF" or "Sample".
  String get sourceLabel => switch (source) {
        StudyNoteSource.sample => 'Sample',
        StudyNoteSource.typed => 'Typed',
        StudyNoteSource.pasted => 'Pasted',
        StudyNoteSource.file => 'Text file',
        StudyNoteSource.pdf => 'PDF',
      };

  /// True when the note is long enough for the quiz generator to use.
  bool get isQuizReady =>
      sentences.length >= 4 && content.length >= 100;

  /// The note's sentences, in order. Used by the quiz generator.
  List<String> get sentences {
    return content
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.length > 1)
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'source': source.name,
    };
  }
}
