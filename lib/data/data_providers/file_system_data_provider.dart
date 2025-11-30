/// File system data provider with platform-specific implementations
/// Uses conditional imports to provide native or web implementation
export 'file_system_data_provider_io.dart'
    if (dart.library.html) 'file_system_data_provider_web.dart';
