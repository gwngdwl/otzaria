/// Text manipulation utilities with platform-specific implementations
export 'text_manipulation_io.dart'
    if (dart.library.html) 'text_manipulation_web.dart';
