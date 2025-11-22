import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mood_shift_ai/app/services/storage_service.dart';
import 'package:mood_shift_ai/app/services/ad_service.dart';

/// 🧪 AUTOMATED TESTS FOR MOODSHIFT AI FEATURES
/// 
/// FEATURE 1: Interstitial Ad After Exactly 4th Shift
/// FEATURE 2: Golden Voice 1 Hour Timer
///
/// Run with: flutter test test/features_test.dart

void main() {
  // Initialize GetStorage for testing
  setUpAll(() async {
    await GetStorage.init();
  });

  group('FEATURE 1: Interstitial Ad Counter Logic', () {
    late StorageService storage;

    setUp(() async {
      // Initialize fresh storage for each test
      Get.reset();
      storage = await StorageService().init();
      Get.put(storage);
      
      // Clear any existing data
      storage.resetShiftCounter();
    });

    test('Counter starts at 0', () {
      final counter = storage.getShiftCounter();
      expect(counter, 0, reason: 'Initial counter should be 0');
      print('✅ Test passed: Counter starts at 0');
    });

    test('Counter increments correctly for 7 shifts', () {
      print('\n🧪 Testing counter increments for 7 shifts...');
      
      for (int i = 1; i <= 7; i++) {
        storage.incrementShiftCounter();
        final counter = storage.getShiftCounter();
        
        print('  Shift #$i → Counter: $counter');
        
        if (i <= 4) {
          expect(counter, i, reason: 'Counter should be $i after shift $i');
        } else {
          // After 4th shift, counter resets to 0, then increments
          expect(counter, i - 4, reason: 'Counter should be ${i - 4} after shift $i (reset at 4)');
        }
      }
      
      print('✅ Test passed: Counter increments correctly');
    });

    test('Interstitial should show ONLY on 4th shift', () {
      print('\n🧪 Testing interstitial ad logic for 8 shifts...');
      
      for (int i = 1; i <= 8; i++) {
        storage.incrementShiftCounter();
        final counter = storage.getShiftCounter();
        
        // Simulate ad service logic
        final shouldShowAd = (counter == 4);
        
        print('  Shift #$i → Counter: $counter → Show Ad: $shouldShowAd');
        
        if (i == 4 || i == 8) {
          expect(shouldShowAd, true, 
            reason: 'Ad should show on shift $i (counter == 4)');
          // Simulate reset after showing ad
          storage.resetShiftCounter();
          print('    ✅ Ad shown, counter reset to 0');
        } else {
          expect(shouldShowAd, false, 
            reason: 'Ad should NOT show on shift $i (counter != 4)');
        }
      }
      
      print('✅ Test passed: Interstitial shows only on 4th and 8th shifts');
    });

    test('Counter persists across service restarts', () {
      print('\n🧪 Testing counter persistence...');
      
      // Increment counter 3 times
      storage.incrementShiftCounter();
      storage.incrementShiftCounter();
      storage.incrementShiftCounter();
      
      final counterBefore = storage.getShiftCounter();
      print('  Counter before restart: $counterBefore');
      expect(counterBefore, 3);
      
      // Simulate app restart by creating new service instance
      final newStorage = StorageService();
      newStorage.init();
      
      final counterAfter = newStorage.getShiftCounter();
      print('  Counter after restart: $counterAfter');
      expect(counterAfter, 3, reason: 'Counter should persist across restarts');
      
      print('✅ Test passed: Counter persists correctly');
    });

    test('Counter resets correctly after 4th shift', () {
      print('\n🧪 Testing counter reset logic...');
      
      // Increment to 4
      for (int i = 0; i < 4; i++) {
        storage.incrementShiftCounter();
      }
      
      expect(storage.getShiftCounter(), 4);
      print('  Counter at 4: ${storage.getShiftCounter()}');
      
      // Reset (simulating ad shown)
      storage.resetShiftCounter();
      expect(storage.getShiftCounter(), 0);
      print('  Counter after reset: ${storage.getShiftCounter()}');
      
      // Increment again
      storage.incrementShiftCounter();
      expect(storage.getShiftCounter(), 1);
      print('  Counter after next shift: ${storage.getShiftCounter()}');
      
      print('✅ Test passed: Counter resets correctly');
    });

    test('Verify counter never shows ad on 1st, 2nd, 3rd, 5th, 6th, 7th shifts', () {
      print('\n🧪 Testing ad does NOT show on wrong shifts...');
      
      final noAdShifts = [1, 2, 3, 5, 6, 7];
      
      for (final shiftNum in noAdShifts) {
        // Reset and increment to target shift
        storage.resetShiftCounter();
        for (int i = 0; i < shiftNum; i++) {
          storage.incrementShiftCounter();
        }
        
        final counter = storage.getShiftCounter();
        final shouldShowAd = (counter == 4);
        
        print('  Shift #$shiftNum → Counter: $counter → Should show ad: $shouldShowAd');
        expect(shouldShowAd, false, 
          reason: 'Ad should NOT show on shift $shiftNum');
      }
      
      print('✅ Test passed: Ad correctly skipped on non-4th shifts');
    });
  });

  group('FEATURE 2: Golden Voice Timer Logic', () {
    late StorageService storage;

    setUp(() async {
      Get.reset();
      storage = await StorageService().init();
      Get.put(storage);
      
      // Clear any existing golden voice data
      storage.clearGoldenVoice();
    });

    test('Golden voice initially inactive', () {
      final hasGolden = storage.hasGoldenVoice();
      expect(hasGolden, false, reason: 'Golden voice should be inactive initially');
      print('✅ Test passed: Golden voice starts inactive');
    });

    test('Golden voice activates for 1 hour', () {
      print('\n🧪 Testing golden voice activation...');
      
      storage.setGoldenVoice1Hour();
      
      final hasGolden = storage.hasGoldenVoice();
      expect(hasGolden, true, reason: 'Golden voice should be active after activation');
      print('  Golden voice active: $hasGolden');
      
      final remaining = storage.getRemainingGoldenTime();
      print('  Time remaining: ${remaining.inMinutes}m ${remaining.inSeconds % 60}s');
      
      expect(remaining.inMinutes, greaterThanOrEqualTo(59), 
        reason: 'Should have at least 59 minutes remaining');
      expect(remaining.inMinutes, lessThanOrEqualTo(60), 
        reason: 'Should have at most 60 minutes remaining');
      
      print('✅ Test passed: Golden voice activates correctly');
    });

    test('Golden voice timer counts down', () async {
      print('\n🧪 Testing golden voice timer countdown...');
      
      storage.setGoldenVoice1Hour();
      
      final initialRemaining = storage.getRemainingGoldenTime();
      print('  Initial time: ${initialRemaining.inSeconds}s');
      
      // Wait 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      
      final afterWait = storage.getRemainingGoldenTime();
      print('  After 2s wait: ${afterWait.inSeconds}s');
      
      expect(afterWait.inSeconds, lessThan(initialRemaining.inSeconds), 
        reason: 'Time should decrease after waiting');
      expect(initialRemaining.inSeconds - afterWait.inSeconds, 
        greaterThanOrEqualTo(1), 
        reason: 'Should have decreased by at least 1 second');
      
      print('✅ Test passed: Timer counts down correctly');
    });

    test('Golden voice timer format is correct', () {
      print('\n🧪 Testing timer format...');
      
      storage.setGoldenVoice1Hour();
      
      final remaining = storage.getRemainingGoldenTime();
      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds % 60;
      final formatted = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      
      print('  Formatted time: $formatted');
      
      expect(formatted, matches(r'^\d{2}:\d{2}$'), 
        reason: 'Format should be MM:SS');
      expect(minutes, greaterThanOrEqualTo(59));
      expect(seconds, greaterThanOrEqualTo(0));
      expect(seconds, lessThan(60));
      
      print('✅ Test passed: Timer format is correct');
    });

    test('Golden voice persists across service restarts', () {
      print('\n🧪 Testing golden voice persistence...');
      
      storage.setGoldenVoice1Hour();
      
      final endTimeBefore = storage.getGoldenVoiceEndTime();
      print('  End time before restart: $endTimeBefore');
      expect(endTimeBefore, isNotEmpty);
      
      // Simulate app restart
      final newStorage = StorageService();
      newStorage.init();
      
      final hasGoldenAfter = newStorage.hasGoldenVoice();
      final endTimeAfter = newStorage.getGoldenVoiceEndTime();
      
      print('  Has golden after restart: $hasGoldenAfter');
      print('  End time after restart: $endTimeAfter');
      
      expect(hasGoldenAfter, true, reason: 'Golden voice should persist');
      expect(endTimeAfter, endTimeBefore, reason: 'End time should be same');
      
      print('✅ Test passed: Golden voice persists correctly');
    });

    test('Golden voice expires after 1 hour', () {
      print('\n🧪 Testing golden voice expiration...');
      
      // Manually set expired time (1 hour ago)
      final expiredTime = DateTime.now().subtract(const Duration(hours: 1));
      final box = GetStorage();
      box.write('golden_voice_until', expiredTime.toIso8601String());
      
      final hasGolden = storage.hasGoldenVoice();
      print('  Has golden voice (expired): $hasGolden');
      
      expect(hasGolden, false, reason: 'Golden voice should be inactive after expiration');
      
      final remaining = storage.getRemainingGoldenTime();
      print('  Remaining time: ${remaining.inSeconds}s');
      
      expect(remaining, Duration.zero, reason: 'Remaining time should be zero');
      
      print('✅ Test passed: Golden voice expires correctly');
    });

    test('Golden voice can be renewed after expiration', () {
      print('\n🧪 Testing golden voice renewal...');
      
      // Set expired time
      final expiredTime = DateTime.now().subtract(const Duration(hours: 1));
      final box = GetStorage();
      box.write('golden_voice_until', expiredTime.toIso8601String());
      
      expect(storage.hasGoldenVoice(), false);
      print('  Golden voice expired');
      
      // Renew
      storage.setGoldenVoice1Hour();
      
      expect(storage.hasGoldenVoice(), true);
      final remaining = storage.getRemainingGoldenTime();
      print('  Golden voice renewed, remaining: ${remaining.inMinutes}m');
      
      expect(remaining.inMinutes, greaterThanOrEqualTo(59));
      
      print('✅ Test passed: Golden voice can be renewed');
    });

    test('Clear golden voice works correctly', () {
      print('\n🧪 Testing clear golden voice...');
      
      storage.setGoldenVoice1Hour();
      expect(storage.hasGoldenVoice(), true);
      print('  Golden voice activated');
      
      storage.clearGoldenVoice();
      expect(storage.hasGoldenVoice(), false);
      print('  Golden voice cleared');
      
      final remaining = storage.getRemainingGoldenTime();
      expect(remaining, Duration.zero);
      
      print('✅ Test passed: Clear golden voice works');
    });
  });

  group('INTEGRATION: Both Features Together', () {
    late StorageService storage;

    setUp(() async {
      Get.reset();
      storage = await StorageService().init();
      Get.put(storage);
      
      storage.resetShiftCounter();
      storage.clearGoldenVoice();
    });

    test('Simulate 4 shifts with golden voice unlock on 4th', () {
      print('\n🧪 INTEGRATION TEST: 4 shifts + golden voice unlock...');
      
      for (int i = 1; i <= 4; i++) {
        print('\n--- Shift #$i ---');
        
        // Increment shift counter
        storage.incrementShiftCounter();
        final counter = storage.getShiftCounter();
        print('  Counter: $counter');
        
        // Check if interstitial should show
        final shouldShowAd = (counter == 4);
        print('  Show interstitial: $shouldShowAd');
        
        if (shouldShowAd) {
          expect(i, 4, reason: 'Interstitial should only show on 4th shift');
          storage.resetShiftCounter();
          print('  ✅ Interstitial shown, counter reset');
          
          // User watches rewarded ad and unlocks golden voice
          storage.setGoldenVoice1Hour();
          print('  ✨ Golden voice unlocked!');
          
          expect(storage.hasGoldenVoice(), true);
          final remaining = storage.getRemainingGoldenTime();
          print('  Golden time remaining: ${remaining.inMinutes}m ${remaining.inSeconds % 60}s');
        }
      }
      
      // Verify final state
      expect(storage.getShiftCounter(), 0, reason: 'Counter should be reset');
      expect(storage.hasGoldenVoice(), true, reason: 'Golden voice should be active');
      
      print('\n✅ Integration test passed!');
    });
  });
}

