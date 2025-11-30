/// Web implementation of platform-specific functions
/// These are no-ops on web since window_manager is not available

bool get isDesktopPlatform => false;

void setupFullscreenCallback(void Function(bool) callback) {
  // No-op on web
}

Future<bool> isWindowFullScreen() async {
  return false;
}

Future<void> setWindowFullScreen(bool fullscreen) async {
  // No-op on web
}
