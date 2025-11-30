import 'package:flutter/foundation.dart';

// Conditional import for window_manager
import 'window_listener_stub.dart'
    if (dart.library.io) 'window_listener_io.dart'
    if (dart.library.html) 'window_listener_web.dart' as impl;

/// Callback type for fullscreen state changes
typedef FullscreenCallback = void Function(bool isFullscreen);

/// Window listener that handles window events properly to prevent crashes
/// Uses platform-specific implementation
abstract class AppWindowListener {
  FullscreenCallback? onFullscreenChanged;

  factory AppWindowListener() => impl.createWindowListener();

  void dispose();
}
