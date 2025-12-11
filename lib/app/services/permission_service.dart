import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'storage_service.dart';
import 'habit_service.dart';
import '../utils/snackbar_utils.dart';
import '../utils/responsive_utils.dart';

/// 2025-compliant permission service for MoodShift AI
/// Handles microphone and notification permissions with Apple & Google approved dialogs
class PermissionService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();

  // Storage keys for tracking permission requests
  static const String _keyMicPermissionAsked = 'mic_permission_asked';
  static const String _keyNotificationPermissionAsked = 'notification_permission_asked';

  /// Check if microphone permission has been asked before
  bool get hasMicPermissionBeenAsked {
    return _storage.box.read(_keyMicPermissionAsked) ?? false;
  }

  /// Check if notification permission has been asked before
  bool get hasNotificationPermissionBeenAsked {
    return _storage.box.read(_keyNotificationPermissionAsked) ?? false;
  }

  /// Mark microphone permission as asked
  void _markMicPermissionAsked() {
    _storage.box.write(_keyMicPermissionAsked, true);
  }

  /// Mark notification permission as asked
  void _markNotificationPermissionAsked() {
    _storage.box.write(_keyNotificationPermissionAsked, true);
  }

  /// Request microphone permission with 2025-compliant dialog
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      return await _showMicrophoneSettingsDialog();
    }

    if (status.isDenied && hasMicPermissionBeenAsked) {
      return await _showMicrophoneSettingsDialog();
    }

    final shouldRequest = await _showMicrophoneEducationalDialog();

    if (!shouldRequest) {
      _markMicPermissionAsked();
      return false;
    }

    _markMicPermissionAsked();
    final newStatus = await Permission.microphone.request();

    if (newStatus.isGranted) {
      return true;
    } else if (newStatus.isPermanentlyDenied) {
      SnackbarUtils.showWarning(
        title: 'permission_denied'.tr,
        message: 'permission_denied_message'.tr,
      );
      return false;
    } else {
      return false;
    }
  }

  /// Show educational dialog explaining why microphone is needed
  /// Returns true if user wants to proceed, false if cancelled
  Future<bool> _showMicrophoneEducationalDialog() async {
    final context = Get.context;
    final isTablet = context != null ? ResponsiveUtils.isTablet(context) : false;

    final result = await Get.dialog<bool>(
      PopScope(
        canPop: false, // Prevent dismissing by tapping outside
        child: Dialog(
          backgroundColor: const Color(0xFF1A1030),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 24 : 24.r),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(Get.context!).size.height * 0.8,
              maxWidth: isTablet ? 420 : 400,
            ),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 28 : 24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Scrollable content
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon with gradient background
                          Container(
                            width: isTablet ? 72 : 64.w,
                            height: isTablet ? 72 : 64.w,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C4DFF), Color(0xFF6D5FFD)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C4DFF).withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.mic_rounded,
                              size: isTablet ? 36 : 32.sp,
                              color: Colors.white,
                            ),
                          ),

                          SizedBox(height: isTablet ? 24 : 20.h),

                          // Title
                          Text(
                            'mic_permission_title'.tr,
                            style: TextStyle(
                              fontSize: isTablet ? 22 : 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: isTablet ? 16 : 16.h),

                          // Content
                          Text(
                            'mic_permission_message'.tr,
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.8),
                              height: 1.5,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isTablet ? 28 : 24.h),

                  // Buttons (fixed at bottom)
                  Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(result: false),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 12 : 12.r),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'permission_cancel'.tr,
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.7),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: isTablet ? 16 : 12.w),

                      // Continue button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Get.back(result: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C4DFF),
                            padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 12 : 12.r),
                            ),
                            elevation: 0,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'permission_continue'.tr,
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    return result ?? false;
  }

  /// Show settings dialog when permission is denied/permanently denied
  /// Returns true if permission is granted after opening settings, false otherwise
  Future<bool> _showMicrophoneSettingsDialog() async {
    final context = Get.context;
    final isTablet = context != null ? ResponsiveUtils.isTablet(context) : false;

    final result = await Get.dialog<bool>(
      PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: const Color(0xFF1A1030),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 24 : 24.r),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(Get.context!).size.height * 0.8,
              maxWidth: isTablet ? 420 : 400,
            ),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 28 : 18.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Scrollable content
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon with gradient background
                          Container(
                            width: isTablet ? 72 : 64.w,
                            height: isTablet ? 72 : 64.w,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE53935), Color(0xFFFF5252)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE53935).withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.settings_rounded,
                              size: isTablet ? 36 : 32.sp,
                              color: Colors.white,
                            ),
                          ),

                          SizedBox(height: isTablet ? 24 : 20.h),

                          // Title
                          Text(
                            'mic_permission_settings_title'.tr,
                            style: TextStyle(
                              fontSize: isTablet ? 22 : 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: isTablet ? 16 : 16.h),

                          // Content
                          Text(
                            'mic_permission_settings_message'.tr,
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.8),
                              height: 1.5,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isTablet ? 28 : 24.h),

                  // Buttons (fixed at bottom)
                  Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(result: false),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 12 : 12.r),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'permission_cancel'.tr,
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.7),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: isTablet ? 16 : 12.w),

                      // Open Settings button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Get.back(result: false);
                            await openAppSettings();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C4DFF),
                            padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 12 : 12.r),
                            ),
                            elevation: 0,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'permission_open_settings'.tr,
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    return result ?? false;
  }

  /// Request notification permission with 2025-compliant dialog (optional)
  /// This should be called AFTER microphone permission is granted
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestNotificationPermission() async {
    if (hasNotificationPermissionBeenAsked) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }

    final shouldRequest = await _showNotificationEducationalDialog();
    _markNotificationPermissionAsked();

    if (!shouldRequest) {
      return false;
    }

    final status = await Permission.notification.request();

    if (status.isGranted) {
      // Schedule the reminder notification now that permission is granted
      await HabitService.scheduleReminderNotification();
      SnackbarUtils.showSuccess(
        title: 'reminder_set'.tr,
        message: 'reminder_set_message'.tr,
      );
      return true;
    } else {
      return false;
    }
  }

  /// Show educational dialog for notification permission (optional, skippable)
  /// Returns true if user wants to enable, false if not now
  Future<bool> _showNotificationEducationalDialog() async {
    final context = Get.context;
    final isTablet = context != null ? ResponsiveUtils.isTablet(context) : false;

    final result = await Get.dialog<bool>(
      Dialog(
        backgroundColor: const Color(0xFF1A1030),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 24 : 24.r),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(Get.context!).size.height * 0.8,
            maxWidth: isTablet ? 420 : 400,
          ),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 28 : 24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon with gradient background
                        Container(
                          width: isTablet ? 72 : 64.w,
                          height: isTablet ? 72 : 64.w,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.notifications_rounded,
                            size: isTablet ? 36 : 32.sp,
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(height: isTablet ? 24 : 20.h),

                        // Title
                        Text(
                          'notification_permission_title'.tr,
                          style: TextStyle(
                            fontSize: isTablet ? 22 : 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: isTablet ? 16 : 16.h),

                        // Content
                        Text(
                          'notification_permission_message'.tr,
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.5,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isTablet ? 28 : 24.h),

                // Buttons (fixed at bottom)
                Row(
                  children: [
                    // Not now button
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(result: false),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isTablet ? 12 : 12.r),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'permission_not_now'.tr,
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.7),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: isTablet ? 16 : 12.w),

                    // Yes, remind me button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Get.back(result: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isTablet ? 12 : 12.r),
                          ),
                          elevation: 0,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'permission_yes_remind'.tr,
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true, // Can be dismissed - it's optional
    );

    return result ?? false;
  }

  /// Complete permission flow for first-time mic button press
  /// 1. Request microphone (required)
  /// 2. If granted, request notifications (optional)
  /// Returns a map with:
  /// - 'granted': true if microphone is granted, false otherwise
  /// - 'justGranted': true if permissions were just granted (user should tap again), false if already had permission
  Future<Map<String, bool>> requestPermissionsFlow() async {
    final currentStatus = await Permission.microphone.status;
    final alreadyGranted = currentStatus.isGranted;

    final micGranted = await requestMicrophonePermission();

    if (!micGranted) {
      return {'granted': false, 'justGranted': false};
    }

    if (alreadyGranted) {
      return {'granted': true, 'justGranted': false};
    }

    if (!hasNotificationPermissionBeenAsked) {
      await requestNotificationPermission();
    }

    return {'granted': true, 'justGranted': true};
  }
}
