import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _permissionsGranted = false;
  bool _isInitialized = false;

  Future<void> init() async {
    // Initialize timezone database
    tz.initializeTimeZones();
    // Set default timezone to Israel
    tz.setLocalLocation(tz.getLocation('Asia/Jerusalem'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open');

    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: initializationSettingsIOS,
            linux: initializationSettingsLinux);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);

    _isInitialized = true;

    // Request permissions
    await requestPermissions();
  }

  bool get isInitialized => _isInitialized;

  /// Request notification permissions (Android 13+ and iOS)
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Request exact alarm permission for Android 12+
        final exactAlarmGranted =
            await androidPlugin.requestExactAlarmsPermission();

        // Request notification permission for Android 13+
        final notificationGranted =
            await androidPlugin.requestNotificationsPermission();

        _permissionsGranted =
            (exactAlarmGranted ?? true) && (notificationGranted ?? true);
        return _permissionsGranted;
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      final iosPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      _permissionsGranted = granted ?? false;
      return _permissionsGranted;
    }

    // Windows and Linux don't require permissions
    _permissionsGranted = true;
    return true;
  }

  bool get hasPermissions => _permissionsGranted;

  void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    // Handle notification tapped logic here
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime eventDate,
    required int reminderMinutes,
    bool soundEnabled = true,
  }) async {
    // Check if initialized before scheduling
    if (!_isInitialized) {
      if (kDebugMode) {
        debugPrint('Cannot schedule notification: service not initialized');
      }
      return;
    }

    // Check permissions before scheduling
    if (!_permissionsGranted) {
      if (kDebugMode) {
        debugPrint('Cannot schedule notification: permissions not granted');
      }
      return;
    }

    final scheduleTime = eventDate.subtract(Duration(minutes: reminderMinutes));

    // Ensure the notification is scheduled for the future
    if (scheduleTime.isBefore(DateTime.now())) {
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'calendar_channel',
      'התראות לוח שנה',
      channelDescription: 'התראות על אירועים בלוח השנה',
      importance: Importance.max,
      priority: Priority.high,
      playSound: soundEnabled,
      icon: '@mipmap/ic_launcher',
    );

    final iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: soundEnabled,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
      macOS: iOSDetails,
      linux: const LinuxNotificationDetails(),
    );

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduleTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to schedule notification: $e');
      }
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
