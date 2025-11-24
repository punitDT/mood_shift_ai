import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// HabitService - Smart daily streak + shift counter + non-annoying notifications
/// 
/// Features:
/// - Daily streak tracking (Day 1, Day 2, etc.)
/// - Today's shift count
/// - Total lifetime shifts
/// - Total active days (days with at least 1 shift)
/// - Smart local notifications (max 1 per day, never spam)
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
  static const String _keyLastNotifyDate = 'last_notify_date';
  
  Future<HabitService> init() async {
    _box = GetStorage();
    _notifications = FlutterLocalNotificationsPlugin();
    
    // Initialize timezone
    tz.initializeTimeZones();
    
    // Save install date if first launch
    if (_box.read(_keyInstallDate) == null) {
      _box.write(_keyInstallDate, DateTime.now().toIso8601String());
      print('📅 [HABIT] Install date saved: ${DateTime.now()}');
    }
    
    // Initialize notification plugin
    await _initializeNotifications();
    
    // Schedule next notification
    await _scheduleSmartNotification();
    
    return this;
  }
  
  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        print('🔔 [HABIT] Notification tapped: ${details.payload}');
      },
    );
    
    // Request permissions on iOS
    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    
    print('🔔 [HABIT] Notifications initialized');
  }
  
  // ========== PUBLIC STATIC API ==========
  
  /// Call this after every successful shift
  static void userDidAShiftToday() {
    final service = HabitService.to;
    service._recordShift();
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
  
  // ========== PRIVATE METHODS ==========
  
  void _recordShift() {
    final now = DateTime.now();
    final lastShiftDate = _box.read(_keyLastShiftDate);

    // Note: Total shifts is incremented by StreakController, not here
    // to avoid double-counting

    // Check if this is first shift today
    final isFirstShiftToday = lastShiftDate == null ||
        !_isSameDay(DateTime.parse(lastShiftDate), now);

    if (isFirstShiftToday) {
      // First shift of the day
      _updateDailyStreak(now, lastShiftDate);
      _box.write(_keyTodayShifts, 1);

      // Increment active days
      final activeDays = (_box.read(_keyActiveDays) ?? 0) + 1;
      _box.write(_keyActiveDays, activeDays);

      print('🔥 [HABIT] First shift today! Streak: ${streak}, Active days: ${activeDays}');
    } else {
      // Additional shift today
      final todayShifts = (_box.read(_keyTodayShifts) ?? 0) + 1;
      _box.write(_keyTodayShifts, todayShifts);

      print('📊 [HABIT] Shift #$todayShifts today');
    }

    // Update last shift date
    _box.write(_keyLastShiftDate, now.toIso8601String());

    // Schedule next notification
    _scheduleSmartNotification();
  }
  
  void _updateDailyStreak(DateTime now, String? lastShiftDate) {
    int currentStreak = _box.read(_keyCurrentStreak) ?? 0;

    if (lastShiftDate == null) {
      // First shift ever - start at Day 1
      currentStreak = 1;
    } else {
      final last = DateTime.parse(lastShiftDate);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final lastDay = DateTime(last.year, last.month, last.day);

      if (_isSameDay(lastDay, yesterday)) {
        // Consecutive day - increment streak
        currentStreak++;
      } else {
        // Streak broken - reset to Day 1
        currentStreak = 1;
        print('💔 [HABIT] Streak broken. Starting fresh at Day 1');
      }
    }

    _box.write(_keyCurrentStreak, currentStreak);
    print('🔥 [HABIT] Streak updated: Day $currentStreak');
  }
  
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  // ========== SMART NOTIFICATION SYSTEM ==========
  
  Future<void> _scheduleSmartNotification() async {
    // Cancel any existing notifications
    await _notifications.cancelAll();
    
    // Check if we should send a notification
    if (!_shouldSendNotification()) {
      print('🔕 [HABIT] No notification needed today');
      return;
    }
    
    // Schedule for tomorrow at 9 AM
    final tomorrow9AM = _getNext9AM();
    
    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'habit_reminder',
        'Daily Reminders',
        channelDescription: 'Gentle reminders to keep your streak alive',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    
    final message = _getNotificationMessage();
    
    await _notifications.zonedSchedule(
      0, // notification id
      message['title']!,
      message['body']!,
      tomorrow9AM,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    
    print('🔔 [HABIT] Notification scheduled for ${tomorrow9AM.toLocal()}');
    print('   Title: ${message['title']}');
    print('   Body: ${message['body']}');
  }
  
  bool _shouldSendNotification() {
    final installDate = _box.read(_keyInstallDate);
    if (installDate == null) return false;
    
    final install = DateTime.parse(installDate);
    final now = DateTime.now();
    final daysSinceInstall = now.difference(install).inDays;
    
    final lastNotifyDate = _box.read(_keyLastNotifyDate);
    final lastShiftDate = _box.read(_keyLastShiftDate);
    
    // Check if already notified today
    if (lastNotifyDate != null) {
      final lastNotify = DateTime.parse(lastNotifyDate);
      if (_isSameDay(lastNotify, now)) {
        return false; // Already notified today
      }
    }
    
    // Check if user already shifted today
    if (lastShiftDate != null) {
      final lastShift = DateTime.parse(lastShiftDate);
      if (_isSameDay(lastShift, now)) {
        return false; // Already shifted today, no need to remind
      }
    }
    
    // Rule 1: First 3 days after install → always notify
    if (daysSinceInstall < 3) {
      _box.write(_keyLastNotifyDate, now.toIso8601String());
      return true;
    }
    
    // Rule 2: Streak ≥ 3 and would lose it today → notify
    final currentStreak = _box.read(_keyCurrentStreak) ?? 0;
    if (currentStreak >= 3) {
      // Check if last shift was yesterday
      if (lastShiftDate != null) {
        final lastShift = DateTime.parse(lastShiftDate);
        final yesterday = DateTime(now.year, now.month, now.day - 1);
        final lastDay = DateTime(lastShift.year, lastShift.month, lastShift.day);
        
        if (_isSameDay(lastDay, yesterday)) {
          // Streak is at risk!
          _box.write(_keyLastNotifyDate, now.toIso8601String());
          return true;
        }
      }
    }
    
    // Rule 3: After day 14 → max 1 notification every 4 days
    if (daysSinceInstall >= 14) {
      if (lastNotifyDate != null) {
        final lastNotify = DateTime.parse(lastNotifyDate);
        final daysSinceLastNotify = now.difference(lastNotify).inDays;
        
        if (daysSinceLastNotify >= 4) {
          _box.write(_keyLastNotifyDate, now.toIso8601String());
          return true;
        }
      } else {
        // Never notified before (after day 14)
        _box.write(_keyLastNotifyDate, now.toIso8601String());
        return true;
      }
    }
    
    return false;
  }
  
  Map<String, String> _getNotificationMessage() {
    final currentStreak = _box.read(_keyCurrentStreak) ?? 0;
    final installDate = _box.read(_keyInstallDate);
    final daysSinceInstall = installDate != null
        ? DateTime.now().difference(DateTime.parse(installDate)).inDays
        : 0;
    
    // Streak protection message
    if (currentStreak >= 3) {
      return {
        'title': '🔥 Save your $currentStreak-day streak!',
        'body': 'Just one quick shift to keep it alive ❤️',
      };
    }
    
    // First 3 days - gentle welcome
    if (daysSinceInstall < 3) {
      return {
        'title': '✨ Ready for a quick shift?',
        'body': 'Take a moment to shift your mood today',
      };
    }
    
    // Default gentle reminder
    return {
      'title': '💜 Time for a mood shift?',
      'body': 'Your daily moment of calm awaits',
    };
  }
  
  tz.TZDateTime _getNext9AM() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9, // 9 AM
      0,
      0,
    );
    
    // If 9 AM today has passed, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    
    return scheduled;
  }
}

