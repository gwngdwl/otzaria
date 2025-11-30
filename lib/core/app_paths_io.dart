import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'app_paths.dart';

/// Resolves the notes database path for native platforms
Future<String> resolveNotesDbPath(String fileName) async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Windows, Linux, macOS: this will go into application support directory
    final support = await getApplicationSupportDirectory();
    final dbDir = Directory(p.join(support.path, 'databases'));
    if (!await dbDir.exists()) await dbDir.create(recursive: true);
    return p.join(dbDir.path, fileName);
  } else {
    // Mobile: the standard path for sqflite
    final dbs = await getDatabasesPath();
    final dbDir = Directory(dbs);
    if (!await dbDir.exists()) await dbDir.create(recursive: true);
    return p.join(dbs, fileName);
  }
}

/// Creates necessary directories for native platforms
Future<void> createNecessaryDirectories() async {
  final libraryPath = await AppPaths.getLibraryPath();
  final libraryDir = Directory(libraryPath);

  // אם תיקיית הספרייה לא קיימת, לא ניצור אותה
  // רק נוודא שתיקיות האינדקס קיימות אם תיקיית הספרייה קיימת
  if (await libraryDir.exists()) {
    final dirs = [
      await AppPaths.getIndexPath(),
      await AppPaths.getRefIndexPath(),
    ];

    for (final dirPath in dirs) {
      final directory = Directory(dirPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }
  }
}
