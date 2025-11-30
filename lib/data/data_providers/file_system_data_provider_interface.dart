import 'package:otzaria/models/books.dart';
import 'package:otzaria/library/models/library.dart';
import 'package:otzaria/models/links.dart';

/// Abstract interface for file system data provider
/// Allows different implementations for native and web platforms
abstract class FileSystemDataInterface {
  Future<Map<String, String>> get titleToPath;
  String get libraryPath;
  Future<Map<String, Map<String, dynamic>>> get metadata;

  Future<Library> getLibrary();
  Future<List<Link>> getAllLinksForBook(String title);
  Future<String> getBookText(String title);
  Future<void> saveBookText(String title, String content);
  Future<String> getLinkContent(Link link);
  Future<List<TocEntry>> getBookToc(String title);
  Future<String> getLineFromFile(String path, int index);
  Future<bool> bookExists(String title);
  Future<bool> isTanachBook(String title);
  Future<int> cleanupAllOldBackups();

  static Future<List<ExternalBook>> getOtzarBooks() async => [];
  static Future<List<Book>> getHebrewBooks() async => [];
}
