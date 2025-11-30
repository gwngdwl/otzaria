import 'package:hive/hive.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/tabs/bloc/tabs_state.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class TabsRepository {
  static const String _tabsBoxKey = 'key-tabs';
  static const String _currentTabKey = 'key-current-tab';
  static const String _sideBySideModeKey = 'key-side-by-side-mode';
  
  // In-memory storage for web
  static final Map<String, dynamic> _webStorage = {};
  static bool _initialized = false;
  static String? _directory;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    if (!kIsWeb) {
      final dir = await getApplicationSupportDirectory();
      _directory = dir.path;
    }
    _initialized = true;
  }

  Box? _getBox() {
    if (kIsWeb) return null;
    if (_directory == null) return null;
    return Hive.box(name: 'tabs', directory: _directory);
  }

  List<OpenedTab> loadTabs() {
    try {
      if (kIsWeb) {
        final rawTabs = _webStorage[_tabsBoxKey] as List? ?? [];
        return List<OpenedTab>.from(
          rawTabs.map((e) => OpenedTab.fromJson(e)).toList(),
        );
      }
      
      final box = _getBox();
      if (box == null) return [];
      final rawTabs = box.get(_tabsBoxKey, defaultValue: []) as List;
      return List<OpenedTab>.from(
        rawTabs.map((e) => OpenedTab.fromJson(e)).toList(),
      );
    } catch (e) {
      debugPrint('Error loading tabs from disk: $e');
      return [];
    }
  }

  int loadCurrentTabIndex() {
    if (kIsWeb) {
      return _webStorage[_currentTabKey] as int? ?? 0;
    }
    final box = _getBox();
    if (box == null) return 0;
    return box.get(_currentTabKey, defaultValue: 0);
  }

  SideBySideMode? loadSideBySideMode() {
    try {
      if (kIsWeb) {
        final rawMode = _webStorage[_sideBySideModeKey];
        if (rawMode == null) return null;
        return SideBySideMode.fromJson(Map<String, dynamic>.from(rawMode));
      }
      
      final box = _getBox();
      if (box == null) return null;
      final rawMode = box.get(_sideBySideModeKey);
      if (rawMode == null) return null;
      return SideBySideMode.fromJson(Map<String, dynamic>.from(rawMode));
    } catch (e) {
      debugPrint('Error loading side-by-side mode from disk: $e');
      return null;
    }
  }

  void saveTabs(List<OpenedTab> tabs, int currentTabIndex,
      [SideBySideMode? sideBySideMode]) {
    if (kIsWeb) {
      _webStorage[_tabsBoxKey] = tabs.map((tab) => tab.toJson()).toList();
      _webStorage[_currentTabKey] = currentTabIndex;
      if (sideBySideMode != null) {
        _webStorage[_sideBySideModeKey] = sideBySideMode.toJson();
      } else {
        _webStorage.remove(_sideBySideModeKey);
      }
      return;
    }
    
    final box = _getBox();
    if (box == null) return;
    box.put(_tabsBoxKey, tabs.map((tab) => tab.toJson()).toList());
    box.put(_currentTabKey, currentTabIndex);
    if (sideBySideMode != null) {
      box.put(_sideBySideModeKey, sideBySideMode.toJson());
    } else {
      box.delete(_sideBySideModeKey);
    }
  }
  
  /// Initialize the repository (call this before using)
  static Future<void> initialize() async {
    await _ensureInitialized();
  }
}
