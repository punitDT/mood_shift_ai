import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../services/storage_service.dart';

class StreakController extends GetxController {
  static StreakController get to => Get.find();
  
  final StorageService _storage = Get.find<StorageService>();
  
  // Observable values
  final currentStreak = 0.obs;
  final longestStreak = 0.obs;
  final totalShifts = 0.obs;
  final streakMessage = ''.obs;
  
  late ConfettiController confettiController;

  @override
  void onInit() {
    super.onInit();
    confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadStreakData();
  }

  void _loadStreakData() {
    currentStreak.value = _storage.getCurrentStreak();
    longestStreak.value = _storage.getLongestStreak();
    totalShifts.value = _storage.getTotalShifts();
    _updateStreakMessage();
    print('🔥 [STREAK CONTROLLER] Loaded - Current: ${currentStreak.value}, Longest: ${longestStreak.value}, Total: ${totalShifts.value}');
  }

  void _updateStreakMessage() {
    final current = currentStreak.value;
    
    if (current == 0) {
      streakMessage.value = 'Start your journey! 🌟';
    } else if (current == 1) {
      streakMessage.value = 'Day 1 – Welcome! Keep coming back ❤️';
    } else if (current >= 3) {
      streakMessage.value = 'Day $current 🔥 • ${totalShifts.value} shifts saved';
    } else {
      streakMessage.value = 'Day $current • ${totalShifts.value} shifts saved';
    }
  }

  // Call this after every successful shift (after TTS finishes)
  void incrementStreak() {
    // Always increment total shifts
    final newTotal = _storage.incrementTotalShifts();
    totalShifts.value = newTotal;

    // Check if we should increment streak (only once per day)
    final hasShiftedToday = _storage.hasShiftedToday();
    
    if (!hasShiftedToday) {
      // First shift of the day - update streak
      final result = _storage.incrementStreak();
      
      final current = result['current'] as int;
      final longest = result['longest'] as int;
      final isNewRecord = result['isNewRecord'] as bool;
      final isBroken = result['isBroken'] as bool;

      currentStreak.value = current;
      longestStreak.value = longest;
      _updateStreakMessage();

      // Show celebration
      _showStreakCelebration(current, isNewRecord, isBroken);
    } else {
      // Not first shift today - just update message
      _updateStreakMessage();
      print('🔥 [STREAK] Already shifted today, total shifts: $newTotal');
    }
  }

  void _showStreakCelebration(int current, bool isNewRecord, bool isBroken) {
    // Play confetti
    confettiController.play();

    String title;
    String message;
    Color backgroundColor;
    IconData icon;

    if (isBroken) {
      // Streak was broken - gentle encouragement
      title = 'New start! 💪';
      message = 'Day 1 again – you got this ❤️';
      backgroundColor = Colors.purple.withOpacity(0.9);
      icon = Icons.favorite_rounded;
    } else if (isNewRecord) {
      // New record!
      title = '🎉 NEW RECORD!';
      message = 'Day $current! Legend status unlocked 🏆';
      backgroundColor = Colors.amber.withOpacity(0.9);
      icon = Icons.emoji_events_rounded;
    } else if (current == 1) {
      // First day
      title = 'Welcome! 🌟';
      message = 'Day 1 – Your journey begins!';
      backgroundColor = Colors.blue.withOpacity(0.9);
      icon = Icons.rocket_launch_rounded;
    } else if (current == 3) {
      // First fire emoji day
      title = 'You\'re on fire! 🔥';
      message = 'Day $current streak! Keep it going!';
      backgroundColor = Colors.orange.withOpacity(0.9);
      icon = Icons.local_fire_department_rounded;
    } else if (current % 7 == 0) {
      // Weekly milestone
      title = '🎊 ${current ~/ 7} Week${current ~/ 7 > 1 ? 's' : ''}!';
      message = 'Day $current! You\'re unstoppable 🔥';
      backgroundColor = Colors.deepPurple.withOpacity(0.9);
      icon = Icons.celebration_rounded;
    } else if (current % 30 == 0) {
      // Monthly milestone
      title = '🌟 ${current ~/ 30} Month${current ~/ 30 > 1 ? 's' : ''}!';
      message = 'Day $current! Absolute legend! 👑';
      backgroundColor = Colors.pink.withOpacity(0.9);
      icon = Icons.stars_rounded;
    } else {
      // Regular day
      title = 'Day $current streak! 🔥';
      message = 'You\'re unstoppable! Keep going!';
      backgroundColor = Colors.deepOrange.withOpacity(0.9);
      icon = Icons.local_fire_department_rounded;
    }

    // Show snackbar
    Get.snackbar(
      title,
      message,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      icon: Icon(icon, color: Colors.white, size: 28),
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  // Get formatted streak text for UI
  String getStreakText() {
    final current = currentStreak.value;
    final total = totalShifts.value;
    
    if (current == 0) {
      return 'Start your first shift! 🌟';
    } else if (current == 1) {
      return 'Day 1 – Welcome! ❤️';
    } else if (current >= 3) {
      return 'Day $current 🔥 • $total shifts saved';
    } else {
      return 'Day $current • $total shifts saved';
    }
  }

  // Check if should show fire emoji
  bool shouldShowFire() {
    return currentStreak.value >= 3;
  }

  @override
  void onClose() {
    confettiController.dispose();
    super.onClose();
  }
}

