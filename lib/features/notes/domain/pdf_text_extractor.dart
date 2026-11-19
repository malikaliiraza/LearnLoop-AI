import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Extracts the text layer from a PDF file, in pure Dart (works on web).
///
/// Reads the PDF's content streams, inflates FlateDecode streams with the
/// pure-Dart `archive` decoder, and pulls the text out of the `Tj` / `TJ`
/// show-text operators. Only PDFs with a real text layer work: scanned or
/// image-only PDFs have no text to extract and return an empty string —
/// the import screen says so honestly instead of inventing text.
/// Encrypted PDFs and PDFs with custom font encodings are not supported.
class PdfTextExtractor {
  /// The extracted text, or an empty string when the PDF has no readable
  /// text layer (or is not a PDF at all).
  String extractText(List<int> bytes) {
    if (bytes.length < 5 ||
        latin1.decode(bytes.sublist(0, 5)) != '%PDF-') {
      return '';
    }

    final runs = <String>[];
    var searchFrom = 0;
    while (true) {
      final streamStart = _indexOf(bytes, _streamMarker, searchFrom);
      if (streamStart < 0) break;
      var contentStart = streamStart + _streamMarker.length;
      // "stream" is followed by \r\n or \n.
      if (contentStart < bytes.length && bytes[contentStart] == 0x0D) {
        contentStart += 1;
      }
      if (contentStart < bytes.length && bytes[contentStart] == 0x0A) {
        contentStart += 1;
      }
      final streamEnd = _indexOf(bytes, _endStreamMarker, contentStart);
      if (streamEnd < 0) break;
      final streamBytes = bytes.sublist(contentStart, streamEnd);
      final dictStart = streamStart - 512 < 0 ? 0 : streamStart - 512;
      final dict = latin1.decode(bytes.sublist(dictStart, streamStart));
      final decoded = dict.contains('FlateDecode')
          ? _inflate(streamBytes)
          : streamBytes;
      if (decoded != null) {
        runs.addAll(_textRuns(latin1.decode(decoded)));
      }
      searchFrom = streamEnd + _endStreamMarker.length;
    }

    return runs
        .map((r) => r.trim())
        .where((r) => r.isNotEmpty)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const List<int> _streamMarker = <int>[0x73, 0x74, 0x72, 0x65, 0x61, 0x6D]; // stream
  static const List<int> _endStreamMarker =
      <int>[0x65, 0x6E, 0x64, 0x73, 0x74, 0x72, 0x65, 0x61, 0x6D]; // endstream

  List<int>? _inflate(List<int> bytes) {
    try {
      return const ZLibDecoder().decodeBytes(Uint8List.fromList(bytes));
    } catch (_) {
      return null;
    }
  }

  /// The text strings shown by the `Tj` / `TJ` operators in one content
  /// stream, in order.
  List<String> _textRuns(String content) {
    final runs = <String>[];
    // "(...) Tj" — a single literal string.
    final tjPattern = RegExp(r'\((?:\\.|[^()\\])*\)\s*Tj');
    for (final match in tjPattern.allMatches(content)) {
      final literal = match.group(0)!;
      final end = literal.lastIndexOf(')');
      runs.add(_unescape(literal.substring(0, end + 1)));
    }
    // "[(...) (...) -120 (...) ] TJ" — an array of strings and kern numbers.
    final tjArrayPattern =
        RegExp(r'\[(?:[^\[\]]|\((?:\\.|[^()\\])*\))*\]\s*TJ');
    for (final match in tjArrayPattern.allMatches(content)) {
      final array = match.group(0)!;
      final stringPattern = RegExp(r'\((?:\\.|[^()\\])*\)');
      final parts = stringPattern
          .allMatches(array)
          .map((m) => _unescape(m.group(0)!))
          .join();
      runs.add(parts);
    }
    return runs;
  }

  /// Unescapes a PDF literal string, including its outer parentheses.
  String _unescape(String literal) {
    final inner = literal.substring(1, literal.length - 1);
    final out = StringBuffer();
    var i = 0;
    while (i < inner.length) {
      final ch = inner[i];
      if (ch != '\\' || i + 1 >= inner.length) {
        out.write(ch);
        i += 1;
        continue;
      }
      final next = inner[i + 1];
      switch (next) {
        case 'n':
          out.write('\n');
          i += 2;
        case 'r':
          out.write('\r');
          i += 2;
        case 't':
          out.write('\t');
          i += 2;
        case '(':
        case ')':
        case '\\':
          out.write(next);
          i += 2;
        default:
          if (RegExp(r'[0-7]').hasMatch(next)) {
            var octal = '';
            var j = i + 1;
            while (j < inner.length &&
                j < i + 4 &&
                RegExp(r'[0-7]').hasMatch(inner[j])) {
              octal += inner[j];
              j += 1;
            }
            out.writeCharCode(int.parse(octal, radix: 8));
            i = j;
          } else {
            // Backslash before any other character: the character itself.
            out.write(next);
            i += 2;
          }
      }
    }
    return out.toString();
  }

  int _indexOf(List<int> haystack, List<int> needle, int from) {
    outer:
    for (var i = from; i + needle.length <= haystack.length; i++) {
      for (var j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) continue outer;
      }
      return i;
    }
    return -1;
  }
}
