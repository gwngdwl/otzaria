import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:otzaria/core/http_client_registry.dart';
import 'package:otzaria/core/pre_close_registry.dart';
import 'package:otzaria/core/window_persistence.dart';
import 'package:otzaria/data/data_providers/sqlite_data_provider.dart';
import 'package:otzaria/data/data_providers/user_books_database_holder.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Callback type for fullscreen state changes
typedef FullscreenCallback = void Function(bool isFullscreen);

/// Window listener that handles window events properly to prevent crashes
class AppWindowListener extends WindowListener {
  static const MethodChannel _processControlChannel = MethodChannel(
    'otzaria/process_control',
  );

  FullscreenCallback? onFullscreenChanged;

  /// נקרא לאחר אירועי מצב חלון דיסקרטיים שעלולים לגרום לאיבוד פוקוס:
  /// maximize, unmaximize, restore, כניסה/יציאה ממסך מלא.
  VoidCallback? onWindowStateChanged;

  /// נקרא בכל אירוע resize רציף — מיועד ל-debounced restore.
  VoidCallback? onWindowResizeOccurred;
  bool _isClosing = false;

  Future<void> _runBestEffortShutdownStep(
    String stepName,
    Future<void> Function() action, {
    required Duration timeout,
  }) async {
    try {
      await action().timeout(timeout);
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint('WebView shutdown step timed out: $stepName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('WebView shutdown step failed ($stepName): $e');
      }
    }
  }

  Future<void> _armForceExitWatchdog() async {
    if (kIsWeb || !Platform.isWindows) {
      return;
    }

    await _processControlChannel.invokeMethod('armForceExitWatchdog', {
      'timeoutMs': 15000,
    });
  }

  @override
  void onWindowEnterFullScreen() {
    if (kDebugMode) {
      debugPrint('Window entered fullscreen');
    }
    onFullscreenChanged?.call(true);
    onWindowStateChanged?.call();
  }

  @override
  void onWindowLeaveFullScreen() {
    if (kDebugMode) {
      debugPrint('Window left fullscreen');
    }
    onFullscreenChanged?.call(false);
    onWindowStateChanged?.call();
  }

