import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:otzaria/models/books.dart';
import 'package:otzaria/library/models/library.dart';
import 'package:otzaria/models/links.dart';
import 'package:otzaria/core/scaffold_messenger.dart';

/// Web implementation of FileSystemData
/// On web, we load library structure from bundled assets
/// Book content is not available on web (would require API server)
class FileSystemData {
  late Future<Map<String, String>> titleToPath;
  late String libraryPath;
  late Future<Map<String, Map<String, dynamic>>> metadata;

  // Cache for loaded library
  Library? _cachedLibrary;
  bool _libraryLoaded = false;

  FileSystemData() {
    libraryPath = '/otzaria';
    titleToPath = Future.value({});
    metadata = _loadMetadata();
  }

  static FileSystemData instance = FileSystemData();

  /// Load metadata from assets
  Future<Map<String, Map<String, dynamic>>> _loadMetadata() async {
    try {
      final jsonString = await rootBundle.loadString('assets/metadata.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      final Map<String, Map<String, dynamic>> result = {};
      for (var item in jsonList) {
        if (item is Map<String, dynamic> && item['title'] != null) {
          result[item['title']] = item;
        }
      }
      debugPrint('Web: Loaded ${result.length} metadata entries');
      return result;
    } catch (e) {
      debugPrint('Web: Failed to load metadata: $e');
      return {};
    }
  }

  Future<Library> getLibrary() async {
    if (_libraryLoaded && _cachedLibrary != null) {
      return _cachedLibrary!;
    }

    debugPrint('Web: Loading library from assets...');
    
    try {
      final categories = <Category>[];
      
      // Load Tanach
      final tanachCategory = await _loadCategoryFromAsset(
        'assets/shamor_zachor/data/tanach.json',
        null,
      );
      if (tanachCategory != null) {
        categories.add(tanachCategory);
      }

      // Load Mishna
      final mishnaCategory = await _loadCategoryFromAsset(
        'assets/shamor_zachor/data/mishna.json',
        null,
      );
      if (mishnaCategory != null) {
        categories.add(mishnaCategory);
      }

      // Load Shas (Talmud Bavli)
      final shasCategory = await _loadCategoryFromAsset(
        'assets/shamor_zachor/data/shas.json',
        null,
      );
      if (shasCategory != null) {
        categories.add(shasCategory);
      }

      // Load Yerushalmi
      final yerushalmiCategory = await _loadCategoryFromAsset(
        'assets/shamor_zachor/data/yerushalmi.json',
        null,
      );
      if (yerushalmiCategory != null) {
        categories.add(yerushalmiCategory);
      }

      // Load Rambam
      final rambamCategory = await _loadCategoryFromAsset(
        'assets/shamor_zachor/data/rambam.json',
        null,
      );
      if (rambamCategory != null) {
        categories.add(rambamCategory);
      }

      // Load Halakha
      final halakhaCategory = await _loadCategoryFromAsset(
        'assets/shamor_zachor/data/halakha.json',
        null,
      );
      if (halakhaCategory != null) {
        categories.add(halakhaCategory);
      }

      _cachedLibrary = Library(categories: categories);
      _libraryLoaded = true;
      
      debugPrint('Web: Library loaded with ${categories.length} categories');
      return _cachedLibrary!;
    } catch (e) {
      debugPrint('Web: Error loading library: $e');
      UiSnack.showError('שגיאה בטעינת הספרייה: ${e.toString()}');
      return Library(categories: []);
    }
  }

  /// Load a category from a JSON asset file
  Future<Category?> _loadCategoryFromAsset(String assetPath, Category? parent) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      return _parseCategoryJson(jsonData, parent);
    } catch (e) {
      debugPrint('Web: Failed to load category from $assetPath: $e');
      UiSnack.showError('שגיאה בטעינת קטגוריה: ${e.toString()}');
      return null;
    }
  }

  /// Parse category JSON into Category object
  Category _parseCategoryJson(Map<String, dynamic> jsonData, Category? parent) {
    final name = jsonData['name'] as String? ?? 'Unknown';
    final subcategories = <Category>[];
    final books = <Book>[];

    // Create the category first (without subcategories)
    final category = Category(
      title: name,
      description: '',
      shortDescription: '',
      order: 0,
      subCategories: subcategories,
      books: books,
      parent: parent,
    );

    // Parse subcategories
    if (jsonData['subcategories'] != null) {
      for (var subJson in jsonData['subcategories']) {
        final subCategory = _parseCategoryJson(subJson, category);
        subcategories.add(subCategory);
      }
    }

    // Parse books
    if (jsonData['books'] != null) {
      final booksMap = jsonData['books'] as Map<String, dynamic>;
      for (var entry in booksMap.entries) {
        final bookTitle = entry.key;
        books.add(TextBook(
          title: bookTitle,
          category: category,
        ));
      }
    }

    return category;
  }

  static Future<List<ExternalBook>> getOtzarBooks() async {
    debugPrint('Web: getOtzarBooks called');
    // Could load from assets/otzar_books.csv in the future
    return [];
  }

  static Future<List<Book>> getHebrewBooks() async {
    debugPrint('Web: getHebrewBooks called');
    // Could load from assets/hebrew_books.csv in the future
    return [];
  }

  Future<List<Link>> getAllLinksForBook(String title) async {
    debugPrint('Web: getAllLinksForBook called for $title');
    return [];
  }

  Future<String> getBookText(String title) async {
    debugPrint('Web: getBookText called for $title');
    return '''
<h1>$title</h1>
<p>תוכן הספר לא זמין בגרסת הווב.</p>
<p>כדי לקרוא את תוכן הספרים, יש להשתמש באפליקציה המותקנת על המחשב.</p>
''';
  }

  Future<void> saveBookText(String title, String content) async {
    debugPrint('Web: saveBookText called for $title');
    throw UnsupportedError('Saving books is not supported on web');
  }

  Future<String> getLinkContent(Link link) async {
    debugPrint('Web: getLinkContent called');
    return 'תוכן הקישור לא זמין בגרסת הווב';
  }

  Future<List<TocEntry>> getBookToc(String title) async {
    debugPrint('Web: getBookToc called for $title');
    return [];
  }

  Future<String> getLineFromFile(String path, int index) async {
    debugPrint('Web: getLineFromFile called');
    return '';
  }

  Future<bool> bookExists(String title) async {
    return false;
  }

  Future<bool> isTanachBook(String title) async {
    // Check if the book is in Tanach category
    final library = await getLibrary();
    for (var category in library.subCategories) {
      if (category.title == 'תנ"ך') {
        final allBooks = category.getAllBooks();
        return allBooks.any((book) => book.title == title);
      }
    }
    return false;
  }

  Future<int> cleanupAllOldBackups() async {
    return 0;
  }
}
