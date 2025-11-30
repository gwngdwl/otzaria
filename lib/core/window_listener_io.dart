import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'window_listener.dart';

AppWindowListener createWindowListener() => AppWindowListenerImpl();

class AppWindowListenerImpl extends WindowListener implements AppWindowListener {
  @override
  FullscreenCallback? onFullscreenChanged;

  @override
  void onWindowEnterFullScreen() {
    if (kDebugMode) {
      print('Window entered fullscreen');
    }
    onFullscreenChanged?.call(true);
  }

  @override
  void onWindowLeaveFullScreen() {
    if (kDebugMode) {
      print('Window left fullscreen');
    }
    onFullscreenChanged?.call(false);
  }

  @override
  void onWindowClose() {
    if (kDebugMode) {
      print('Window close requested');
    }

    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        Future.microtask(() async {
          await windowManager.destroy();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during window close: $e');
      }
      exit(0);
    }
  }

  @override
  void onWindowFocus() {
    if (kDebugMode) {
      print('Window focused');
    }
  }

  @override
  void onWindowBlur() {
    if (kDebugMode) {
      print('Window blurred');
    }
  }

  @override
  void onWindowMinimize() {
    if (kDebugMode) {
      print('Window minimized');
    }
  }

  @override
  void onWindowRestore() {
    if (kDebugMode) {
      print('Window restored');
    }
  }

  @override
  void onWindowResize() {
    if (kDebugMode) {
      print('Window resized');
    }
  }

  @override
  void onWindowMove() {
    if (kDebugMode) {
      print('Window moved');
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
  }
}
