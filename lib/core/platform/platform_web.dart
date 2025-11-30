/// Platform implementation for web
import 'package:flutter/foundation.dart';

bool get isDesktop => false;
bool get isMobile => false;
bool get isWeb => true;

Future<void> initializePlatform() async {
  // Web doesn't need special initialization
  debugPrint('Running on web platform');
}

Future<String> getDefaultLibraryPath() async {
  // Web uses IndexedDB or localStorage, no file system path
  return '/otzaria';
}
