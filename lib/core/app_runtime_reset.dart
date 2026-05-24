import 'package:otzaria/core/app_paths.dart';
import 'package:otzaria/data/cache/acronyms_cache.dart';
import 'package:otzaria/data/cache/books_cache.dart';
import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/data/data_providers/library_provider_manager.dart';
import 'package:otzaria/data/data_providers/sqlite_data_provider.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/find_ref/repository/reference_books_cache.dart';

/// מאפס מצב runtime מקומי כדי שהאפליקציה תוכל להיבנות מחדש בלי סגירת תהליך.
Future<void> resetRuntimeStateForAppRestart() async {
  await SqliteDataProvider.instance.dispose();

  final libraryPath = await AppPaths.getLibraryPath();
  FileSystemData.instance.libraryPath = libraryPath;
  FileSystemData.instance.clearBookCache();

  LibraryProviderManager.instance.resetRuntimeState();
  DataRepository.instance.invalidateExternalBooksCache();

  ReferenceBooksCache.instance.clear();
  BooksCache.instance.clear();
  AcronymsCache.instance.clear();
}

/// תאימות לשם הישן במסלול איפוס הגדרות.
Future<void> resetRuntimeStateAfterSettingsReset() async {
  await resetRuntimeStateForAppRestart();
}
