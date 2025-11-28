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
  final hasCrystalVoice = false.obs;
  final crystalTimeRemaining = ''.obs;
  final showCrystalGlow = false.obs;
  final showCrystalSparkle = false.obs;

  Timer? _crystalVoiceTimer;

  @override
  void onInit() {
    super.onInit();
    _startCrystalVoiceTimer();
  }

  // ========== 2× STRONGER FEATURE (UNLIMITED!) ==========

  void useStronger() {
    // No limits! Users can use this as many times as they want
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

  // ========== CRYSTAL VOICE FEATURE ==========

  void _startCrystalVoiceTimer() {
    // Update crystal voice status every second
    _crystalVoiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCrystalVoiceStatus();
    });
  }

  void _updateCrystalVoiceStatus() {
    final wasCrystal = hasCrystalVoice.value;
    hasCrystalVoice.value = _storage.hasCrystalVoice();

    if (hasCrystalVoice.value) {
      final remaining = _storage.getRemainingCrystalTime();
      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds % 60;
      crystalTimeRemaining.value = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      // Show glow when active
      showCrystalGlow.value = true;
    } else {
      crystalTimeRemaining.value = '';
      showCrystalGlow.value = false;

      // Show expiry notification if it just expired
      if (wasCrystal && !hasCrystalVoice.value) {
        _showCrystalExpiredNotification();
      }
    }
  }

  void _showCrystalExpiredNotification() {
    SnackbarUtils.showCustom(
      title: '💎 Crystal Voice Expired',
      message: 'Crystal Voice expired – renew?',
      backgroundColor: const Color(0xFF7B1FA2),
      textColor: Colors.white,
      icon: Icons.diamond_outlined,
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> activateCrystalVoice() async {
    _storage.setCrystalVoice1Hour();
    _updateCrystalVoiceStatus();

    // Play sparkle animation
    showCrystalSparkle.value = true;
    await Future.delayed(const Duration(seconds: 2));
    showCrystalSparkle.value = false;

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

  String getCrystalTimerDisplay() {
    if (!hasCrystalVoice.value) return '';
    // Compact format for top bar to prevent overflow
    return '${crystalTimeRemaining.value}';
  }

  String getCrystalTimerDisplayFull() {
    if (!hasCrystalVoice.value) return '';
    // Full format for bottom sheet
    return 'Crystal Voice: ${crystalTimeRemaining.value}';
  }

  @override
  void onClose() {
    _crystalVoiceTimer?.cancel();
    super.onClose();
  }
}

