import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StorageService extends GetxService {
  late final GetStorage _box;

  // Expose box for permission service
  GetStorage get box => _box;

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

  String getCountryCode() {
    return _box.read('country_code') ?? 'US';
  }

  String getFullLocale() {
    final languageCode = getLanguageCode();
    final countryCode = getCountryCode();
    final locale = '$languageCode-$countryCode';

    // Map to AWS Polly language codes
    // AWS Polly uses different codes for Chinese and Arabic
    final pollyLocaleMap = {
      'zh-CN': 'cmn-CN',  // Chinese Mandarin
      'ar-SA': 'arb',     // Arabic (Modern Standard)
    };

    return pollyLocaleMap[locale] ?? locale;
  }

  // Voice Gender
  String getVoiceGender() {
    return _box.read('voice_gender') ?? 'female';
  }

  void setVoiceGender(String gender) {
    _box.write('voice_gender', gender);
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
      currentStreak = 1;
      longestStreak = 1;
    } else {
      final last = DateTime.parse(lastDate);
      final lastDay = DateTime(last.year, last.month, last.day);
      final daysDiff = today.difference(lastDay).inDays;

      if (daysDiff == 0) {
        // Same day - don't increment
      } else if (daysDiff == 1) {
        currentStreak++;
      } else {
        currentStreak = 1;
        isBroken = true;
      }
    }

    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
      isNewRecord = true;
    }

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

  int incrementTotalShifts() {
    final current = getTotalShifts();
    final newTotal = current + 1;
    _box.write('total_shifts', newTotal);
    return newTotal;
  }

  int getStreakDay() {
    return getCurrentStreak();
  }

  int getTodayShifts() {
    return 0;
  }

  void incrementShift() {
    // Old method - kept for backward compatibility
  }

  int getShiftCounter() {
    return _box.read('shift_counter') ?? 0;
  }

  void incrementShiftCounter() {
    final current = getShiftCounter();
    final newValue = current + 1;
    _box.write('shift_counter', newValue);
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
  }

  bool hasCrystalVoice() {
    final crystalUntil = _box.read('crystal_voice_until');
    if (crystalUntil == null) return false;

    final until = DateTime.parse(crystalUntil);
    final hasCrystal = DateTime.now().isBefore(until);

    if (!hasCrystal) {
      _box.remove('crystal_voice_until');
    }

    return hasCrystal;
  }

  void setCrystalVoice1Hour() {
    final until = DateTime.now().add(const Duration(hours: 1));
    _box.write('crystal_voice_until', until.toIso8601String());
  }

  Duration getRemainingCrystalTime() {
    final crystalUntil = _box.read('crystal_voice_until');
    if (crystalUntil == null) return Duration.zero;

    final until = DateTime.parse(crystalUntil);
    final remaining = until.difference(DateTime.now());

    return remaining.isNegative ? Duration.zero : remaining;
  }

  String getCrystalVoiceEndTime() {
    return _box.read('crystal_voice_until') ?? '';
  }

  void clearCrystalVoice() {
    _box.remove('crystal_voice_until');
  }

  // Last AI response for 2x stronger feature
  String? getLastResponse() {
    return _box.read('last_response');
  }

  void setLastResponse(String response) {
    _box.write('last_response', response);
  }

  // ========== CONVERSATION HISTORY (Anti-Repetition) ==========

  // Get last 3 user inputs (optimized from 5 for better prompt efficiency)
  List<String> getRecentUserInputs() {
    final inputs = _box.read<List>('recent_user_inputs');
    if (inputs == null) return [];
    return inputs.cast<String>().take(3).toList();
  }

  // Get last 3 AI responses (optimized from 5 for better prompt efficiency)
  List<String> getRecentAIResponses() {
    final responses = _box.read<List>('recent_ai_responses');
    if (responses == null) return [];
    return responses.cast<String>().take(3).toList();
  }

  // Add user input to history (keep last 3, optimized from 5)
  void addUserInputToHistory(String input) {
    final inputs = getRecentUserInputs();
    inputs.insert(0, input);
    if (inputs.length > 3) {
      inputs.removeRange(3, inputs.length);
    }
    _box.write('recent_user_inputs', inputs);
  }

  // Add AI response to history (keep last 3, optimized from 5)
  void addAIResponseToHistory(String response) {
    final responses = getRecentAIResponses();
    responses.insert(0, response);
    if (responses.length > 3) {
      responses.removeRange(3, responses.length);
    }
    _box.write('recent_ai_responses', responses);
  }

  void clearConversationHistory() {
    _box.remove('recent_user_inputs');
    _box.remove('recent_ai_responses');
  }

  List<Map<String, dynamic>> getCachedResponses() {
    final cached = _box.read('cached_responses');
    if (cached == null) return [];
    return List<Map<String, dynamic>>.from(cached);
  }

  void addCachedResponse(String userInput, String response, String language) {
    final cached = getCachedResponses();

    cached.add({
      'userInput': userInput,
      'response': response,
      'language': language,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (cached.length > 20) {
      cached.removeRange(0, cached.length - 20);
    }

    _box.write('cached_responses', cached);
  }

  Map<String, dynamic>? findCachedResponse(String userInput, String language) {
    final cached = getCachedResponses();

    try {
      return cached.lastWhere(
        (item) =>
          item['userInput'].toString().toLowerCase() == userInput.toLowerCase() &&
          item['language'] == language,
      );
    } catch (e) {
      return null;
    }
  }

  void clearCachedResponses() {
    _box.remove('cached_responses');
  }

  bool isFirstLaunch() {
    return _box.read('first_launch') ?? true;
  }

  void setFirstLaunchComplete() {
    _box.write('first_launch', false);
  }

  Map<String, dynamic>? getPollyVoiceMap() {
    final jsonString = _box.read('polly_voice_map');
    if (jsonString == null) return null;

    try {
      return Map<String, dynamic>.from(jsonDecode(jsonString));
    } catch (e) {
      return null;
    }
  }

  void setPollyVoiceMap(Map<String, dynamic> voiceMap) {
    final jsonString = jsonEncode(voiceMap);
    _box.write('polly_voice_map', jsonString);
  }

  void clearPollyVoiceMap() {
    _box.remove('polly_voice_map');
  }

  int? getPollyVoiceMapVersion() {
    return _box.read('polly_voice_map_version');
  }

  void setPollyVoiceMapVersion(int version) {
    _box.write('polly_voice_map_version', version);
  }

  bool getCrashReportsEnabled() {
    return _box.read('crash_reports_enabled') ?? true;
  }

  void setCrashReportsEnabled(bool enabled) {
    _box.write('crash_reports_enabled', enabled);
  }
}


