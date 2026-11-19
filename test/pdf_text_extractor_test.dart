import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnloop_ai/features/notes/domain/pdf_text_extractor.dart';

/// Builds a minimal one-page PDF whose content stream shows [content].
/// When [flate] is true the stream is FlateDecode-compressed, like most
/// real PDFs; otherwise it is plain text.
List<int> buildPdf(String content, {bool flate = false}) {
  final contentBytes = latin1.encode(content);
  final streamBytes =
      flate ? const ZLibEncoder().encode(contentBytes) : contentBytes;
  final filter = flate ? ' /Filter /FlateDecode' : '';
  final pdf = '%PDF-1.4\n'
      '1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n'
      '2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n'
      '3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
      '/Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >> endobj\n'
      '4 0 obj << /Length ${streamBytes.length}$filter >> stream\n'
      '${latin1.decode(streamBytes)}\n'
      'endstream endobj\n'
      '5 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n'
      '%%EOF\n';
  return latin1.encode(pdf);
}

void main() {
  final extractor = PdfTextExtractor();

  group('PdfTextExtractor', () {
    test('extracts text from an uncompressed Tj stream', () {
      const content = 'BT /F1 12 Tf 72 720 Td '
          '(Photosynthesis is the process by which green plants make food.) Tj ET';
      expect(extractor.extractText(buildPdf(content)), contains('Photosynthesis'));
    });

    test('extracts text from a FlateDecode stream', () {
      const content = 'BT /F1 12 Tf 72 720 Td '
          '(Chlorophyll captures sunlight in the leaves.) Tj ET';
      expect(extractor.extractText(buildPdf(content, flate: true)),
          contains('Chlorophyll captures sunlight'));
    });

    test('extracts text from a TJ array', () {
      const content = 'BT /F1 12 Tf 72 720 Td '
          '[(Hello ) -120 (world)] TJ ET';
      expect(extractor.extractText(buildPdf(content)), 'Hello world');
    });

    test('unescapes parentheses inside literal strings', () {
      // The literal string itself needs escaped parens in the PDF.
      const escaped =
          'BT /F1 12 Tf 72 720 Td (Photosynthesis \\(the process\\) makes food.) Tj ET';
      expect(extractor.extractText(buildPdf(escaped)),
          contains('Photosynthesis (the process) makes food.'));
    });

    test('returns empty for a PDF with no text layer', () {
      expect(extractor.extractText(buildPdf('BT ET')), isEmpty);
    });

    test('returns empty for non-PDF bytes', () {
      expect(extractor.extractText(utf8.encode('not a pdf at all')), isEmpty);
      expect(extractor.extractText([]), isEmpty);
    });
  });
}
