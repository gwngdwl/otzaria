import 'dart:io';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/settings/settings_exports.dart';

enum InstallMode { systemWide, perUser }

/// Utility class for managing application paths.
/// Centralizes path construction logic to avoid duplication.
class AppPaths {
  static String? _cachedDataRootPath;
  static String? _cachedTantivyLockPathFor;
  static String? _cachedTantivyLockPathResult;

  @visibleForTesting
  static void debugOverrideDataRootPath(String? path) {
    _cachedDataRootPath = path;
    // הנתיב של ה-Hive box נגזר גם מ-dataRoot, ולכן יש לאפס אותו יחד.
    _cachedTantivyLockPathFor = null;
    _cachedTantivyLockPathResult = null;
  }

  /// מאפס את הקאש של נתיב ה-Hive box של האינדקס.
  /// נדרש אחרי שינוי [SettingsRepository.keyIndexPath] בזמן ריצה
  /// (למשל החלפת מיקום אינדקס מ-Settings UI).
  static void clearTantivyLockPathCache() {
    _cachedTantivyLockPathFor = null;
    _cachedTantivyLockPathResult = null;
  }

  /// Returns the default writable root for user-scoped app data.
  static Future<String> getDataRootPath() async {
    if (_cachedDataRootPath != null && _cachedDataRootPath!.isNotEmpty) {
      return _cachedDataRootPath!;
    }

    final String rootPath;
    if (Platform.isAndroid || Platform.isIOS) {
      rootPath = (await getApplicationDocumentsDirectory()).path;
    } else if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? '';
      rootPath = p.join(appData, 'otzaria');
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '';
      rootPath = p.join(home, 'Library', 'Application Support', 'otzaria');
    } else {
      // Linux
      final home = Platform.environment['HOME'] ?? '';
      rootPath = p.join(home, '.local', 'share', 'otzaria');
    }

