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

  // Streak tracking
  int getStreakDay() {
    final lastDate = _box.read('last_shift_date');
    final today = DateTime.now();
    
    if (lastDate == null) {
      return 1;
    }
    
    final last = DateTime.parse(lastDate);
    final difference = today.difference(last).inDays;
    
    if (difference == 0) {
      // Same day
      return _box.read('streak_day') ?? 1;
    } else if (difference == 1) {
      // Next day - increment streak
      final newStreak = (_box.read('streak_day') ?? 0) + 1;
      _box.write('streak_day', newStreak);
      return newStreak;
    } else {
      // Streak broken - reset to 1
      _box.write('streak_day', 1);
      return 1;
    }
  }

  int getTodayShifts() {
    final lastDate = _box.read('last_shift_date');
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    if (lastDate == null || !lastDate.startsWith(today)) {
      return 0;
    }
    
    return _box.read('today_shifts') ?? 0;
  }

  void incrementShift() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastDate = _box.read('last_shift_date');
    
    if (lastDate == null || !lastDate.startsWith(today)) {
      // New day
      _box.write('today_shifts', 1);
    } else {
      // Same day
      final current = _box.read('today_shifts') ?? 0;
      _box.write('today_shifts', current + 1);
    }
    
    _box.write('last_shift_date', DateTime.now().toIso8601String());
    
    // Update streak
    getStreakDay();
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
  }

  // Golden voice
  bool hasGoldenVoice() {
    final goldenUntil = _box.read('golden_voice_until');
    if (goldenUntil == null) return false;
    
    final until = DateTime.parse(goldenUntil);
    return DateTime.now().isBefore(until);
  }

  void setGoldenVoice1Hour() {
    final until = DateTime.now().add(const Duration(hours: 1));
    _box.write('golden_voice_until', until.toIso8601String());
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

