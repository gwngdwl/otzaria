import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:otzaria/main.dart' show appWindowListener;

bool get isDesktopPlatform =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

void setupFullscreenCallback(void Function(bool) callback) {
  if (isDesktopPlatform) {
    appWindowListener?.onFullscreenChanged = callback;
  }
}

Future<bool> isWindowFullScreen() async {
  if (isDesktopPlatform) {
    return await windowManager.isFullScreen();
  }
  return false;
}

Future<void> setWindowFullScreen(bool fullscreen) async {
  if (isDesktopPlatform) {
    await windowManager.setFullScreen(fullscreen);
  }
}