    _cachedDataRootPath = rootPath;
    return _cachedDataRootPath!;
  }

  static String? get cachedDataRootPath => _cachedDataRootPath;

  /// Detects whether the app is installed system-wide or per-user.
  static Future<InstallMode> detectInstallMode() async {
    if (Platform.isMacOS) {
      if (await Directory('/Library/Application Support/Otzaria').exists()) {
        return InstallMode.systemWide;
      }
    }
    if (Platform.isWindows) {
      final exeDir = p.dirname(Platform.resolvedExecutable);
      if (File(p.join(exeDir, 'system_install.marker')).existsSync()) {
        return InstallMode.systemWide;
      }
    }
    if (Platform.isLinux) {
      if (await Directory('/var/lib/otzaria').exists()) {
        return InstallMode.systemWide;
      }
    }
    return InstallMode.perUser;
  }

  /// Default library path.
  ///
  /// On system-wide desktop installs this remains in the shared data root.
  /// Otherwise it lives under the user-scoped app data root.
  static Future<String> getDefaultLibraryPath() async {
    final systemWideRoot = await _getSystemWideLibraryRootIfNeeded();
    if (systemWideRoot != null) {
      return p.join(systemWideRoot, 'books');
    }

    return p.join(await getDataRootPath(), 'books');
  }

  static Future<String?> _getSystemWideLibraryRootIfNeeded() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return null;
    }

    final mode = await detectInstallMode();
    if (mode != InstallMode.systemWide) {
      return null;
    }

    if (Platform.isWindows) {
      final pd = Platform.environment['ProgramData'] ?? r'C:\ProgramData';
      return p.join(pd, 'otzaria');
    }
    if (Platform.isMacOS) {
      return '/Library/Application Support/otzaria';
    }
    if (Platform.isLinux) {
      return '/var/lib/otzaria';
    }

    return null;
  }

  static Future<String> _getDefaultIndexPath() async {
    final systemWideRoot = await _getSystemWideLibraryRootIfNeeded();
    if (systemWideRoot != null) {
      return p.join(systemWideRoot, 'index');
    }

    // תאימות אחורה: בעבר האינדקס תמיד נוצר תחת dataRoot (APPDATA וכדומה).
    // אם קיים שם אינדקס – ממשיכים להשתמש בו כדי לא לאבד עבודה.
    final legacyPath = p.join(await getDataRootPath(), 'index');
    if (await Directory(legacyPath).exists()) {
      return legacyPath;
    }

    // ברירת מחדל חדשה: האינדקס יושב ליד תיקיית הספרייה. כך אם המשתמש
    // העביר את הספרייה לכונן אחר (למשל D:), גם האינדקס יישב שם.
    final libraryPath = await getLibraryPath();
    return p.join(p.dirname(libraryPath), 'index');
  }

  /// Gets the main library path from settings, or gracefully falls back to default paths.
  static Future<String> getLibraryPath() async {
    // Check existing library path setting
    final currentPath =
        Settings.getValue<String>(SettingsRepository.keyLibraryPath);

    if (currentPath != null && currentPath.isNotEmpty) {
      return currentPath;
    }

    // Determine default path based on platform
    String libraryPath = await getDefaultLibraryPath();

    await Settings.setValue(SettingsRepository.keyLibraryPath, libraryPath);
    return libraryPath;
  }

  /// Gets the search index path.
  ///
  /// On system-wide desktop installs this remains next to the shared library.
  static Future<String> getIndexPath() async {
    // Check if there is a separate index path assigned
    final savedIndex =
        Settings.getValue<String>(SettingsRepository.keyIndexPath);
    if (savedIndex != null && savedIndex.isNotEmpty) return savedIndex;

    return _getDefaultIndexPath();
  }

  /// מחזיר רשימת נתיבי ברירת מחדל לאינדקס שאינם הנתיב הפעיל כעת.
  ///
  /// משמש בעת איפוס אינדקס: אינדקסים ישנים בנתיבים אלו (למשל אינדקס
  /// ישן שנותר ב-APPDATA אחרי שהמשתמש העביר את הספרייה לכונן אחר)
  /// ימחקו כדי שלא "יתפסו" את ברירת המחדל ב-[getIndexPath] בהפעלה הבאה.
  static Future<List<String>> getStaleDefaultIndexPaths() async {
    final activePath = p.normalize(await getIndexPath());
    final candidates = <String>{};

    final systemWideRoot = await _getSystemWideLibraryRootIfNeeded();
    if (systemWideRoot != null) {
      candidates.add(p.normalize(p.join(systemWideRoot, 'index')));
    }

    // ברירת המחדל הישנה: תחת תיקיית הנתונים (APPDATA וכדומה).
    candidates.add(p.normalize(p.join(await getDataRootPath(), 'index')));

    // ברירת המחדל הנוכחית: ליד הספרייה.
    final libraryPath = await getLibraryPath();
    candidates.add(p.normalize(p.join(p.dirname(libraryPath), 'index')));

    return candidates.where((c) => c != activePath).toList();
  }

  /// Returns the backup path inside the writable app data root.
  static Future<String> getDefaultBackupPath() async {
    return p.join(await getDataRootPath(), 'backups');
  }

  /// Gets backup path from settings.
  static Future<String> getBackupPath() async {
    final saved = Settings.getValue<String>(SettingsRepository.keyBackupPath);
    if (saved != null && saved.isNotEmpty) return saved;
    return getDefaultBackupPath();
  }

  /// Gets the shared directory used for Tantivy state files (Hive box).
  ///
  /// מועדף: ליד תיקיית האינדקס הפעילה. אם המיקום אינו כתיב (למשל התקנת
  /// system-wide תחת `C:\ProgramData\otzaria` ללא הרשאות Modify למשתמש),
  /// נופלים למיקום אישי תחת [getDataRootPath].
  ///
  /// Sticky fallback: אם כבר נכתב `books_indexed.hive` ב-fallback בעבר,
  /// נמשיך להשתמש בו גם אם המיקום המועדף שב להיות כתיב — אחרת היינו
  /// מאבדים את booksDone וגורמים לבנייה מחדש מיותרת של האינדקס.
  ///
  /// קאש: ההחלטה ממוקטמת ע"י [getIndexPath]. בדיקת הכתיבות (write probe)
  /// רצה רק כשנתיב האינדקס משתנה.
  static Future<String> getTantivyLockPath() async {
    final indexPath = await getIndexPath();
    if (_cachedTantivyLockPathFor == indexPath &&
        _cachedTantivyLockPathResult != null) {
      return _cachedTantivyLockPathResult!;
    }

    final preferredDir = Directory(p.join(p.dirname(indexPath), 'tantivy.lock'));
    final fallbackDir =
        Directory(p.join(await getDataRootPath(), 'tantivy_state'));
    final fallbackBox =
        File(p.join(fallbackDir.path, 'books_indexed.hive'));

    String result;
    if (await fallbackBox.exists()) {
      // Sticky: כבר יש מצב נשמר ב-fallback, ממשיכים איתו.
      result = fallbackDir.path;
    } else if (await _ensureWritableDir(preferredDir)) {
      result = preferredDir.path;
    } else {
      await fallbackDir.create(recursive: true);
      await _migrateTantivyStateIfNeeded(preferredDir, fallbackDir);
      result = fallbackDir.path;
    }

    _cachedTantivyLockPathFor = indexPath;
    _cachedTantivyLockPathResult = result;
    return result;
  }

  /// מחזיר true אם [dir] קיימת (יוצרת אם צריך) וכתיבה אליה אפשרית.
  static Future<bool> _ensureWritableDir(Directory dir) async {
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final probe = File(p.join(dir.path,
          '.otzaria_write_probe_${DateTime.now().microsecondsSinceEpoch}'));
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// מעתיק את `books_indexed.hive` מ-[source] אל [target] אם קיים במקור
  /// ואינו קיים ביעד. שומר על booksDone קיים כשעוברים לנתיב fallback.
  static Future<void> _migrateTantivyStateIfNeeded(
      Directory source, Directory target) async {
    try {
      final sourceFile = File(p.join(source.path, 'books_indexed.hive'));
      final targetFile = File(p.join(target.path, 'books_indexed.hive'));
      if (await sourceFile.exists() && !await targetFile.exists()) {
        await sourceFile.copy(targetFile.path);
      }
    } catch (_) {
      // Best-effort: כישלון כאן רק מאפס את booksDone — האינדוקס יתרענן.
    }
  }

  /// Gets the manifest file path (library_path/files_manifest.json)
  static Future<String> getManifestPath() async {
    final libraryPath = await getLibraryPath();
    return p.join(libraryPath, 'files_manifest.json');
  }

  /// Resolves the notes database path - for cross-platform compatibility.
  static Future<String> resolveNotesDbPath(String fileName) async {
    final dbDir = Directory(p.join(await getDataRootPath(), 'databases'));
    if (!await dbDir.exists()) await dbDir.create(recursive: true);
    return p.join(dbDir.path, fileName);
  }

  /// מחזיר את הנתיב של ה-DB של ספרי המשתמש (תיקיות מותאמות אישית).
  ///
  /// מאוחסן באותה תיקייה כמו DBs אחרים של נתוני משתמש, נפרד מ-`seforim.db`
  /// של הספרייה הרשמית. כך שינויים ב-DB הרשמי לא משפיעים על ספרי המשתמש,
  /// ולהפך.
  static Future<String> resolveUserBooksDbPath() async {
    return resolveNotesDbPath('user_books.db');
  }

  /// Creates startup directories when eagerly required.
  static Future<void> createNecessaryDirectories() async {
    // Directories are created lazily by the services that actually use them.
  }

  /// Gets the root path for user overrides.
  static Future<String> getUserOverridesRootPath() async {
    return p.join(await getDataRootPath(), 'user_overrides');
  }

  /// Gets the root path for per-book settings files.
  static Future<String> getPerBookSettingsPath() async {
    return p.join(await getDataRootPath(), 'per_book_settings');
  }

}
