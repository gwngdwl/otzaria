# בנייה בלי תמיכת PDF

בנייה שנועדה לסביבה שאינה מרשה קורא PDF נבנית כך:

```bash
flutter build apk --dart-define=OTZARIA_ENABLE_PDF=false
```

הדגל נקרא ל-`kPdfBooksEnabled` ב-`lib/utils/file/document_format.dart` דרך
`bool.fromEnvironment`, כלומר הוא **קבוע קומפילציה**: אין לו מתג בממשק, אין לו
מפתח בהגדרות ואי אפשר לשנותו בזמן ריצה או בעריכת קבצים על המכשיר.

## מה נחסם

| מסלול | נקודת האכיפה |
|---|---|
| בורר הקבצים בייבוא ספרים אישיים | `kProductionBookFormats` → `kSupportedBookExtensions` |
| סריקת תיקיות מותאמות, תיקיית הספרייה, סנכרון קבצים, generator | `DocumentFormat.isProductionSupported` |
| ש"ס הבבלי המצורף | `isSupportedBookFile` בשני הספקים |
| **הורדת ספר היברובוקס מהשרת** | `HebrewBooksDownloadService.download` + הסתרת כפתור ההורדה |
| ספרי היברובוקס מתיקייה מקומית | `FileSystemData.scanHebrewBooksPdfFilesAtPath` / `probeHebrewBooksPdfFilesByIds` + הסתרת אריח ההגדרה |
| פורמט פתיחת הבבלי | `talmudBavliOpensInPdf` / `resolveTalmudBavliPdfBook` |
| שורת PDF שכבר במסד (מבנייה קודמת) | `_convertMinimalBookMapToBook` (דרך `isProductionSupported`, לא בדיקת `pdf` ייעודית) |
| ספר שנשמר בסימנייה, בהיסטוריה, בסביבת עבודה או בגיבוי | `Book.fromJson` |
| טאב שנשמר לדיסק (כולל חלונית בטאב מפוצל וטאב מפרשים) | `PdfBookTab.fromJson` |
| קישור עומק `otzaria://open/pdf/<id>` | `ExternalUriRouter` |
| קובץ שתוסף מבקש להגיש ל-WebView שלו | `PluginFileServer.register` / `registerWithToken` |
| הורדת קובץ בידי תוסף (`network.download`) | `PluginFileDownloadService` |
| בורר הקבצים של תוסף (`fs.pickUserFile`) | סינון `pdf` מרשימת הסיומות |
| ייצוא PDF בידי תוסף (`ui.exportPdf`) | `PluginBridgeAdapter` |
| רינדור של טאב PDF שנוצר בכל דרך אחרת | `isPaneBlockedByDisabledPdf` |

השער האחרון הוא הרשת: גם טאב PDF שנוצר ממסלול שלא נחסם — למשל אינדקס חיפוש
שנבנה לפני המעבר לבנייה הזו — אינו מרונדר, ובמקומו מוצג "קובצי PDF אינם
נתמכים בגרסה זו".

`OpenedTab.fromBook` אינו המסלול היחיד לטאב PDF: תוצאות חיפוש, איתור מקורות,
סימניות, היסטוריה ושכפול טאב בונים `PdfBookTab` ישירות. ה**רינדור** הוא מה
שחוסם אותם, ולכן `fromBook` **אינו זורק**: קוראיו (`BookOpenCoordinator`,
איתור מקורות, קישור חיצוני) אינם עוטפים אותו ב-`try`, וזריקה שם הפילה את
הפעולה במקום להציג הודעה.

## סמנטיקת החסימה

שער בשכבת המודלים והטאבים זורק `UnsupportedError` עם `kPdfDisabledMessage`;
שער בשכבת התוספים עוטף את אותה הודעה ב-`error.permission_denied:` שגשר ה-RPC
מחלץ ממנו את הקוד. **כל קורא רשימה מדלג על הפריט שנכשל לבדו** — ב-Hive
(`HiveListRepository.load`), בשחזור הגיבוי ובשחזור הטאבים. בלי הדילוג הפרטני
סימנייה אחת של PDF מוחקת מהתצוגה את כל הסימניות, והכתיבה הבאה צורבת את
המחיקה לדיסק.

שערי התוספים בודקים גם את **תוכן** הקובץ (`hasPdfContentSignature`) ולא רק
את הסיומת — אחרת `a.pdf`→`a.bin` היה עוקף אותם. הסריקה היא על כל הכותרת
(`kPdfHeaderScanBytes`) ולא על היסט 0 בלבד, כי הספק אינו מחייב את החתימה
בתחילת הקובץ. בשרת הקבצים הבדיקה חוזרת גם **בזמן ההגשה**: ה-grant מחזיק
נתיב, וקובץ שהוחלף אחרי הרישום היה נקרא מהדיסק מחדש.

בהורדה, גם קובץ **חלקי** ששומרים להמשכה עובר את הבדיקה — אחרת קטיעה מכוונת
של הזרם הייתה משאירה ראש PDF על הדיסק.

**דילוג אינו מחיקה:** `HiveListRepository` מחזיק את השורות שדולגו ומחזיר
אותן לדיסק ב-`save`, והגיבוי קורא אותן גולמיות (`loadRaw`). בלי זה הוספת
סימנייה אחת בבנייה בלי PDF הייתה מוחקת לצמיתות את כל סימניות ה-PDF — גם
לאחר חזרה לבנייה שכן טוענת אותן.

## מה לא משתנה

`pdfrx` נשאר בתלויות והספרייה הנייטיבית של pdfium עדיין נארזת ב-APK — הדגל
מסיר את היכולת, לא את המשקל. ההדפסה של ספרי טקסט עוברת דרך אותו מנוע ריסטור
וממשיכה לעבוד. לחיסכון בגודל ה-APK ראו `--split-per-abi`.

## אימות

`test/utils/file/pdf_disabled_build_test.dart` כותב כל טענה מול
`kPdfBooksEnabled` ולכן עובר בשתי הבניות, ו-`flutter_tests.yml` מריץ אותו
בשתיהן. ידנית:

```bash
flutter test test/utils/file/pdf_disabled_build_test.dart
```

```bash
flutter test --dart-define=OTZARIA_ENABLE_PDF=false test/utils/file/pdf_disabled_build_test.dart
```
