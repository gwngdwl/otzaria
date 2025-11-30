import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/core/platform/platform.dart' as platform;

// Conditional imports for non-web platforms
import 'app_paths_io.dart' if (dart.library.html) 'app_paths_web.dart'
    as paths_impl;

/// Utility class for managing application paths.
/// Centralizes path construction logic to avoid duplication.
class AppPaths {
  /// Gets the main library path from settings. Defaults based on platform.
  static Future<String> getLibraryPath() async {
    // Check existing library path setting
    final currentPath = Settings.getValue('key-library-path');

    if (currentPath != null) {
      return currentPath;
    }

    // Determine default path based on platform
    String libraryPath = await platform.getDefaultLibraryPath();

    await Settings.setValue('key-library-path', libraryPath);
    return libraryPath;
  }

  /// Gets the search index path (library_path/index)
  static Future<String> getIndexPath() async {
    return p.join(await getLibraryPath(), 'index');
  }

  /// Gets the reference index path (library_path/ref_index)
  static Future<String> getRefIndexPath() async {
    return p.join(await getLibraryPath(), 'ref_index');
  }

  /// Gets the manifest file path (library_path/files_manifest.json)
  static Future<String> getManifestPath() async {
    return p.join(await getLibraryPath(), 'files_manifest.json');
  }

  /// Resolves the notes database path - for cross-platform compatibility
  static Future<String> resolveNotesDbPath(String fileName) async {
    return paths_impl.resolveNotesDbPath(fileName);
  }

  /// Creates necessary directories for the application
  static Future<void> createNecessaryDirectories() async {
    if (kIsWeb) {
      // Web doesn't need directory creation
      return;
    }
    await paths_impl.createNecessaryDirectories();
  }
}
