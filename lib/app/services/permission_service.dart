import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'storage_service.dart';
import '../utils/snackbar_utils.dart';

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
    print('🎤 [PERMISSION] Requesting microphone permission');

    // Check current permission status
    final status = await Permission.microphone.status;

    if (status.isGranted) {
      print('✅ [PERMISSION] Microphone already granted');
      return true;
    }

    // If permanently denied, show settings dialog
    if (status.isPermanentlyDenied) {
      print('⚠️  [PERMISSION] Microphone permanently denied - showing settings dialog');
      return await _showMicrophoneSettingsDialog();
    }

    // If denied but not permanently, show educational dialog first
    if (status.isDenied && hasMicPermissionBeenAsked) {
      print('⚠️  [PERMISSION] Microphone denied previously - showing settings dialog');
      return await _showMicrophoneSettingsDialog();
    }

    // First time asking - show educational dialog then request
    print('🎤 [PERMISSION] First time asking for microphone - showing educational dialog');
    final shouldRequest = await _showMicrophoneEducationalDialog();

    if (!shouldRequest) {
      print('❌ [PERMISSION] User cancelled microphone permission request');
      _markMicPermissionAsked();
      return false;
    }

    // Request the permission
    _markMicPermissionAsked();
    final newStatus = await Permission.microphone.request();

    if (newStatus.isGranted) {
      print('✅ [PERMISSION] Microphone permission granted');
      return true;
    } else if (newStatus.isPermanentlyDenied) {
      print('❌ [PERMISSION] Microphone permission permanently denied');
      SnackbarUtils.showWarning(
        title: 'permission_denied'.tr,
        message: 'permission_denied_message'.tr,
      );
      return false;
    } else {
      print('❌ [PERMISSION] Microphone permission denied');
      return false;
    }
  }

  /// Show educational dialog explaining why microphone is needed
  /// Returns true if user wants to proceed, false if cancelled
  Future<bool> _showMicrophoneEducationalDialog() async {
    final result = await Get.dialog<bool>(
      WillPopScope(
        onWillPop: () async => false, // Prevent dismissing by tapping outside
        child: Dialog(
          backgroundColor: const Color(0xFF2A1F3D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    size: 32.sp,
                    color: const Color(0xFF7C4DFF),
                  ),
                ),

                SizedBox(height: 20.h),

                // Title
                Text(
                  'mic_permission_title'.tr,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 16.h),

                // Content
                Text(
                  'mic_permission_message'.tr,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.5,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 24.h),

                // Buttons
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(result: false),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'permission_cancel'.tr,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.7),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 12.w),

                    // Continue button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Get.back(result: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C4DFF),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'permission_continue'.tr,
                            style: TextStyle(
                              fontSize: 16.sp,
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
      barrierDismissible: false,
    );

    return result ?? false;
  }

  /// Show settings dialog when permission is denied/permanently denied
  /// Returns true if permission is granted after opening settings, false otherwise
  Future<bool> _showMicrophoneSettingsDialog() async {
    final result = await Get.dialog<bool>(
      WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: const Color(0xFF2A1F3D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    size: 32.sp,
                    color: const Color(0xFFE53935),
                  ),
                ),

                SizedBox(height: 20.h),

                // Title
                Text(
                  'mic_permission_settings_title'.tr,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 16.h),

                // Content
                Text(
                  'mic_permission_settings_message'.tr,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.5,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 24.h),

                // Buttons
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(result: false),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'permission_cancel'.tr,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.7),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 12.w),

                    // Open Settings button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Get.back(result: false);
                          await openAppSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C4DFF),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'permission_open_settings'.tr,
                            style: TextStyle(
                              fontSize: 16.sp,
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
      barrierDismissible: false,
    );

    return result ?? false;
  }

  /// Request notification permission with 2025-compliant dialog (optional)
  /// This should be called AFTER microphone permission is granted
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestNotificationPermission() async {
    print('🔔 [PERMISSION] Requesting notification permission');

    // Check if already asked
    if (hasNotificationPermissionBeenAsked) {
      print('⚠️  [PERMISSION] Notification permission already asked - skipping');
      final status = await Permission.notification.status;
      return status.isGranted;
    }

    // Show educational dialog
    final shouldRequest = await _showNotificationEducationalDialog();
    _markNotificationPermissionAsked();

    if (!shouldRequest) {
      print('❌ [PERMISSION] User declined notification permission');
      return false;
    }

    // Request the permission
    final status = await Permission.notification.request();

    if (status.isGranted) {
      print('✅ [PERMISSION] Notification permission granted');
      SnackbarUtils.showSuccess(
        title: 'reminder_set'.tr,
        message: 'reminder_set_message'.tr,
      );
      return true;
    } else {
      print('❌ [PERMISSION] Notification permission denied');
      return false;
    }
  }

  /// Show educational dialog for notification permission (optional, skippable)
  /// Returns true if user wants to enable, false if not now
  Future<bool> _showNotificationEducationalDialog() async {
    final result = await Get.dialog<bool>(
      Dialog(
        backgroundColor: const Color(0xFF2A1F3D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_rounded,
                  size: 32.sp,
                  color: const Color(0xFF4CAF50),
                ),
              ),

              SizedBox(height: 20.h),

              // Title
              Text(
                'notification_permission_title'.tr,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 16.h),

              // Content
              Text(
                'notification_permission_message'.tr,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.8),
                  height: 1.5,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 24.h),

              // Buttons
              Row(
                children: [
                  // Not now button
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(result: false),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'permission_not_now'.tr,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Yes, remind me button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'permission_yes_remind'.tr,
                          style: TextStyle(
                            fontSize: 16.sp,
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
    print('🎯 [PERMISSION] Starting complete permission flow');

    // Check if microphone permission is already granted
    final currentStatus = await Permission.microphone.status;
    final alreadyGranted = currentStatus.isGranted;

    print('🎤 [PERMISSION] Microphone already granted: $alreadyGranted');

    // Step 1: Request microphone (required)
    final micGranted = await requestMicrophonePermission();

    if (!micGranted) {
      print('❌ [PERMISSION] Microphone not granted - stopping flow');
      return {'granted': false, 'justGranted': false};
    }

    // If permission was already granted, no dialogs were shown
    if (alreadyGranted) {
      print('✅ [PERMISSION] Permission already granted - user can proceed immediately');
      return {'granted': true, 'justGranted': false};
    }

    // Step 2: Request notifications (optional) - only if not asked before
    if (!hasNotificationPermissionBeenAsked) {
      print('🔔 [PERMISSION] Microphone granted - requesting notifications');
      await requestNotificationPermission();
    }

    print('✅ [PERMISSION] Permission flow complete - permissions just granted');
    return {'granted': true, 'justGranted': true};
  }
}
