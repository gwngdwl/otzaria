import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:otzaria/data/repository/hive_list_repository.dart';

/// פריט שנכשל בפענוח חייב להידחות **לבדו**. כשהכשל הפיל את כל הרשימה,
/// סימנייה אחת שאינה נטענת (למשל ספר PDF בבנייה בלי PDF) מחקה מהתצוגה את
/// כל הסימניות — והכתיבה הבאה צרבה את המחיקה לדיסק.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_list_repo_');
    Hive.init(dir.path);
    await Hive.openBox<dynamic>('items');
  });

  tearDown(() async {
    await Hive.close();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  HiveListRepository<String> buildRepo() => HiveListRepository<String>(
    boxName: 'items',
    key: 'key-items',
    fromJson: (json) {
      final value = json['value'] as String;
      if (value == 'bad') throw UnsupportedError('unsupported item');
      return value;
    },
    toJson: (value) => {'value': value},
  );

  test('פריט שנכשל מדולג, והשאר נטענים', () async {
    await Hive.box<dynamic>('items').put('key-items', [
      {'value': 'a'},
      {'value': 'bad'},
      {'value': 'b'},
    ]);

    expect(await buildRepo().load(), ['a', 'b']);
  });

  test('הוספת פריט אינה מוחקת את הפריטים התקינים', () async {
    await Hive.box<dynamic>('items').put('key-items', [
      {'value': 'a'},
      {'value': 'bad'},
      {'value': 'b'},
    ]);

    final repo = buildRepo();
    await repo.addItem('c');

    expect(await repo.load(), ['c', 'a', 'b']);
  });

  test('הפריט שדולג נשאר בדיסק אחרי כתיבה', () async {
    // דילוג אינו מחיקה: `save` דורס את כל הרשימה, ולכן בלי החזרת השורות
    // שדולגו סימנייה שהבנייה הזו אינה טוענת נמחקת לצמיתות בכתיבה הבאה.
    await Hive.box<dynamic>('items').put('key-items', [
      {'value': 'a'},
      {'value': 'bad'},
    ]);

    final repo = buildRepo();
    await repo.addItem('c');

    expect(
      (await repo.loadRaw()).map((e) => e['value']).toList(),
      ['c', 'a', 'bad'],
    );
  });

  test('removeAt אינו מוחק את הפריט שדולג', () async {
    await Hive.box<dynamic>('items').put('key-items', [
      {'value': 'a'},
      {'value': 'bad'},
      {'value': 'b'},
    ]);

    final repo = buildRepo();
    await repo.load();
    await repo.removeAt(0);

    expect(await repo.load(), ['b']);
    expect(
      (await repo.loadRaw()).map((e) => e['value']).toList(),
      ['b', 'bad'],
    );
  });

  test('clear מוחק גם את הפריטים שדולגו', () async {
    await Hive.box<dynamic>('items').put('key-items', [
      {'value': 'a'},
      {'value': 'bad'},
    ]);

    final repo = buildRepo();
    await repo.load();
    await repo.clear();

    expect(await repo.loadRaw(), isEmpty);
  });

  test('רשימה שאינה List כלל מוחזרת ריקה ואינה זורקת', () async {
    await Hive.box<dynamic>('items').put('key-items', 'not-a-list');

    expect(await buildRepo().load(), isEmpty);
  });
}
