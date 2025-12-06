import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// HabitService - Smart daily streak + shift counter + non-annoying notifications
///
/// Features:
/// - Daily streak tracking (Day 1, Day 2, etc.)
/// - Today's shift count
/// - Total lifetime shifts
/// - Total active days (days with at least 1 shift)
/// - Weekly reminder notifications
class HabitService extends GetxService {
  static HabitService get to => Get.find();

  late final GetStorage _box;
  late final FlutterLocalNotificationsPlugin _notifications;

  // Storage keys
  static const String _keyInstallDate = 'install_date';
  static const String _keyLastShiftDate = 'last_shift_date';
  static const String _keyCurrentStreak = 'current_streak';
  static const String _keyTodayShifts = 'today_shifts';
  static const String _keyTotalShifts = 'total_shifts';
  static const String _keyActiveDays = 'active_days';

  // Notification ID
  static const int _notificationId = 1;

  Future<HabitService> init() async {
    try {
      _box = GetStorage();
      _notifications = FlutterLocalNotificationsPlugin();

      if (_box.read(_keyInstallDate) == null) {
        _box.write(_keyInstallDate, DateTime.now().toIso8601String());
      }

      await _initializeNotifications();
      // Note: Do NOT schedule notifications on app start
      // Notifications are scheduled after user grants permission and completes a shift

      return this;
    } catch (e) {
      debugPrint('HabitService init error: $e');
      return this;
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      final channelName = 'notification_channel_name'.tr;
      final channelDescription = 'notification_channel_description'.tr;

      final androidChannel = AndroidNotificationChannel(
        'habit_reminder',
        channelName,
        description: channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(androidChannel);
        // Note: Permission requests are handled by PermissionService when user clicks speak button
        // Do NOT request permissions here on app start
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      // Do NOT request permissions on iOS during initialization
      // Permissions are requested by PermissionService when user clicks speak button
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification tapped: ${details.payload}');
        },
      );

      debugPrint('Notifications initialized successfully');
    } catch (e) {
      debugPrint('Notification init error: $e');
    }
  }
  
  // ========== PUBLIC STATIC API ==========

  /// Call this after every successful shift
  static void userDidAShiftToday() {
    final service = HabitService.to;
    service._recordShift();
  }

  /// Schedule notification reminder - call this once after user grants notification permission
  static Future<void> scheduleReminderNotification() async {
    final service = HabitService.to;
    await service._scheduleNotification();
  }

  /// Get current daily streak
  static int get streak {
    final service = HabitService.to;
    return service._box.read(_keyCurrentStreak) ?? 0;
  }

  /// Get today's shift count
  static int get todayShifts {
    final service = HabitService.to;
    final lastShiftDate = service._box.read(_keyLastShiftDate);
    if (lastShiftDate == null) return 0;

    final last = DateTime.parse(lastShiftDate);
    final today = DateTime.now();

    // If last shift was today, return today's count
    if (service._isSameDay(last, today)) {
      return service._box.read(_keyTodayShifts) ?? 0;
    }

    return 0; // Different day, reset
  }

  /// Get total lifetime shifts
  static int get totalShifts {
    final service = HabitService.to;
    return service._box.read(_keyTotalShifts) ?? 0;
  }

  /// Get total active days (days with at least 1 shift)
  static int get activeDays {
    final service = HabitService.to;
    return service._box.read(_keyActiveDays) ?? 0;
  }

  /// Test notification - shows immediately (for Crashlytics testing)
  static Future<void> testNotification() async {
    final service = HabitService.to;
    await service._showTestNotification();
  }

  // ========== PRIVATE METHODS ==========

  void _recordShift() {
    final now = DateTime.now();
    final lastShiftDate = _box.read(_keyLastShiftDate);

    // Check if this is first shift today
    final isFirstShiftToday = lastShiftDate == null ||
        !_isSameDay(DateTime.parse(lastShiftDate), now);

    if (isFirstShiftToday) {
      _updateDailyStreak(now, lastShiftDate);
      _box.write(_keyTodayShifts, 1);

      final activeDays = (_box.read(_keyActiveDays) ?? 0) + 1;
      _box.write(_keyActiveDays, activeDays);
    } else {
      final todayShifts = (_box.read(_keyTodayShifts) ?? 0) + 1;
      _box.write(_keyTodayShifts, todayShifts);
    }

    _box.write(_keyLastShiftDate, now.toIso8601String());
  }

  void _updateDailyStreak(DateTime now, String? lastShiftDate) {
    int currentStreak = _box.read(_keyCurrentStreak) ?? 0;

    if (lastShiftDate == null) {
      currentStreak = 1;
    } else {
      final last = DateTime.parse(lastShiftDate);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final lastDay = DateTime(last.year, last.month, last.day);

      if (_isSameDay(lastDay, yesterday)) {
        currentStreak++;
      } else {
        currentStreak = 1;
      }
    }

    _box.write(_keyCurrentStreak, currentStreak);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Schedules weekly reminder notification
  /// Uses simple periodic notification - works in all locales without timezone complexity
  Future<void> _scheduleNotification() async {
    try {
      // Cancel any existing notifications before scheduling new one
      await _notifications.cancelAll();

      final title = 'notification_title'.tr;
      final body = 'notification_body'.tr;
      final channelName = 'notification_channel_name'.tr;
      final channelDescription = 'notification_channel_description'.tr;

      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminder',
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // Schedule weekly repeating notification
      // This uses the system's AlarmManager (Android) / UNUserNotificationCenter (iOS)
      // which handles timezone and locale automatically
      await _notifications.periodicallyShow(
        _notificationId,
        title,
        body,
        RepeatInterval.weekly,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

      debugPrint('📅 Weekly notification reminder scheduled successfully');
    } catch (e) {
      debugPrint('Notification schedule error: $e');
    }
  }

  /// Test notification - shows immediately (for Crashlytics testing)
  Future<void> _showTestNotification() async {
    try {
      final title = 'notification_title'.tr;
      final body = 'notification_body'.tr;
      final channelName = 'notification_channel_name'.tr;
      final channelDescription = 'notification_channel_description'.tr;

      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminder',
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notifications.show(
        999,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      // Silently fail - not critical
    }
  }
}
