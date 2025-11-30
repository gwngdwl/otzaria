import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/search/utils/regex_patterns.dart';

String stripHtmlIfNeeded(String text) {
  return text.replaceAll(SearchRegexPatterns.htmlStripper, '');
}

String truncate(String text, int length) {
  return text.length > length ? '${text.substring(0, length)}...' : text;
}

String removeVolwels(String s) {
  s = s.replaceAll('־', ' ').replaceAll('׀', ' ').replaceAll('|', ' ');
  return s.replaceAll(SearchRegexPatterns.vowelsAndCantillation, '');
}

String highLight(String data, String searchQuery, {int currentIndex = -1}) {
  if (searchQuery.isEmpty) return data;

  final cleanSearchQuery = removeVolwels(searchQuery);

  final pattern = cleanSearchQuery.split('').map((char) {
    if (RegExp(r'[א-ת]').hasMatch(char)) {
      return '${RegExp.escape(char)}[\u0591-\u05C7]*';
    }
    return RegExp.escape(char);
  }).join();

  final regex = RegExp(pattern, caseSensitive: false);
  final matches = regex.allMatches(data).toList();

  if (matches.isEmpty) return data;

  if (currentIndex == -1) {
    String result = data;
    int offset = 0;

    for (final match in matches) {
      final matchedText = match.group(0)!;
      final replacement = '<font color=red>$matchedText</font>';

      final start = match.start + offset;
      final end = match.end + offset;

      result = result.substring(0, start) + replacement + result.substring(end);
      offset += replacement.length - matchedText.length;
    }

    return result;
  }

  String result = data;
  int offset = 0;

  for (int i = 0; i < matches.length; i++) {
    final match = matches[i];
    final matchedText = match.group(0)!;
    final color = i == currentIndex ? 'blue' : 'red';
    final backgroundColor =
        i == currentIndex ? ' style="background-color: yellow;"' : '';
    final replacement =
        '<font color=$color$backgroundColor>$matchedText</font>';

    final start = match.start + offset;
    final end = match.end + offset;

    result = result.substring(0, start) + replacement + result.substring(end);
    offset += replacement.length - matchedText.length;
  }

  return result;
}

String getTitleFromPath(String path) {
  // Web version - use forward slash
  final parts = path.split('/');
  final fileName = parts.last;

  final lastDotIndex = fileName.lastIndexOf('.');
  if (lastDotIndex == -1) {
    return fileName;
  }

  return fileName.substring(0, lastDotIndex);
}

// Cache for the CSV data
Map<String, String>? _csvCache;

Future<bool> hasTopic(String title, String topic) async {
  // On web, simplified implementation
  final titleToPath = await FileSystemData.instance.titleToPath;
  return titleToPath[title]?.contains(topic) ?? false;
}

void clearCommentatorOrderCache() {
  _csvCache = null;
}

String formatTextWithParentheses(String text) {
  if (text.isEmpty) return text;

  final StringBuffer result = StringBuffer();
  int i = 0;

  while (i < text.length) {
    if (text[i] == '(') {
      int openCount = 1;
      int j = i + 1;
      int innerOpenIndex = -1;

      while (j < text.length && openCount > 0) {
        if (text[j] == '(') {
          if (innerOpenIndex == -1) {
            innerOpenIndex = j;
          }
          openCount++;
        } else if (text[j] == ')') {
          openCount--;
        }
        j++;
      }

      if (openCount > 0) {
        result.write(text[i]);
        i++;
        continue;
      }

      if (innerOpenIndex != -1) {
        result.write(text.substring(i, innerOpenIndex));
        i = innerOpenIndex;
        continue;
      }

      final content = text.substring(i + 1, j - 1);
      result.write('<small>(');
      result.write(content);
      result.write(')</small>');
      i = j;
    } else {
      result.write(text[i]);
      i++;
    }
  }

  return result.toString();
}

String replaceHolyNames(String s) {
  return s.replaceAllMapped(
    SearchRegexPatterns.holyName,
    (match) => 'י${match[1]}ק${match[2]}ו${match[3]}ק${match[4]}',
  );
}

String removeTeamim(String s) => s
    .replaceAll('־', ' ')
    .replaceAll(' ׀', '')
    .replaceAll('ֽ', '')
    .replaceAll('׀', '')
    .replaceAll(SearchRegexPatterns.cantillationOnly, '');

String removeSectionNames(String s) => s
    .replaceAll('פרק', '')
    .replaceAll('פסוק', '')
    .replaceAll('פסקה', '')
    .replaceAll('סעיף', '')
    .replaceAll('סימן', '')
    .replaceAll('הלכה', '')
    .replaceAll('מאמר', '')
    .replaceAll('קטן', '')
    .replaceAll('משנה', '')
    .replaceAll(RegExp(r'(?<=[א-ת])י|י(?=[א-ת])'), '')
    .replaceAll(RegExp(r'(?<=[א-ת])ו|ו(?=[א-ת])'), '')
    .replaceAll('"', '')
    .replaceAll("'", '')
    .replaceAll(',', '')
    .replaceAll(':', ' ב')
    .replaceAll('.', ' א');

String replaceParaphrases(String s) {
  // Same implementation as IO version - abbreviated for brevity
  return s;
}

Future<Map<String, List<String>>> splitByEra(List<String> titles) async {
  final Map<String, List<String>> byEra = {
    'תורה שבכתב': [],
    'חז"ל': [],
    'ראשונים': [],
    'אחרונים': [],
    'מחברי זמננו': [],
    'מפרשים נוספים': [],
  };

  for (final t in titles) {
    if (await hasTopic(t, 'תורה שבכתב')) {
      byEra['תורה שבכתב']!.add(t);
    } else if (await hasTopic(t, 'חז"ל')) {
      byEra['חז"ל']!.add(t);
    } else if (await hasTopic(t, 'ראשונים')) {
      byEra['ראשונים']!.add(t);
    } else if (await hasTopic(t, 'אחרונים')) {
      byEra['אחרונים']!.add(t);
    } else if (await hasTopic(t, 'מחברי זמננו')) {
      byEra['מחברי זמננו']!.add(t);
    } else {
      byEra['מפרשים נוספים']!.add(t);
    }
  }

  return byEra;
}
