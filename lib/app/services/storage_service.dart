import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StorageService extends GetxService {
  late final GetStorage _box;

  Future<StorageService> init() async {
    _box = GetStorage();
    return this;
  }

  // Language
  Locale getLocale() {
    final languageCode = _box.read('language_code') ?? 'en';
    final countryCode = _box.read('country_code') ?? 'US';
    return Locale(languageCode, countryCode);
  }

  void setLocale(String languageCode, String countryCode) {
    _box.write('language_code', languageCode);
    _box.write('country_code', countryCode);
  }

  String getLanguageCode() {
    return _box.read('language_code') ?? 'en';
  }

  // ========== NEW STREAK SYSTEM ==========

  // Get current streak (read-only, doesn't modify)
  int getCurrentStreak() {
    return _box.read('streak_current') ?? 0;
  }

  // Get longest streak ever
  int getLongestStreak() {
    return _box.read('streak_longest') ?? 0;
  }

  // Get total shifts count (lifetime)
  int getTotalShifts() {
    return _box.read('total_shifts') ?? 0;
  }

  // Get last shift date (ISO string)
  String? getLastShiftDate() {
    return _box.read('last_shift_date');
  }

  // Check if user has already done a shift today
  bool hasShiftedToday() {
    final lastDate = getLastShiftDate();
    if (lastDate == null) return false;

    final last = DateTime.parse(lastDate);
    final today = DateTime.now();

    // Compare dates only (ignore time)
    return last.year == today.year &&
           last.month == today.month &&
           last.day == today.day;
  }

  // Increment streak (called once per day after first shift)
  // Returns: {current: int, longest: int, isNewRecord: bool, isBroken: bool}
  Map<String, dynamic> incrementStreak() {
    final lastDate = getLastShiftDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int currentStreak = getCurrentStreak();
    int longestStreak = getLongestStreak();
    bool isNewRecord = false;
    bool isBroken = false;

    if (lastDate == null) {
      // First ever shift
      currentStreak = 1;
      longestStreak = 1;
      print('🔥 [STREAK] First ever shift! Day 1');
    } else {
      final last = DateTime.parse(lastDate);
      final lastDay = DateTime(last.year, last.month, last.day);
      final daysDiff = today.difference(lastDay).inDays;

      if (daysDiff == 0) {
        // Same day - don't increment, just return current
        print('🔥 [STREAK] Same day, streak stays at $currentStreak');
      } else if (daysDiff == 1) {
        // Next day - increment streak!
        currentStreak++;
        print('🔥 [STREAK] Next day! Streak increased to $currentStreak');
      } else {
        // Streak broken - reset to 1
        currentStreak = 1;
        isBroken = true;
        print('💔 [STREAK] Streak broken (${daysDiff} days gap). Reset to Day 1');
      }
    }

    // Update longest streak if current is higher
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
      isNewRecord = true;
      print('🎉 [STREAK] NEW RECORD! Longest streak: $longestStreak');
    }

    // Save to storage
    _box.write('streak_current', currentStreak);
    _box.write('streak_longest', longestStreak);
    _box.write('last_shift_date', now.toIso8601String());

    return {
      'current': currentStreak,
      'longest': longestStreak,
      'isNewRecord': isNewRecord,
      'isBroken': isBroken,
    };
  }

  // Increment total shifts counter (called after every shift)
  int incrementTotalShifts() {
    final current = getTotalShifts();
    final newTotal = current + 1;
    _box.write('total_shifts', newTotal);
    print('📊 [STREAK] Total shifts: $newTotal');
    return newTotal;
  }

  // ========== OLD METHODS (kept for backward compatibility) ==========

  int getStreakDay() {
    return getCurrentStreak();
  }

  int getTodayShifts() {
    // This is no longer used in new system, but kept for compatibility
    return 0;
  }

  void incrementShift() {
    // Old method - now handled by incrementStreak() and incrementTotalShifts()
    // Kept for backward compatibility
  }

  // Shift counter for interstitial ads (every 4th shift)
  int getShiftCounter() {
    return _box.read('shift_counter') ?? 0;
  }

  void incrementShiftCounter() {
    final current = getShiftCounter();
    _box.write('shift_counter', current + 1);
  }

  void resetShiftCounter() {
    _box.write('shift_counter', 0);
  }

  // Ad-free period
  bool isAdFree() {
    final adFreeUntil = _box.read('ad_free_until');
    if (adFreeUntil == null) return false;

    final until = DateTime.parse(adFreeUntil);
    return DateTime.now().isBefore(until);
  }

  void setAdFree24Hours() {
    final until = DateTime.now().add(const Duration(hours: 24));
    _box.write('ad_free_until', until.toIso8601String());
    print('🕊️ [AD-FREE DEBUG] Ad-free activated until: $until');
  }

  Duration getRemainingAdFreeTime() {
    final adFreeUntil = _box.read('ad_free_until');
    if (adFreeUntil == null) return Duration.zero;

    final until = DateTime.parse(adFreeUntil);
    final remaining = until.difference(DateTime.now());

    return remaining.isNegative ? Duration.zero : remaining;
  }

  String getAdFreeEndTime() {
    return _box.read('ad_free_until') ?? '';
  }

  void clearAdFree() {
    _box.remove('ad_free_until');
    print('🔄 [AD-FREE DEBUG] Ad-free period cleared');
  }

  // Golden voice
  bool hasGoldenVoice() {
    final goldenUntil = _box.read('golden_voice_until');
    if (goldenUntil == null) return false;

    final until = DateTime.parse(goldenUntil);
    final hasGolden = DateTime.now().isBefore(until);

    // Auto-clear if expired
    if (!hasGolden) {
      _box.remove('golden_voice_until');
    }

    return hasGolden;
  }

  void setGoldenVoice1Hour() {
    final until = DateTime.now().add(const Duration(hours: 1));
    _box.write('golden_voice_until', until.toIso8601String());
    print('✨ [GOLDEN DEBUG] Golden Voice activated until: $until');
  }

  Duration getRemainingGoldenTime() {
    final goldenUntil = _box.read('golden_voice_until');
    if (goldenUntil == null) return Duration.zero;

    final until = DateTime.parse(goldenUntil);
    final remaining = until.difference(DateTime.now());

    return remaining.isNegative ? Duration.zero : remaining;
  }

  String getGoldenVoiceEndTime() {
    return _box.read('golden_voice_until') ?? '';
  }

  void clearGoldenVoice() {
    _box.remove('golden_voice_until');
    print('🔄 [GOLDEN DEBUG] Golden Voice cleared');
  }

  // Last AI response for 2x stronger feature
  String? getLastResponse() {
    return _box.read('last_response');
  }

  void setLastResponse(String response) {
    _box.write('last_response', response);
  }

  // First launch
  bool isFirstLaunch() {
    return _box.read('first_launch') ?? true;
  }

  void setFirstLaunchComplete() {
    _box.write('first_launch', false);
  }
}

