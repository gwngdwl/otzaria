import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:path_provider/path_provider.dart';

/// A cache access provider class for shared preferences using Hive library
class HiveCache extends CacheProvider {
  Box? _preferences;
  final String keyName = 'app_preferences';
  
  // In-memory fallback for web
  final Map<String, dynamic> _webCache = {};

  @override
  Future<void> init() async {
    if (kIsWeb) {
      // On web, use in-memory cache as fallback
      // Hive web support requires additional setup
      debugPrint('HiveCache: Using in-memory cache for web');
    } else {
      final defaultDirectory = await getApplicationSupportDirectory();
      _preferences = Hive.box(name: keyName, directory: defaultDirectory.path);
    }
  }
  
  dynamic _getValue(String key) {
    if (kIsWeb) {
      return _webCache[key];
    }
    return _preferences?.get(key);
  }
  
  void _setValue(String key, dynamic value) {
    if (kIsWeb) {
      _webCache[key] = value;
    } else {
      _preferences?.put(key, value);
    }
  }

  Set get keys => getKeys();

  @override
  bool? getBool(String key, {bool? defaultValue}) {
    return _getValue(key) ?? defaultValue;
  }

  @override
  double? getDouble(String key, {double? defaultValue}) {
    return _getValue(key) ?? defaultValue;
  }

  @override
  int? getInt(String key, {int? defaultValue}) {
    return _getValue(key) ?? defaultValue;
  }

  @override
  String? getString(String key, {String? defaultValue}) {
    return _getValue(key) ?? defaultValue;
  }

  @override
  Future<void> setBool(String key, bool? value) async {
    _setValue(key, value);
  }

  @override
  Future setDouble(String key, double? value) async {
    _setValue(key, value);
  }

  @override
  Future<void> setInt(String key, int? value) async {
    _setValue(key, value);
  }

  @override
  Future<void> setString(String key, String? value) async {
    _setValue(key, value);
  }

  @override
  Future<void> setObject<T>(String key, T? value) async {
    _setValue(key, value);
  }

  @override
  bool containsKey(String key) {
    if (kIsWeb) {
      return _webCache.containsKey(key);
    }
    return _preferences?.containsKey(key) ?? false;
  }

  @override
  Set getKeys() {
    if (kIsWeb) {
      return _webCache.keys.toSet();
    }
    return _preferences?.keys.toSet() ?? {};
  }

  @override
  Future<void> remove(String key) async {
    if (kIsWeb) {
      _webCache.remove(key);
    } else if (containsKey(key)) {
      _preferences?.delete(key);
    }
  }

  @override
  Future<void> removeAll() async {
    if (kIsWeb) {
      _webCache.clear();
    } else {
      final keys = getKeys();
      _preferences?.deleteAll(keys.where((element) => true) as Iterable<String>);
    }
  }

  @override
  T? getValue<T>(String key, {T? defaultValue}) {
    var value = _getValue(key);
    if (value is T) {
      return value;
    }
    return defaultValue;
  }
}
