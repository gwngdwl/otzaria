import 'dart:io';

bool checkLibraryIsEmpty() {
  // This shouldn't be called on native platforms
  return true;
}

bool checkLibraryIsEmptyNative(String libraryPath) {
  // בדיקה שהתיקייה הראשית קיימת
  final rootDir = Directory(libraryPath);
  if (!rootDir.existsSync()) {
    return true;
  }

  // בדיקה שתיקיית אוצריא קיימת
  final libraryDir = Directory('$libraryPath${Platform.pathSeparator}אוצריא');
  if (!libraryDir.existsSync()) {
    return true;
  }

  // בדיקה שהתיקייה לא ריקה
  try {
    final contents = libraryDir.listSync();
    if (contents.isEmpty) {
      return true;
    }
  } catch (e) {
    // אם יש שגיאה בגישה לתיקייה, נחשיב אותה כריקה
    return true;
  }

  return false;
}
