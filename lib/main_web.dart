/// Platform-specific initialization for web
import 'package:flutter/foundation.dart';

/// Log error (web version - just prints to console)
void logError(String error) {
  debugPrint('Error: $error');
}

/// Check if this is the first instance (always false on web)
Future<bool> checkSingleInstance() async {
  return false;
}

/// Initialize platform-specific features for web
Future<void> initializePlatform() async {
  debugPrint('Initializing web platform');
}

/// Initialize Hive storage for web
Future<void> initHive() async {
  // Hive on web uses IndexedDB automatically
  // We need to initialize it differently - Hive.init() is not needed on web
  debugPrint('Hive initialized for web (using IndexedDB)');
}

/// Load SSL certificates (no-op on web)
Future<void> loadCerts() async {
  // Web handles SSL through the browser
}

/// Initialize PDF cache directory (no-op on web)
Future<void> initPdfCache() async {
  // Web handles caching differently
}

/// Perform automatic backup if needed (no-op on web)
Future<void> performAutoBackupIfNeeded() async {
  // Backup not supported on web
}

/// Initialize notification service (no-op on web)
Future<void> initNotifications() async {
  // Web notifications would need different implementation
}
