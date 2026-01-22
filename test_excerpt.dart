
import 'package:flutter/foundation.dart';

void main() {
  testExcerpt("hello world this is a test", "world", 10);
  testExcerpt("hello world this is a test", "world", 5);
  testExcerpt("hello world this is a test", "world", 20);
  testExcerpt("אבג דהו זחט", "דהו", 4);
  testExcerpt("אבג דהו זחט", "דהו", 10);
  testExcerpt("word1 word2 word3", "word2", 10);
}

void testExcerpt(String fullText, String query, int maxChars) {
  debugPrint("Text: '$fullText', Query: '$query', Max: $maxChars");
  debugPrint("Result: '${_buildSearchExcerpt(fullText: fullText, query: query, maxChars: maxChars)}'");
  debugPrint("---");
}

String _buildSearchExcerpt({
  required String fullText,
  required String query,
  required int maxChars,
}) {
  var text = fullText.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.length <= maxChars) return text;

  final q = query.trim();
  if (q.isEmpty) {
    var end = maxChars;
    if (end < text.length) {
      final nextSpace = text.indexOf(' ', end);
      if (nextSpace != -1) {
        end = nextSpace;
      } else {
        end = text.length;
      }
    }
    return '${text.substring(0, end)}...';
  }

  final terms = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  if (terms.isEmpty) {
    var end = maxChars;
    if (end < text.length) {
      final nextSpace = text.indexOf(' ', end);
      if (nextSpace != -1) {
        end = nextSpace;
      } else {
        end = text.length;
      }
    }
    return '${text.substring(0, end)}...';
  }

  final highlightRegex = RegExp(
    terms.map(RegExp.escape).join('|'),
    caseSensitive: false,
  );

  final match = highlightRegex.firstMatch(text);
  if (match == null) {
    var end = maxChars;
    if (end < text.length) {
      final nextSpace = text.indexOf(' ', end);
      if (nextSpace != -1) {
        end = nextSpace;
      } else {
        end = text.length;
      }
    }
    return '${text.substring(0, end)}...';
  }

  final len = text.length;
  var start = (match.start - (maxChars ~/ 2)).clamp(0, len);
  var end = (start + maxChars).clamp(0, len);

  // If we're at the end and didn't get enough chars, shift the window left.
  if (end - start < maxChars) {
    start = (end - maxChars).clamp(0, len);
  }

  // Adjust start to beginning of word
  if (start > 0) {
    final lastSpace = text.lastIndexOf(' ', start);
    if (lastSpace != -1) {
      start = lastSpace + 1;
    } else {
      start = 0;
    }
  }

  // Adjust end to end of word
  if (end < len) {
    final nextSpace = text.indexOf(' ', end);
    if (nextSpace != -1) {
      end = nextSpace;
    } else {
      end = len;
    }
  }

  final prefix = start > 0 ? '...' : '';
  final suffix = end < len ? '...' : '';
  return '$prefix${text.substring(start, end)}$suffix';
}
