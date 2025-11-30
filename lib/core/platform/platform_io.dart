/// Platform implementation for native platforms (iOS, Android, Windows, Linux, macOS)
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

bool get isDesktop =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;
bool get isMobile => Platform.isAndroid || Platform.isIOS;
bool get isWeb => false;

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

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}

Future<String> getDefaultLibraryPath() async {
  if (Platform.isIOS) {
    return (await getApplicationDocumentsDirectory()).path;
  } else if (Platform.isAndroid) {
    try {
      return (await getExternalStorageDirectory())?.path ??
          (await getApplicationDocumentsDirectory()).path;
    } catch (_) {
      return (await getApplicationDocumentsDirectory()).path;
    }
  } else if (Platform.isWindows) {
    return 'C:/אוצריא';
  } else {
    // Linux, macOS
    return (await getApplicationSupportDirectory()).path;
  }
}
