import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../services/storage_service.dart';

/// Controller for managing rewarded ad features:
/// - 2× Stronger: Replay response with amplified energy (3 uses/session limit)
/// - Golden Voice: Premium warm voice for 1 hour
class RewardedController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // 2× Stronger Feature
  final strongerUsesRemaining = 3.obs;
  final showStrongerFlash = false.obs;
  final showStrongerOverlay = false.obs;
  
  // Golden Voice Feature
  final hasGoldenVoice = false.obs;
  final goldenTimeRemaining = ''.obs;
  final showGoldenGlow = false.obs;
  final showGoldenSparkle = false.obs;
  
  Timer? _goldenVoiceTimer;
  Timer? _sessionResetTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeStrongerSession();
    _startGoldenVoiceTimer();
    _startSessionResetTimer();
  }

  // ========== 2× STRONGER FEATURE ==========

  void _initializeStrongerSession() {
    // Reset stronger uses at start of session
    final lastSessionDate = _storage.getLastSessionDate();
    final today = DateTime.now();
    
    if (lastSessionDate == null || 
        !_isSameDay(DateTime.parse(lastSessionDate), today)) {
      // New session - reset uses
      strongerUsesRemaining.value = 3;
      _storage.setStrongerUsesRemaining(3);
      _storage.setLastSessionDate(today.toIso8601String());
    } else {
      // Same session - load saved uses
      strongerUsesRemaining.value = _storage.getStrongerUsesRemaining();
    }
    
    print('⚡ [STRONGER] Session initialized: ${strongerUsesRemaining.value} uses remaining');
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _startSessionResetTimer() {
    // Check every hour if we need to reset the session
    _sessionResetTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      final lastSessionDate = _storage.getLastSessionDate();
      final today = DateTime.now();
      
      if (lastSessionDate != null && 
          !_isSameDay(DateTime.parse(lastSessionDate), today)) {
        // New day - reset uses
        strongerUsesRemaining.value = 3;
        _storage.setStrongerUsesRemaining(3);
        _storage.setLastSessionDate(today.toIso8601String());
        print('⚡ [STRONGER] Session reset: 3 uses available');
      }
    });
  }

  bool canUseStronger() {
    return strongerUsesRemaining.value > 0;
  }

  void useStronger() {
    if (!canUseStronger()) {
      Get.snackbar(
        '⚡ Limit Reached',
        'You\'ve used all 3 "2× Stronger" boosts for today. Come back tomorrow!',
        backgroundColor: Colors.orange.withOpacity(0.9),
        colorText: Colors.white,
        icon: const Icon(Icons.bolt, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    strongerUsesRemaining.value--;
    _storage.setStrongerUsesRemaining(strongerUsesRemaining.value);
    print('⚡ [STRONGER] Used! Remaining: ${strongerUsesRemaining.value}');

    // Track analytics
    _analytics.logEvent(
      name: 'stronger_used',
      parameters: {
        'uses_remaining': strongerUsesRemaining.value,
        'session_date': _storage.getLastSessionDate(),
      },
    );
  }

  Future<void> playStrongerEffects() async {
    // Orange flash effect
    showStrongerFlash.value = true;
    await Future.delayed(const Duration(milliseconds: 300));
    showStrongerFlash.value = false;

    // Power overlay
    showStrongerOverlay.value = true;
    await Future.delayed(const Duration(seconds: 2));
    showStrongerOverlay.value = false;
  }

  // ========== GOLDEN VOICE FEATURE ==========

  void _startGoldenVoiceTimer() {
    // Update golden voice status every second
    _goldenVoiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateGoldenVoiceStatus();
    });
  }

  void _updateGoldenVoiceStatus() {
    final wasGolden = hasGoldenVoice.value;
    hasGoldenVoice.value = _storage.hasGoldenVoice();

    if (hasGoldenVoice.value) {
      final remaining = _storage.getRemainingGoldenTime();
      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds % 60;
      goldenTimeRemaining.value = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      
      // Show glow when active
      showGoldenGlow.value = true;
    } else {
      goldenTimeRemaining.value = '';
      showGoldenGlow.value = false;
      
      // Show expiry notification if it just expired
      if (wasGolden && !hasGoldenVoice.value) {
        _showGoldenExpiredNotification();
      }
    }
  }

  void _showGoldenExpiredNotification() {
    Get.snackbar(
      '✨ Golden Voice Expired',
      'Your premium voice has ended. Watch an ad to renew?',
      backgroundColor: Colors.amber.withOpacity(0.8),
      colorText: Colors.black,
      icon: const Icon(Icons.star_border, color: Colors.black),
      duration: const Duration(seconds: 4),
      mainButton: TextButton(
        onPressed: () {
          Get.back(); // Close snackbar
          // Trigger golden voice unlock (handled by home controller)
        },
        child: const Text(
          'Renew',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> activateGoldenVoice() async {
    _storage.setGoldenVoice1Hour();
    _updateGoldenVoiceStatus();

    // Play sparkle animation
    showGoldenSparkle.value = true;
    await Future.delayed(const Duration(seconds: 2));
    showGoldenSparkle.value = false;

    // Show success snackbar
    Get.snackbar(
      '✨ Golden Voice Unlocked!',
      'Premium warmth for 1 hour',
      backgroundColor: Colors.amber.withOpacity(0.9),
      colorText: Colors.black,
      icon: const Icon(Icons.star, color: Colors.amber),
      duration: const Duration(seconds: 3),
    );

    // Track analytics
    _analytics.logEvent(
      name: 'golden_voice_activated',
      parameters: {
        'duration_minutes': 60,
        'activation_time': DateTime.now().toIso8601String(),
      },
    );
  }

  String getGoldenTimerDisplay() {
    if (!hasGoldenVoice.value) return '';
    return 'Golden: ${goldenTimeRemaining.value}';
  }

  // ========== ANALYTICS HELPERS ==========

  Map<String, dynamic> getStrongerAnalyticsData() {
    return {
      'uses_remaining': strongerUsesRemaining.value,
      'session_date': _storage.getLastSessionDate() ?? '',
    };
  }

  Map<String, dynamic> getGoldenAnalyticsData() {
    return {
      'is_active': hasGoldenVoice.value,
      'time_remaining_seconds': _storage.getRemainingGoldenTime().inSeconds,
      'expiry_time': _storage.getGoldenVoiceEndTime(),
    };
  }

  @override
  void onClose() {
    _goldenVoiceTimer?.cancel();
    _sessionResetTimer?.cancel();
    super.onClose();
  }
}