  @override
  void onWindowClose() async {
    if (_isClosing) {
      return;
    }
    _isClosing = true;

    if (kDebugMode) {
      debugPrint('Window close requested');
    }

    await _runBestEffortShutdownStep(
      'armForceExitWatchdog',
      _armForceExitWatchdog,
      timeout: const Duration(seconds: 1),
    );

    // סוגרים את כל ה-HTTP clients המתמשכים לפני כל ניקוי אחר. כל socket
    // פתוח מחזיק handle של kernel + state של TLS; ב-Windows admin install
    // + ריצה לא-elevated, ניקוי ה-I/O ע"י הקרנל ביציאה לוקח מספר שניות
    // (Defender real-time scan + מדיניות אמון נמוך). סגירה מקדימה משחררת
    // את ה-resources בזמן שה-UI thread עוד פעיל, ומונעת "Not Responding".
    await _runBestEffortShutdownStep(
      'closeHttpClients',
      HttpClientRegistry.closeAll,
      timeout: const Duration(seconds: 1),
    );

    // Step 1: Non-critical cleanup — errors here must not block Hive.close().
    try {
      await UserBooksDatabaseHolder.instance.close();
      await SqliteDataProvider.instance.dispose();
    } catch (e) {
      if (kDebugMode) print('Non-critical cleanup error: $e');
    }

    // Step 2: Flush pending in-memory writes to Hive.
    // A flush failure must NOT prevent Hive.close() — closing Hive without
    // flushing first is safe, but skipping Hive.close() would corrupt the DB.
    Object? flushFailure;
    try {
      await PreCloseRegistry.runAll();
    } on PreCloseFlushFailure catch (e) {
      flushFailure = e;
      if (kDebugMode) print('Flush failed at exit: $e');
    }

    // Step 3: Error reporting and window destruction.
    //
    // הוסרו במכוון:
    //   - `WindowPersistence.saveNow()` — `Settings.setValue` כותב ל-Hive
    //     `app_preferences`; הקריאה תוקעת את ה-isolate ב-admin install
    //     (`Program Files\אוצריא\`) כי Defender real-time scan חוסם את
    //     ה-CloseHandle של הקובץ. מצב החלון נשמר רציף ב-`scheduleSave`
    //     (debounce 400ms על כל move/resize/maximize), אז ההלך הסופי
    //     היה belt-and-suspenders מיותר.
    //   - `await Hive.close()` — סגירת ה-handles של 7 קבצי `.hive` ב-
    //     `%APPDATA%\otzaria\` נחסמת באותה צורה. כל `box.put()` כבר כותב
    //     מיד דרך FFI ל-OS file buffer; ה-OS שוטף buffers בעת
    //     `ExitProcess`/`TerminateProcess` כשהוא סוגר את ה-handles.
    //     hive_ce שורד dirty shutdown מעיצוב (checksum על כל record).
    //     `PreCloseRegistry.runAll()` ב-step2 כבר flushed את ההיסטוריה.
    try {
      if (flushFailure != null) {
        // Report BEFORE Sentry.close() so the event can still be sent.
        try {
          await Sentry.captureException(
            flushFailure,
            stackTrace: StackTrace.current,
          );
        } catch (_) {
          // Sentry reporting is best-effort; never block the close path.
        }
      }

      if (!kIsWeb && Platform.isWindows) {
        // Sentry.close() calls sentry_close() through synchronous FFI on
        // Windows and can block while the native worker flushes. This path
        // exits the process immediately below, so don't delay app shutdown
        // for telemetry cleanup.
      } else {
        await Sentry.close();
      }

      if (!kIsWeb &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        if (Platform.isWindows) {
          // window_manager.destroy() posts WM_QUIT on Windows. Awaiting it can
          // stop the Flutter engine before the Dart continuation reaches exit().
          exit(0);
        }

        await windowManager.setPreventClose(false);
        // סגירה רגילה דרך ה-WindowManager
        await windowManager.destroy();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error during window close: $e');
      }
      // נשמור על exit(0) רק למקרה חירום של קריסה בתהליך הסגירה
      exit(0);
    }
  }

  @override
  void onWindowFocus() {
    if (kDebugMode) {
      //print('Window focused');
    }
    // איפוס מצב המקלדת בעת קבלת פוקוס, למנוע AssertionError ב-HardwareKeyboard
    // כאשר המשתמש מחזיק מקש, מחליף חלון, ומשחרר - Flutter לא מקבל KeyUpEvent
    // ובעת חזרה לחלון, מקש ה-KeyDown הבא גורם ל-assertion failure
    // ignore: invalid_use_of_visible_for_testing_member
    HardwareKeyboard.instance.clearState();
  }

  @override
  void onWindowBlur() {
    if (kDebugMode) {
      //print('Window blurred');
    }
  }

  @override
  void onWindowMinimize() {
    if (kDebugMode) {
      debugPrint('Window minimized');
    }
  }

  @override
  void onWindowRestore() {
    if (kDebugMode) {
      debugPrint('Window restored');
    }
    onWindowStateChanged?.call();
  }

  @override
  void onWindowResize() {
    if (kDebugMode) {
      debugPrint('Window resized');
    }

    if (WindowPersistence.isRestoring) return;
    WindowPersistence.scheduleSave();
    onWindowResizeOccurred?.call();
  }

  @override
  void onWindowMove() {
    if (kDebugMode) {
      debugPrint('Window moved');
    }

    if (WindowPersistence.isRestoring) return;
    WindowPersistence.scheduleSave();
  }

  @override
  void onWindowMaximize() {
    if (kDebugMode) {
      debugPrint('Window maximized');
    }
    if (WindowPersistence.isRestoring) return;
    WindowPersistence.scheduleSave();
    onWindowStateChanged?.call();
  }

  @override
  void onWindowUnmaximize() {
    if (kDebugMode) {
      debugPrint('Window unmaximized');
    }
    if (WindowPersistence.isRestoring) return;
    WindowPersistence.scheduleSave();
    onWindowStateChanged?.call();
  }

  /// Clean up the listener when disposing
  void dispose() {
    // Remove this listener from window manager
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.removeListener(this);
    }
  }
}
