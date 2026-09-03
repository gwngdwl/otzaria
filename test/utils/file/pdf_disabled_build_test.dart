import 'dart:io';

import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria/core/external_uri_router.dart';
import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/library/services/hebrew_books_download_service.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/plugins/services/plugin_file_download_service.dart';
import 'package:otzaria/plugins/services/plugin_file_server.dart';
import 'package:otzaria/settings/engine/settings_repository.dart';
import 'package:otzaria/settings/search/settings_search_index.g.dart';
import 'package:otzaria/tabs/models/pdf_commentators_tab.dart';
import 'package:otzaria/tabs/models/pdf_tab.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/tabs/reading_screen.dart';
import 'package:otzaria/utils/file/document_converter.dart';
import 'package:otzaria/utils/file/document_format.dart';
import 'package:otzaria/utils/navigation/talmud_bavli_open_format.dart';

import '../../helpers/memory_settings_cache.dart';

/// חסימת ה-PDF נצרבת בקומפילציה (`--dart-define=OTZARIA_ENABLE_PDF=false`),
/// ולכן בדיקה אינה יכולה להחליף את הערך. כל טענה כאן נכתבת מול
/// [kPdfBooksEnabled] ולכן עוברת בשתי הבניות — וקושרת את כל השערים לאותו
/// קבוע יחיד, כך שנתק של אחד מהם נכשל.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('שער הפורמטים', () {
    test('pdf נמצא ב-kProductionBookFormats רק כשהבנייה תומכת בו', () {
      expect(
        kProductionBookFormats.contains(DocumentFormat.pdf),
        kPdfBooksEnabled,
      );
      expect(DocumentFormat.pdf.isProductionSupported, kPdfBooksEnabled);
    });

    test('רשימות הסיומות נגזרות מהשער — כולל זו של בורר הקבצים', () {
      expect(kSupportedBookExtensions.contains('pdf'), kPdfBooksEnabled);
      expect(kSupportedDottedBookExtensions.contains('.pdf'), kPdfBooksEnabled);
    });

    test('isSupportedBookFile — השער שכל הסורקים שואלים', () {
      expect(isSupportedBookFile('/lib/a.pdf'), kPdfBooksEnabled);
      expect(isSupportedBookFile('/lib/A.PDF'), kPdfBooksEnabled);
      // פורמט טקסטואלי אינו מושפע מהחסימה.
      expect(isSupportedBookFile('/lib/a.txt'), isTrue);
    });

    test('isSupportedPdfFile — השער של סורק שבונה PdfBook ישירות', () {
      expect(isSupportedPdfFile('/lib/a.pdf'), kPdfBooksEnabled);
      expect(isSupportedPdfFile('/lib/A.PDF'), kPdfBooksEnabled);
      // הסורקים האלה בונים PdfBook ללא תנאי, ולכן קובץ טקסט חייב ליפול
      // כאן **גם** בבנייה שתומכת ב-PDF.
      expect(isSupportedPdfFile('/lib/a.txt'), isFalse);
      expect(isSupportedPdfFile('/lib/a.docx'), isFalse);
    });

    test('hasPdfContentSignature — זיהוי לפי תוכן, לא לפי סיומת', () async {
      final dir = await Directory.systemTemp.createTemp('pdf_sig_');
      addTearDown(() => dir.delete(recursive: true));
      String at(String name) => '${dir.path}${Platform.pathSeparator}$name';

      await File(at('renamed.bin')).writeAsString('%PDF-1.7 header');
      await File(at('plain.txt')).writeAsString('שלום');
      // הספק אינו מחייב את החתימה בהיסט 0, וקוראי PDF מקבלים אותה בכל
      // מקום בכותרת — חיפוש בהיסט 0 בלבד היה נותן כאן מסלול עוקף.
      await File(at('offset.bin')).writeAsString('\n\n\n%PDF-1.7 header');
      await File(at('late.bin')).writeAsString('${'x' * 4000}%PDF-1.7');

      expect(await hasPdfContentSignature(at('renamed.bin')), isTrue);
      expect(await hasPdfContentSignature(at('offset.bin')), isTrue);
      expect(await hasPdfContentSignature(at('plain.txt')), isFalse);
      expect(await hasPdfContentSignature(at('missing.pdf')), isFalse);
      // מעבר לכותרת אין סריקה — קובץ שמזכיר %PDF באמצעו אינו PDF.
      expect(await hasPdfContentSignature(at('late.bin')), isFalse);
    });
  });

  group('שחזור מהדיסק', () {
    Map<String, dynamic> pdfBookJson() => {
      'type': 'PdfBook',
      'title': 'ספר',
      'path': '/lib/a.pdf',
    };

    test('ספר PDF מסודרר (סימנייה/היסטוריה/גיבוי) נדחה בבנייה בלי PDF', () {
      if (kPdfBooksEnabled) {
        expect(Book.fromJson(pdfBookJson()), isA<PdfBook>());
      } else {
        expect(() => Book.fromJson(pdfBookJson()), throwsUnsupportedError);
      }
    });

    test('טאב PDF שנשמר לדיסק נדחה בבנייה בלי PDF', () {
      // בבנייה עם PDF השחזור עצמו דורש `Settings.init` ואינו נבדק כאן.
      if (kPdfBooksEnabled) return;

      expect(
        () => OpenedTab.fromJson({
          'type': 'PdfBookTab',
          'path': '/lib/a.pdf',
          'pageNumber': 3,
        }),
        throwsUnsupportedError,
      );
    });

    test('טאב מפרשים של PDF שנשמר לדיסק נדחה בבנייה בלי PDF', () {
      if (kPdfBooksEnabled) return;
      // אותו שער יחיד ב-`PdfBookTab.fromJson`, שגם `PdfCommentatorsTab`
      // וגם חלונית בטאב מפוצל נכנסות דרכו.
      expect(
        () => PdfCommentatorsTab.fromJson({
          'type': 'PdfCommentatorsTab',
          'sourceTab': {'type': 'PdfBookTab', 'path': '/lib/a.pdf'},
        }),
        throwsUnsupportedError,
      );
    });

    test('חלונית PDF בטאב מפוצל שמור מדולגת, והאחות שורדת', () {
      if (kPdfBooksEnabled) return;
      final restored = OpenedTab.fromJson({
        'type': 'CombinedTab',
        'rightTab': {'type': 'PdfBookTab', 'path': '/lib/a.pdf'},
        'leftTab': {'type': 'SearchingTab', 'title': 'חיפוש'},
      });

      expect(restored, isA<SearchingTab>());
    });
  });

  group('שער הרינדור', () {
    // בניית טאב קוראת העדפות קריאה שמורות.
    setUp(() async {
      await Settings.init(cacheProvider: MemorySettingsCache());
    });

    test('fromBook אינו זורק — הרינדור הוא שחוסם', () {
      // זריקה מ-`fromBook` נחתה בקוראים שאין להם מטפל (איתור מקורות,
      // קישור חיצוני) והפילה את הפעולה במקום להציג הודעה.
      final tab = OpenedTab.fromBook(
        PdfBook(title: 'ספר', path: '/lib/a.pdf'),
        1,
      );

      expect(tab, isA<PdfBookTab>());
      expect(isPaneBlockedByDisabledPdf(tab), !kPdfBooksEnabled);
    });

    test('טאב שאינו PDF אינו נחסם לעולם', () {
      final tab = OpenedTab.fromBook(TextBook(title: 'ספר'), 1);

      expect(isPaneBlockedByDisabledPdf(tab), isFalse);
    });
  });

  group('הגדרות', () {
    setUp(() async {
      await Settings.init(cacheProvider: MemorySettingsCache());
    });

    test('הגדרת פתיחת הבבלי ב-PDF אינה חלה בבנייה בלי PDF', () async {
      // ההגדרה נשמרת מבנייה קודמת או משוחזרת מגיבוי, ולכן הערך על הדיסק
      // אינו קובע לבדו.
      await Settings.setValue<String>(
        SettingsRepository.keyTalmudBavliOpenFormat,
        'pdf',
      );

      expect(talmudBavliOpensInPdf(), kPdfBooksEnabled);
    });

    test('החיפוש בהגדרות אינו מציע כרטיס PDF שאינו נבנה', () {
      bool hasCard(String cardId) =>
          kGeneratedSettingsSearchEntries.any((e) => e.cardId == cardId);

      expect(hasCard('design.pdf'), kPdfBooksEnabled);
      expect(
        kGeneratedSettingsSearchEntries.any(
          (e) => e.id == 'library.location.hebrewbooks',
        ),
        kPdfBooksEnabled,
      );
      // כרטיס שאינו תלוי ב-PDF נשאר באינדקס בשתי הבניות.
      expect(hasCard('design.theme'), isTrue);
    });
  });

  group('קישור עומק', () {
    test('otzaria://open/pdf/<id> אינו מיוצר בבנייה בלי PDF', () {
      final action = ExternalUriRouter.parseUri(
        Uri.parse('otzaria://open/pdf/12'),
      );

      if (kPdfBooksEnabled) {
        expect(action, isA<OpenPdfBookAction>());
        expect((action as OpenPdfBookAction).bookId, 12);
      } else {
        expect(action, isNull);
      }
    });
  });

  group('ספרי היברובוקס', () {
    test('הורדת ספר מהשרת נדחית בבנייה בלי PDF', () async {
      if (kPdfBooksEnabled) return;
      // המסלול הרחב מכולם: מביא PDF מהרשת אל תוך הספרייה.
      final service = HebrewBooksDownloadService();
      addTearDown(service.dispose);

      await expectLater(service.download(1234), throwsUnsupportedError);
    });

    test('סריקת תיקיית היברובוקס מחזירה ריק בבנייה בלי PDF', () async {
      final dir = await Directory.systemTemp.createTemp('hb_scan_');
      addTearDown(() => dir.delete(recursive: true));
      await File('${dir.path}${Platform.pathSeparator}1234.pdf').writeAsString(
        '%PDF-1.4',
      );

      final found = await FileSystemData.scanHebrewBooksPdfFilesAtPath(
        dir.path,
      );

      expect(found.isEmpty, !kPdfBooksEnabled);
    });
  });

  group('תוספים', () {
    test('הגשת PDF ל-WebView של תוסף נדחית בבנייה בלי PDF', () async {
      if (kPdfBooksEnabled) return;
      // נקודת האכיפה היחידה שדרכה קובץ מגיע ל-WebView של תוסף.
      await expectLater(
        PluginFileServer.instance.register(
          pluginId: 'p1',
          canonicalPath: '/tmp/a.pdf',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('הורדת PDF בידי תוסף נדחית בבנייה בלי PDF', () async {
      if (kPdfBooksEnabled) return;
      final service = PluginFileDownloadService();
      addTearDown(service.dispose);

      await expectLater(
        service.downloadToPath(
          Uri.parse('https://example.org/a.pdf'),
          '/tmp/a.pdf',
          isAllowed: (_) async => true,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('error.permission_denied'),
          ),
        ),
      );
    });
  });
}
