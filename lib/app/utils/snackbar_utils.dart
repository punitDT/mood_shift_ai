import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'responsive_utils.dart';

/// Modern, theme-matched snackbar utility for MoodShift AI
class SnackbarUtils {
  // Private constructor to prevent instantiation
  SnackbarUtils._();

  /// Check if current device is a tablet
  static bool _isTablet() {
    final context = Get.context;
    if (context == null) return false;
    return ResponsiveUtils.isTablet(context);
  }

  /// Get responsive margin for snackbar
  static EdgeInsets _getMargin() {
    final isTablet = _isTablet();
    if (isTablet) {
      // Center snackbar on tablet with max width
      final context = Get.context;
      if (context != null) {
        final screenWidth = MediaQuery.of(context).size.width;
        final snackbarWidth = 400.0;
        final horizontalMargin = (screenWidth - snackbarWidth) / 2;
        return EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 20);
      }
    }
    return EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h);
  }

  /// Get responsive padding for snackbar
  static EdgeInsets _getPadding() {
    final isTablet = _isTablet();
    return EdgeInsets.symmetric(
      horizontal: isTablet ? 24 : 20.w,
      vertical: isTablet ? 18 : 16.h,
    );
  }

  /// Get responsive icon size
  static double _getIconSize() {
    return _isTablet() ? 28 : 28.sp;
  }

  /// Get responsive title font size
  static double _getTitleFontSize() {
    return _isTablet() ? 17 : 16.sp;
  }

  /// Get responsive message font size
  static double _getMessageFontSize() {
    return _isTablet() ? 15 : 14.sp;
  }

  /// Get responsive border radius
  static double _getBorderRadius() {
    return _isTablet() ? 16 : 16.r;
  }

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
        size: _getIconSize(),
      ),
      backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.95),
      borderRadius: _getBorderRadius(),
      margin: _getMargin(),
      padding: _getPadding(),
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
          fontSize: _getTitleFontSize(),
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          fontSize: _getMessageFontSize(),
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
        size: _getIconSize(),
      ),
      backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.95),
      borderRadius: _getBorderRadius(),
      margin: _getMargin(),
      padding: _getPadding(),
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
          fontSize: _getTitleFontSize(),
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          fontSize: _getMessageFontSize(),
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
        size: _getIconSize(),
      ),
      backgroundColor: const Color(0xFF7C4DFF).withValues(alpha: 0.95),
      borderRadius: _getBorderRadius(),
      margin: _getMargin(),
      padding: _getPadding(),
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
          fontSize: _getTitleFontSize(),
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          fontSize: _getMessageFontSize(),
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
        size: _getIconSize(),
      ),
      backgroundColor: const Color(0xFFFFC107).withValues(alpha: 0.95),
      borderRadius: _getBorderRadius(),
      margin: _getMargin(),
      padding: _getPadding(),
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
          fontSize: _getTitleFontSize(),
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          letterSpacing: 0.3,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          fontSize: _getMessageFontSize(),
          fontWeight: FontWeight.w400,
          color: Colors.black87.withValues(alpha: 0.9),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// Show a custom themed snackbar (for special cases like Crystal Voice, 2x Power, etc.)
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
              size: _getIconSize(),
            )
          : null,
      backgroundColor: backgroundColor.withValues(alpha: 0.95),
      borderRadius: _getBorderRadius(),
      margin: _getMargin(),
      padding: _getPadding(),
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
          fontSize: _getTitleFontSize(),
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          fontSize: _getMessageFontSize(),
          fontWeight: FontWeight.w400,
          color: textColor.withValues(alpha: 0.95),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

