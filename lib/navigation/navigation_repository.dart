import 'package:flutter/foundation.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

// Conditional import for platform-specific implementation
import 'navigation_repository_io.dart'
    if (dart.library.html) 'navigation_repository_web.dart' as impl;

class NavigationRepository {
  bool checkLibraryIsEmpty() {
    if (kIsWeb) {
      // On web, we'll check differently (e.g., IndexedDB)
      return impl.checkLibraryIsEmpty();
    }

    final libraryPath = Settings.getValue<String>('key-library-path');
    if (libraryPath == null) {
      return true;
    }

    return impl.checkLibraryIsEmptyNative(libraryPath);
  }

  Future<void> refreshLibrary() async {
    // This will be implemented when we migrate the library bloc
    // For now, it's a placeholder for the refresh functionality
  }
}
