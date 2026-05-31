import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria/core/window_persistence.dart';

import '../helpers/memory_settings_cache.dart';

void main() {
  setUp(() async {
    await Settings.init(cacheProvider: MemorySettingsCache());
  });

  test('saveMaximizedState persists the maximized flag immediately', () async {
    await WindowPersistence.saveMaximizedState(true);

    expect(Settings.getValue<bool>('window_is_maximized'), isTrue);

    await WindowPersistence.saveMaximizedState(false);

    expect(Settings.getValue<bool>('window_is_maximized'), isFalse);
  });
}
