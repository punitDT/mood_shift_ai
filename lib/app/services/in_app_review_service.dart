import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_utils.dart';
import 'storage_service.dart';

/// InAppReviewService - Handles native app store review prompts
///
/// Features:
/// - Triggers review dialog when user reaches 15 shifts
/// - Tracks if user has already rated or dismissed
/// - Never shows again after first prompt
/// - Graceful fallback if in_app_review is not available
class InAppReviewService extends GetxService {
  static InAppReviewService get to => Get.find();

  late final InAppReview _inAppReview;
  late final StorageService _storage;

  // Storage keys
  static const String _keyRatedOrDismissed = 'rated_or_dismissed';
  static const int _shiftsThreshold = 15;

  Future<InAppReviewService> init() async {
    try {
      _inAppReview = InAppReview.instance;
      _storage = Get.find<StorageService>();
      AppLogger.info('📱 InAppReviewService initialized');
      return this;
    } catch (e) {
      AppLogger.error('InAppReviewService init error', e);
      return this;
    }
  }

  /// Check if user has already rated or dismissed the review prompt
  bool get hasRatedOrDismissed {
    return _storage.getBool(_keyRatedOrDismissed) ?? false;
  }

  /// Mark that user has seen the review prompt (rated or dismissed)
  void _markAsRatedOrDismissed() {
    _storage.setBool(_keyRatedOrDismissed, true);
    AppLogger.info('📱 Marked as rated/dismissed - will not show again');
  }

  /// Check if we should show the review prompt based on shift count
  bool shouldShowReview(int totalShifts) {
    // Don't show if already rated or dismissed
    if (hasRatedOrDismissed) {
      AppLogger.info('📱 Review already shown before, skipping');
      return false;
    }

    // Show only when reaching exactly 15 shifts
    if (totalShifts == _shiftsThreshold) {
      AppLogger.info('📱 Reached $_shiftsThreshold shifts - eligible for review');
      return true;
    }

    return false;
  }

  /// Request the native in-app review dialog
  /// Call this after a session ends (not during voice flow)
  Future<void> requestReview() async {
    // Double-check we haven't already shown
    if (hasRatedOrDismissed) {
      AppLogger.info('📱 Review already shown, not requesting again');
      return;
    }

    try {
      final isAvailable = await _inAppReview.isAvailable();
      AppLogger.info('📱 In-app review available: $isAvailable');

      if (isAvailable) {
        // Mark as shown BEFORE requesting (in case user dismisses)
        // This ensures we never show again regardless of outcome
        _markAsRatedOrDismissed();

        // Request the native review dialog
        await _inAppReview.requestReview();
        AppLogger.info('📱 Native review dialog requested');
      } else {
        // Fallback: Show a graceful message
        _markAsRatedOrDismissed();
        _showFallbackMessage();
      }
    } catch (e) {
      AppLogger.error('📱 Error requesting review', e);
      // Mark as shown to prevent repeated errors
      _markAsRatedOrDismissed();
      _showFallbackMessage();
    }
  }

  /// Show a graceful fallback message when native review is not available
  void _showFallbackMessage() {
    AppLogger.info('📱 Showing fallback review message');
    SnackbarUtils.showCustom(
      title: '💜 Enjoying MoodShift?',
      message: 'We\'d love to hear your feedback! Rate us on the app store.',
      backgroundColor: const Color(0xFF7C4DFF),
      textColor: Colors.white,
      icon: Icons.star_rounded,
      duration: const Duration(seconds: 4),
    );
  }
}

