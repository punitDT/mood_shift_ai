import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Modern, theme-matched snackbar utility for MoodShift AI
class SnackbarUtils {
  // Private constructor to prevent instantiation
  SnackbarUtils._();

  /// Show a success snackbar with green theme
  static void showSuccess({
    required String title,
    required String message,
    IconData? icon,
    Duration? duration,
  }) {
    Get.rawSnackbar(
      title: title,
      message: message,
      icon: Icon(
        icon ?? Icons.check_circle_rounded,
        color: Colors.white,
        size: 28.sp,
      ),
      backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.95),
      borderRadius: 16.r,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      duration: duration ?? const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      animationDuration: const Duration(milliseconds: 400),
      boxShadows: [
        BoxShadow(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ],
      titleText: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: Colors.white.withValues(alpha: 0.95),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// Show an error snackbar with red theme
  static void showError({
    required String title,
    required String message,
    IconData? icon,
    Duration? duration,
  }) {
    Get.rawSnackbar(
      title: title,
      message: message,
      icon: Icon(
        icon ?? Icons.error_rounded,
        color: Colors.white,
        size: 28.sp,
      ),
      backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.95),
      borderRadius: 16.r,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      duration: duration ?? const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      animationDuration: const Duration(milliseconds: 400),
      boxShadows: [
        BoxShadow(
          color: const Color(0xFFE53935).withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ],
      titleText: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: Colors.white.withValues(alpha: 0.95),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// Show an info snackbar with purple theme
  static void showInfo({
    required String title,
    required String message,
    IconData? icon,
    Duration? duration,
  }) {
    Get.rawSnackbar(
      title: title,
      message: message,
      icon: Icon(
        icon ?? Icons.info_rounded,
        color: Colors.white,
        size: 28.sp,
      ),
      backgroundColor: const Color(0xFF7C4DFF).withValues(alpha: 0.95),
      borderRadius: 16.r,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      duration: duration ?? const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      animationDuration: const Duration(milliseconds: 400),
      boxShadows: [
        BoxShadow(
          color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ],
      titleText: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: Colors.white.withValues(alpha: 0.95),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// Show a warning snackbar with amber theme
  static void showWarning({
    required String title,
    required String message,
    IconData? icon,
    Duration? duration,
  }) {
    Get.rawSnackbar(
      title: title,
      message: message,
      icon: Icon(
        icon ?? Icons.warning_rounded,
        color: Colors.black87,
        size: 28.sp,
      ),
      backgroundColor: const Color(0xFFFFC107).withValues(alpha: 0.95),
      borderRadius: 16.r,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      duration: duration ?? const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      animationDuration: const Duration(milliseconds: 400),
      boxShadows: [
        BoxShadow(
          color: const Color(0xFFFFC107).withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ],
      titleText: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          letterSpacing: 0.3,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: Colors.black87.withValues(alpha: 0.9),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// Show a custom themed snackbar (for special cases like Golden Voice, 2x Power, etc.)
  static void showCustom({
    required String title,
    required String message,
    required Color backgroundColor,
    required Color textColor,
    IconData? icon,
    Duration? duration,
    SnackPosition? position,
  }) {
    Get.rawSnackbar(
      title: title,
      message: message,
      icon: icon != null
          ? Icon(
              icon,
              color: textColor,
              size: 28.sp,
            )
          : null,
      backgroundColor: backgroundColor.withValues(alpha: 0.95),
      borderRadius: 16.r,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      duration: duration ?? const Duration(seconds: 3),
      snackPosition: position ?? SnackPosition.TOP,
      animationDuration: const Duration(milliseconds: 400),
      boxShadows: [
        BoxShadow(
          color: backgroundColor.withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ],
      titleText: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: textColor.withValues(alpha: 0.95),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

