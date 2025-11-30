/// Web implementation of navigation repository

bool checkLibraryIsEmpty() {
  // On web, we'll need to check IndexedDB or localStorage
  // For now, return false to allow the app to load
  // TODO: Implement proper web storage check
  return false;
}

bool checkLibraryIsEmptyNative(String libraryPath) {
  // This shouldn't be called on web
  return false;
}
