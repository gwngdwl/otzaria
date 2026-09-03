import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:otzaria/utils/file/hive_utils.dart';

/// Generic repository for managing lists of objects in Hive.
/// T must have `fromJson(Map<String, dynamic>)` and `toJson()` methods.
class HiveListRepository<T> {
  final String boxName;
  final String key;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;

  HiveListRepository({
    required this.boxName,
    required this.key,
    required this.fromJson,
    required this.toJson,
  });

  Box<dynamic> get _box => Hive.box(boxName);

  /// השורות הגולמיות שהפענוח דילג עליהן בקריאה האחרונה של [load].
  ///
  /// דילוג אינו מחיקה: [save] מחזיר אותן לדיסק. בלעדיהן סימנייה שאינה
  /// נטענת בבנייה הזו (למשל ספר PDF בבנייה בלי PDF) הייתה נמחקת לצמיתות
  /// בכתיבה הבאה — גם אחרי חזרה לבנייה שכן טוענת אותה.
  List<dynamic> _skippedRaw = const [];

  /// השורות הגולמיות כפי שהן בדיסק, בלי פענוח. לשימוש גיבוי, שחייב לכלול
  /// גם פריט שהבנייה הזו אינה יודעת לפענח.
  Future<List<dynamic>> loadRaw() async {
    try {
      return List<dynamic>.from(_box.get(key, defaultValue: []) as List);
    } catch (e) {
      debugPrint('⚠️ HiveListRepository.loadRaw($boxName/$key) failed: $e');
      return [];
    }
  }

  /// Load the list from Hive
  ///
  /// פריט שנכשל מדולג לבדו. בלי הדילוג הפרטני סימנייה אחת שאינה נטענת
  /// מוחקת מהתצוגה את כל הרשימה. הפריט עצמו נשמר ב-[_skippedRaw] וחוזר
  /// לדיסק ב-[save].
  Future<List<T>> load() async {
    try {
      final List<dynamic> raw =
          _box.get(key, defaultValue: []) as List<dynamic>;
      final items = <T>[];
      final skipped = <dynamic>[];
      for (final e in raw) {
        try {
          items.add(fromJson(castMap(e)));
        } catch (itemError) {
          skipped.add(e);
          debugPrint(
            '⚠️ HiveListRepository.load($boxName/$key) skipping item: $itemError',
          );
        }
      }
      _skippedRaw = skipped;
      return items;
    } catch (e) {
      debugPrint('⚠️ HiveListRepository.load($boxName/$key) failed: $e');
      // Do NOT overwrite persisted data — return empty so the UI is functional
      // but the raw data on disk stays intact for the next attempt / fix.
      _skippedRaw = const [];
      return [];
    }
  }

  /// Save the list to Hive
  ///
  /// הפריטים שדולגו ב-[load] האחרון מצורפים בחזרה, כדי שכתיבה רגילה לא
  /// תמחק נתונים שהבנייה הזו רק אינה מציגה.
  Future<void> save(List<T> items) async {
    await _box.put(key, [...items.map(toJson), ..._skippedRaw]);
  }

  /// Clear the list
  ///
  /// מחיקה מפורשת של המשתמש — מוחקת גם את הפריטים שדולגו.
  Future<void> clear() async {
    _skippedRaw = const [];
    await _box.put(key, []);
  }

  /// Add an item at the beginning of the list
  Future<void> addItem(T item) async {
    final list = await load();
    list.insert(0, item);
    await save(list);
  }

  /// Remove item at index
  Future<void> removeAt(int index) async {
    final list = await load();
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      await save(list);
    }
  }
}
