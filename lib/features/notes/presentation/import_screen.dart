import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notes/data/repositories/note_repository.dart';
import '../../notes/domain/note_importer.dart';

/// Add your own notes: paste text, or import a .txt file or a PDF.
///
/// The quiz generator works on the imported text, so a quiz from an
/// imported PDF behaves exactly like one from a typed note. A PDF needs a
/// real text layer — scanned pages have none, and the screen says so
/// instead of pretending the import worked.
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _importer = NoteImporter();
  bool _busy = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveResult(NoteImportResult result) async {
    if (!result.ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Import failed.')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await NoteRepository(prefs).addNote(result.note!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('“${result.note!.title}” imported.')),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _savePasted() async {
    setState(() => _busy = true);
    await _saveResult(
      _importer.fromPastedText(
        _titleController.text,
        _contentController.text,
      ),
    );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _pickTextFile() async {
    setState(() => _busy = true);
    await _saveResult(await _importer.pickTextFile());
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _pickPdfFile() async {
    setState(() => _busy = true);
    await _saveResult(await _importer.pickPdfFile());
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Import a note')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Biology — Chapter 3',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Paste your notes here',
                hintText: 'Paste at least a paragraph — the quiz needs '
                    '4+ sentences with a repeated key term.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _busy ? null : _savePasted,
              child: const Text('Save pasted note'),
            ),
            const SizedBox(height: 24),
            Text('Or import a file', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickTextFile,
              icon: const Icon(Icons.description),
              label: const Text('Import a .txt file'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickPdfFile,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Import a PDF'),
            ),
            const SizedBox(height: 12),
            Text(
              'PDFs need a text layer to quiz from. Scanned pages are '
              'pictures, not text — for those, paste the text above.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
