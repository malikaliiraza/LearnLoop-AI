/// A study note: the student's own text that quizzes are built from.
///
/// In v0.1.0 a note is typed or pasted text. Importing a PDF is on the
/// roadmap — the generator works on the text, so the source does not matter.
class StudyNote {
  StudyNote({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory StudyNote.fromJson(Map<String, dynamic> json) {
    return StudyNote(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

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
    };
  }
}
