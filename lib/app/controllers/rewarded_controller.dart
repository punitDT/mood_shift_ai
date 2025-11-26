import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../utils/snackbar_utils.dart';

/// Controller for managing rewarded ad features:
/// - 2× Stronger: Replay response with amplified energy (UNLIMITED!)
/// - Crystal Voice: Premium clarity voice for 1 hour
class RewardedController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();

  // 2× Stronger Feature (UNLIMITED - no counter!)
  final showStrongerFlash = false.obs;
  final showStrongerOverlay = false.obs;

  // Crystal Voice Feature
  final hasGoldenVoice = false.obs;
  final goldenTimeRemaining = ''.obs;
  final showGoldenGlow = false.obs;
  final showGoldenSparkle = false.obs;

  Timer? _goldenVoiceTimer;

  @override
  void onInit() {
    super.onInit();
    _startGoldenVoiceTimer();
  }

  // ========== 2× STRONGER FEATURE (UNLIMITED!) ==========

  // No limits! Users can use this as many times as they want
  // More ad views = more revenue!
  void useStronger() {
    print('⚡ [STRONGER] Activated! (UNLIMITED)');
  }

  Future<void> playStrongerEffects() async {
    // Electric blue flash effect
    showStrongerFlash.value = true;
    await Future.delayed(const Duration(milliseconds: 300));
    showStrongerFlash.value = false;

    // Power overlay - REMOVED (only top snackbar is shown now)
    // showStrongerOverlay.value = true;
    // await Future.delayed(const Duration(seconds: 2));
    // showStrongerOverlay.value = false;
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
    SnackbarUtils.showCustom(
      title: '✨ Golden Voice Expired',
      message: 'Golden Voice expired – renew?',
      backgroundColor: const Color(0xFFFFC107),
      textColor: Colors.black87,
      icon: Icons.star_border,
      duration: const Duration(seconds: 4),
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
    SnackbarUtils.showCustom(
      title: '💎 Crystal Voice Unlocked!',
      message: 'Premium clarity for 1 hour',
      backgroundColor: const Color(0xFF7B1FA2),
      textColor: Colors.white,
      icon: Icons.diamond,
      duration: const Duration(seconds: 3),
    );
  }

  String getGoldenTimerDisplay() {
    if (!hasGoldenVoice.value) return '';
    // Compact format for top bar to prevent overflow
    return '${goldenTimeRemaining.value}';
  }

  String getGoldenTimerDisplayFull() {
    if (!hasGoldenVoice.value) return '';
    // Full format for bottom sheet
    return 'Golden Voice: ${goldenTimeRemaining.value}';
  }

  @override
  void onClose() {
    _goldenVoiceTimer?.cancel();
    super.onClose();
  }
}

