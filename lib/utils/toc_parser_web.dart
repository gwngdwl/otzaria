import 'package:flutter/foundation.dart';
import 'package:otzaria/models/books.dart';

/// Web implementation of TocParser
/// On web, we can't read files directly from the file system
class TocParser {
  /// Parse TOC from a file path - not supported on web
  static Future<List<Map<String, dynamic>>> parseFlatFromFile(
      String bookPath) async {
    debugPrint('Web: parseFlatFromFile not supported');
    return [];
  }

  /// Parse TOC entries (hierarchical) from the full book content.
  static List<TocEntry> parseEntriesFromContent(String content) {
    final headers = _extractHeaders(content);
    return _buildHierarchy(headers);
  }

  static List<_Header> _extractHeaders(String content) {
    final lines = content.split('\n');
    final List<_Header> headers = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('<h') && line.length > 3) {
        final c = line[2];
        final code = c.codeUnitAt(0);
        if (code >= '1'.codeUnitAt(0) && code <= '6'.codeUnitAt(0)) {
          final level = int.tryParse(c) ?? 1;
          final text = _stripHtmlTags(line);
          if (text.isNotEmpty) {
            headers.add(_Header(text: text, index: i, level: level));
          }
          continue;
        }
      }
    }

    return headers;
  }

  static List<TocEntry> _buildHierarchy(List<_Header> headers) {
    final List<TocEntry> roots = [];
    final Map<int, TocEntry> parents = {};

    for (final h in headers) {
      if (h.level <= 1) {
        final root = TocEntry(text: h.text, index: h.index, level: 1);
        roots.add(root);
        parents[1] = root;
        continue;
      }

      final parent = parents[h.level - 1];
      final entry = TocEntry(
        text: h.text,
        index: h.index,
        level: h.level,
        parent: parent,
      );
      if (parent != null) {
        parent.children.add(entry);
      } else {
        roots.add(entry);
      }
      parents[h.level] = entry;
    }

    return roots;
  }

  static String _stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

class _Header {
  final String text;
  final int index;
  final int level;
  _Header({required this.text, required this.index, required this.level});
}
