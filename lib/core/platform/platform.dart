/// Platform abstraction layer
/// Uses conditional imports to provide platform-specific implementations
export 'platform_stub.dart'
    if (dart.library.io) 'platform_io.dart'
    if (dart.library.html) 'platform_web.dart';
