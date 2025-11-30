import 'window_listener.dart';

AppWindowListener createWindowListener() => AppWindowListenerWeb();

/// Web implementation of window listener (no-op)
class AppWindowListenerWeb implements AppWindowListener {
  @override
  FullscreenCallback? onFullscreenChanged;

  @override
  void dispose() {
    // No-op on web
  }
}
