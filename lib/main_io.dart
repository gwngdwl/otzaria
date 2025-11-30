/// Platform-specific initialization for native platforms (iOS, Android, Windows, Linux, macOS)
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:window_manager/window_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:search_engine/search_engine.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:hive/hive.dart';
import 'package:otzaria/settings/backup_service.dart';
import 'package:otzaria/services/notification_service.dart';
import 'package:otzaria/core/window_listener.dart';

// Global reference to window listener
AppWindowListener? _appWindowListener;

/// Log error to file
void logError(String error) {
  File('errors.txt').writeAsStringSync(error, mode: FileMode.append);
}

/// Check if this is the first instance of the app
Future<bool> checkSingleInstance() async {
  FlutterSingleInstance flutterSingleInstance = FlutterSingleInstance();
  bool isFirstInstance = await flutterSingleInstance.isFirstInstance();
  if (!isFirstInstance) {
    exit(0);
  }
  return false;
}

/// Initialize platform-specific features
Future<void> initializePlatform() async {
  // Initialize SQLite FFI for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    // Add window listener for proper close handling
    _appWindowListener = AppWindowListener();
    windowManager.addListener(_appWindowListener as WindowListener);

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize Rust library for search
  await RustLib.init();
}

/// Initialize Hive storage
Future<void> initHive() async {
  Hive.defaultDirectory = (await getApplicationSupportDirectory()).path;
}

/// Load SSL certificates
Future<void> loadCerts() async {
  final certs = ['assets/ca/netfree_cas.pem'];
  for (var cert in certs) {
    final certBytes = await rootBundle.load(cert);
    SecurityContext.defaultContext
        .setTrustedCertificatesBytes(certBytes.buffer.asUint8List());
  }
}

/// Initialize PDF cache directory
Future<void> initPdfCache() async {
  try {
    final cacheDir = await getTemporaryDirectory();
    Pdfrx.getCacheDirectory = () => cacheDir.path;
    debugPrint('Pdfrx cache directory set to: ${cacheDir.path}');
  } catch (e) {
    debugPrint('Failed to set Pdfrx cache directory: $e');
  }
}

/// Perform automatic backup if needed
Future<void> performAutoBackupIfNeeded() async {
  try {
    if (await BackupService.shouldPerformAutoBackup()) {
      await BackupService.performAutoBackup();
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Failed to perform automatic backup: $e');
    }
  }
}

/// Initialize notification service
Future<void> initNotifications() async {
  try {
    await NotificationService().init();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Failed to initialize notification service: $e');
    }
  }
}
